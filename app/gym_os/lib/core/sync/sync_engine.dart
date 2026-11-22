import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';

import '../database/app_database.dart';

/// State representation for synchronization and connectivity.
class SyncState {
  final bool isOnline;
  final bool isSyncing;
  final int pendingCount;
  final DateTime? lastSyncedAt;

  const SyncState({
    required this.isOnline,
    required this.isSyncing,
    required this.pendingCount,
    this.lastSyncedAt,
  });

  SyncState copyWith({
    bool? isOnline,
    bool? isSyncing,
    int? pendingCount,
    DateTime? lastSyncedAt,
  }) {
    return SyncState(
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

/// Mutex-guarded sync engine coordinating offline outbox push and server state pull.
class SyncEngine {
  final Dio dio;
  final AppDatabase db;
  final Connectivity connectivity;

  bool _isSyncing = false;
  bool _isOnline = true;
  int _pendingCount = 0;
  DateTime? _lastSyncedAt;

  final StreamController<SyncState> _stateController =
      StreamController<SyncState>.broadcast();
  StreamSubscription<int>? _pendingSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  SyncEngine({
    required this.dio,
    required this.db,
    required this.connectivity,
  }) {
    _init();
  }

  bool get isSyncing => _isSyncing;
  bool get isOnline => _isOnline;
  int get pendingCount => _pendingCount;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  SyncState get currentState => SyncState(
        isOnline: _isOnline,
        isSyncing: _isSyncing,
        pendingCount: _pendingCount,
        lastSyncedAt: _lastSyncedAt,
      );

  Stream<SyncState> get stateStream => _stateController.stream;

  void _init() {
    _pendingSubscription = db.syncOutboxDao.watchPendingCount().listen((count) {
      _pendingCount = count;
      _emitState();
    });

    _connectivitySubscription =
        connectivity.onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      final wasOffline = !_isOnline;
      _isOnline = online;
      _emitState();

      if (wasOffline && online) {
        syncAll();
      }
    });

    connectivity.checkConnectivity().then((results) {
      _isOnline = results.any((r) => r != ConnectivityResult.none);
      _emitState();
    });

    db.syncOutboxDao.getMetadata('last_pulled_at').then((val) {
      if (val != null) {
        _lastSyncedAt = DateTime.tryParse(val)?.toLocal();
        _emitState();
      }
    });
  }

  void _emitState() {
    if (!_stateController.isClosed) {
      _stateController.add(currentState);
    }
  }

  /// Checks actual network reachability with a 2-second timeout.
  Future<bool> checkReachability() async {
    bool online = false;
    try {
      final connectivityResults = await connectivity
          .checkConnectivity()
          .timeout(const Duration(seconds: 2));
      online = connectivityResults.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      online = false;
    }

    if (online) {
      try {
        final res = await dio
            .get(
              '/api/plans',
              options: Options(
                sendTimeout: const Duration(seconds: 2),
                receiveTimeout: const Duration(seconds: 2),
              ),
            )
            .timeout(const Duration(seconds: 2));
        online = res.statusCode != null && res.statusCode! < 500;
      } catch (_) {
        online = false;
      }
    }

    _isOnline = online;
    _emitState();
    return online;
  }

  /// Full synchronization cycle:
  /// Always pushes pending local outbox operations FIRST, then pulls latest server state SECOND.
  Future<void> syncNow() => syncAll();

  /// Bidirectional 2-phase sync (Push-then-Pull), atomic & mutex-guarded:
  /// - Phase 1: Push (Local -> Server) pending operations FIFO.
  /// - Phase 2: Pull (Server -> Local) fresh plans, members, 30-day attendance,
  ///   dashboard summary, and payments without overwriting any dirty local rows.
  Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _emitState();

    try {
      final connectivityResults = await connectivity.checkConnectivity();
      _isOnline = connectivityResults.any((r) => r != ConnectivityResult.none);
      _emitState();

      if (!_isOnline) {
        return;
      }

      // Phase 1 — Push (Local -> Server)
      await pushPendingOperations();

      // Phase 2 — Pull (Server -> Local)
      await pullLatestState();

      _lastSyncedAt = DateTime.now();
      await db.syncOutboxDao.setMetadata(
        'last_pulled_at',
        _lastSyncedAt!.toUtc().toIso8601String(),
      );
    } catch (_) {
      // Non-fatal sync cycle error handled gracefully
    } finally {
      _isSyncing = false;
      _emitState();
    }
  }

  /// Pushes pending outbox operations to backend with strict 3-second network timeouts.
  Future<void> pushPendingOperations() async {
    final pendingOps = await db.syncOutboxDao.getPendingOperations(limit: 25);
    if (pendingOps.isEmpty) return;

    for (final op in pendingOps) {
      await db.syncOutboxDao.markSyncing(op.id);

      Map<String, dynamic> payload = {};
      try {
        payload = jsonDecode(op.payloadJson) as Map<String, dynamic>;
      } catch (_) {
        payload = {};
      }

      String? reconciledPaymentId;

      final options = Options(
        headers: {'X-Idempotency-Key': op.operationId},
        sendTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
      );

      try {
        switch (op.entityType) {
          case 'member_create':
            await dio.post(
              '/api/gym/members',
              data: {
                'id': op.entityId,
                'clientId': op.entityId,
                'occurredAtUtc': op.createdAt.toUtc().toIso8601String(),
                ...payload,
              },
              options: options,
            );
            break;

          case 'member_renew':
            try {
              await dio.post(
                '/api/payments/renew',
                data: {
                  'clientId': op.operationId,
                  'occurredAtUtc': op.createdAt.toUtc().toIso8601String(),
                  ...payload,
                },
                options: options,
              );
            } on DioException catch (e) {
              if (e.response?.statusCode == 404 && payload['memberId'] != null) {
                await dio.post(
                  '/api/gym/members/${payload['memberId']}/renew',
                  data: {
                    'clientId': op.operationId,
                    'occurredAtUtc': op.createdAt.toUtc().toIso8601String(),
                    ...payload,
                  },
                  options: options,
                );
              } else {
                rethrow;
              }
            }
            break;

          case 'checkin':
            try {
              await dio.post(
                '/api/attendance/check-in',
                data: {
                  'id': op.entityId,
                  'clientId': op.entityId,
                  'memberId': payload['memberId'],
                  'notes': payload['notes'],
                  'occurredAtUtc': op.createdAt.toUtc().toIso8601String(),
                  ...payload,
                },
                options: options,
              );
            } on DioException catch (e) {
              if (e.response?.statusCode == 404) {
                await dio.post(
                  '/api/gym/attendance/check-in',
                  data: {
                    'id': op.entityId,
                    'clientId': op.entityId,
                    'memberId': payload['memberId'],
                    'occurredAtUtc': op.createdAt.toUtc().toIso8601String(),
                    ...payload,
                  },
                  options: options,
                );
              } else {
                rethrow;
              }
            }
            break;

          case 'checkout':
            final recordId =
                payload['attendanceId'] ?? payload['recordId'] ?? op.entityId;
            try {
              await dio.post(
                '/api/attendance/$recordId/check-out',
                data: {
                  'attendanceId': recordId,
                  'memberId': payload['memberId'],
                  'occurredAtUtc': op.createdAt.toUtc().toIso8601String(),
                  ...payload,
                },
                options: options,
              );
            } on DioException catch (e) {
              if (e.response?.statusCode == 404) {
                await dio.post(
                  '/api/gym/attendance/check-out',
                  data: {
                    'attendanceId': recordId,
                    'memberId': payload['memberId'],
                    'occurredAtUtc': op.createdAt.toUtc().toIso8601String(),
                    ...payload,
                  },
                  options: options,
                );
              } else {
                rethrow;
              }
            }
            break;

          case 'dropin':
            try {
              final res = await dio.post(
                '/api/visits/drop-in',
                data: {
                  'clientId': op.entityId,
                  'attendanceId': op.entityId,
                  'occurredAtUtc': op.createdAt.toUtc().toIso8601String(),
                  ...payload,
                },
                options: options,
              );
              Map<String, dynamic>? resMap;
              if (res.data is Map<String, dynamic>) {
                resMap = res.data as Map<String, dynamic>;
              } else if (res.data is String) {
                try {
                  final decoded = jsonDecode(res.data as String);
                  if (decoded is Map<String, dynamic>) resMap = decoded;
                } catch (_) {}
              }
              final serverPayId = (resMap?['paymentId'] ?? resMap?['PaymentId'])?.toString();
              final localPayId =
                  (payload['paymentId'] ?? payload['PaymentId'])?.toString();
              if (serverPayId != null &&
                  localPayId != null &&
                  serverPayId != localPayId) {
                await db.paymentsDao.reconcilePaymentId(localPayId, serverPayId);
                reconciledPaymentId = serverPayId;
              }
            } on DioException catch (e) {
              if (e.response?.statusCode == 404) {
                final res = await dio.post(
                  '/api/gym/attendance/drop-in',
                  data: {
                    'clientId': op.entityId,
                    'attendanceId': op.entityId,
                    'occurredAtUtc': op.createdAt.toUtc().toIso8601String(),
                    ...payload,
                  },
                  options: options,
                );
                Map<String, dynamic>? resMap;
                if (res.data is Map<String, dynamic>) {
                  resMap = res.data as Map<String, dynamic>;
                } else if (res.data is String) {
                  try {
                    final decoded = jsonDecode(res.data as String);
                    if (decoded is Map<String, dynamic>) resMap = decoded;
                  } catch (_) {}
                }
                final serverPayId = (resMap?['paymentId'] ?? resMap?['PaymentId'])?.toString();
                final localPayId =
                    (payload['paymentId'] ?? payload['PaymentId'])?.toString();
                if (serverPayId != null &&
                    localPayId != null &&
                    serverPayId != localPayId) {
                  await db.paymentsDao.reconcilePaymentId(localPayId, serverPayId);
                  reconciledPaymentId = serverPayId;
                }
              } else {
                rethrow;
              }
            }
            break;

          default:
            // Custom or unrecognized operation type
            break;
        }

        // Extract paymentId from payload if present (e.g. dropin, member_renew, member_create)
        final paymentId = reconciledPaymentId ??
            (payload['paymentId'] ?? payload['PaymentId'])?.toString();

        // 2xx success: delete outbox row and clear local dirty flag
        await db.syncOutboxDao.markCompleted(
          op.id,
          entityType: op.entityType,
          entityId: op.entityId,
          paymentId: paymentId,
        );
      } catch (e) {
        final statusCode = (e is DioException) ? e.response?.statusCode : null;
        if (statusCode != null &&
            statusCode >= 400 &&
            statusCode < 500 &&
            statusCode != 401) {
          // Permanent 4xx client/validation error (e.g. 400, 422, 409):
          // Record error and mark failed so subsequent FIFO operations are not blocked.
          await db.syncOutboxDao.markFailed(op.id, e.toString());
          continue;
        } else {
          // Network, connection timeout, 5xx server error or 401 auth:
          // Mark failed and break push loop to preserve strict FIFO.
          await db.syncOutboxDao.markFailed(op.id, e.toString());
          break;
        }
      }
    }
  }

  /// Pulls the latest plans, members, attendance, and payments from backend.
  Future<void> pullLatestState() async {
    final pullOptions = Options(
      sendTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 3),
    );

    // 1. Pull Plans
    try {
      final plansRes = await dio.get('/api/plans', options: pullOptions);
      final data = plansRes.data;
      if (data is List) {
        final companions = data.map((item) {
          final map = item as Map<String, dynamic>;
          return LocalPlansCompanion.insert(
            id: map['id']?.toString() ?? '',
            name: map['name']?.toString() ?? '',
            price: (map['price'] as num?)?.toDouble() ?? 0.0,
            durationDays: (map['durationInDays'] as num?)?.toInt() ?? 30,
            isActive: Value(map['isActive'] as bool? ?? true),
            updatedAt: DateTime.now(),
          );
        }).toList();
        await db.plansDao.replaceAllPlans(companions);
      }
    } catch (_) {}

    // 2. Pull Members (preserving local rows where isDirty == true)
    try {
      final membersRes = await dio.get(
        '/api/gym/members',
        queryParameters: {'pageSize': 100},
        options: pullOptions,
      );
      final data = membersRes.data;
      final items = (data is Map<String, dynamic> && data['items'] is List)
          ? data['items'] as List
          : (data is List ? data : <dynamic>[]);

      final companions = items.map((m) {
        final map = m as Map<String, dynamic>;
        final endDateStr = map['subscriptionEndDate']?.toString();
        final isActive =
            map['subscriptionStatus']?.toString().toLowerCase() == 'active';
        return LocalMembersCompanion.insert(
          id: map['id']?.toString() ?? '',
          fullName: map['fullName']?.toString() ?? '',
          phone: map['phoneNumber']?.toString() ?? '',
          planName: Value(map['activePlanName']?.toString()),
          subscriptionEndDate: Value(
            endDateStr != null ? DateTime.tryParse(endDateStr) : null,
          ),
          photoUrl: Value(map['photoUrl']?.toString() ?? map['photo_url']?.toString()),
          status: Value(isActive ? 1 : 0),
          updatedAt: DateTime.now(),
          isDirty: const Value(false),
        );
      }).toList();

      await db.membersDao.upsertMembersFromServer(companions);
    } catch (_) {}

    // 3. Pull Historical Attendance (Last 30 Days) & Current Inside
    try {
      final nowUtc = DateTime.now().toUtc();
      final thirtyDaysAgoUtc = nowUtc.subtract(const Duration(days: 30));

      final attRes = await dio.get(
        '/api/attendance',
        queryParameters: {
          'startDate': thirtyDaysAgoUtc.toIso8601String(),
          'endDate': nowUtc.toIso8601String(),
        },
        options: pullOptions,
      );
      final data = attRes.data;
      if (data is List) {
        final companions = data.map((item) {
          final map = item as Map<String, dynamic>;
          final rawDate = map['checkInTime'];
          DateTime checkIn = DateTime.now();
          if (rawDate != null) {
            final parsed = DateTime.tryParse(rawDate.toString());
            if (parsed != null) {
              checkIn = parsed.isUtc
                  ? parsed.toLocal()
                  : (DateTime.tryParse('${rawDate}Z')?.toLocal() ?? parsed);
            }
          }

          final rawCheckOut = map['checkOutTime'];
          DateTime? checkOut;
          if (rawCheckOut != null) {
            final parsedOut = DateTime.tryParse(rawCheckOut.toString());
            if (parsedOut != null) {
              checkOut = parsedOut.isUtc
                  ? parsedOut.toLocal()
                  : (DateTime.tryParse('${rawCheckOut}Z')?.toLocal() ??
                      parsedOut);
            }
          }

          return LocalAttendanceCompanion.insert(
            id: map['recordId']?.toString() ?? map['id']?.toString() ?? '',
            memberId: Value(map['memberId']?.toString()),
            memberName:
                map['fullName']?.toString() ?? map['memberName']?.toString() ?? '',
            memberPhone: Value(map['phoneNumber']?.toString()),
            checkInTime: checkIn,
            checkOutTime: Value(checkOut),
            isDirty: const Value(false),
          );
        }).toList();

        await db.attendanceDao.upsertAttendanceFromServer(companions);
      }
    } catch (_) {}

    // Fallback/Supplement: Pull Current Inside Attendance if needed
    try {
      final attRes = await dio.get(
        '/api/attendance/current-inside',
        options: pullOptions,
      );
      final data = attRes.data;
      if (data is List) {
        final companions = data.map((item) {
          final map = item as Map<String, dynamic>;
          final rawDate = map['checkInTime'];
          DateTime checkIn = DateTime.now();
          if (rawDate != null) {
            final parsed = DateTime.tryParse(rawDate.toString());
            if (parsed != null) {
              checkIn = parsed.isUtc
                  ? parsed.toLocal()
                  : (DateTime.tryParse('${rawDate}Z')?.toLocal() ?? parsed);
            }
          }
          return LocalAttendanceCompanion.insert(
            id: map['recordId']?.toString() ?? map['id']?.toString() ?? '',
            memberId: Value(map['memberId']?.toString()),
            memberName:
                map['fullName']?.toString() ?? map['memberName']?.toString() ?? '',
            memberPhone: Value(map['phoneNumber']?.toString()),
            checkInTime: checkIn,
            isDirty: const Value(false),
          );
        }).toList();

        await db.attendanceDao.upsertAttendanceFromServer(companions);
      }
    } catch (_) {}

    // 4. Pull Recent Payments
    try {
      final payRes = await dio.get(
        '/api/payments',
        queryParameters: {'period': 'month'},
        options: pullOptions,
      );
      final data = payRes.data;
      if (data is Map<String, dynamic> && data['items'] is List) {
        final items = data['items'] as List;
        final companions = items.map((item) {
          final map = item as Map<String, dynamic>;
          final rawDate = map['paymentDate'];
          DateTime createdAt = DateTime.now();
          if (rawDate != null) {
            final parsed = DateTime.tryParse(rawDate.toString());
            if (parsed != null) createdAt = parsed;
          }
          int methodInt = 1;
          final rawMethod = map['method'];
          if (rawMethod is int) {
            methodInt = rawMethod;
          } else if (rawMethod is String) {
            switch (rawMethod.toLowerCase()) {
              case 'visa':
                methodInt = 2;
                break;
              case 'instapay':
                methodInt = 3;
                break;
              case 'vodafonecash':
                methodInt = 4;
                break;
              default:
                methodInt = 1;
                break;
            }
          }
          return LocalPaymentsCompanion.insert(
            id: map['id']?.toString() ?? '',
            memberName: Value(map['memberName']?.toString()),
            planId: Value(map['planId']?.toString()),
            amountPaid: (map['amount'] as num?)?.toDouble() ?? 0.0,
            method: methodInt,
            type: 1,
            createdAt: createdAt,
            isDirty: const Value(false),
          );
        }).toList();

        await db.paymentsDao.upsertPaymentsFromServer(companions);
      }
    } catch (_) {}

    // 5. Pull Dashboard Summary / Stats
    try {
      final statsRes =
          await dio.get('/api/dashboard/stats', options: pullOptions);
      if (statsRes.data is Map<String, dynamic>) {
        await db.syncOutboxDao.setMetadata(
          'cached_dashboard_stats',
          jsonEncode(statsRes.data),
        );
      }
    } catch (_) {}
  }

  void dispose() {
    _pendingSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _stateController.close();
  }
}

/// Automatically triggers sync cycles on app resume, network recovery, and periodic timer.
class SyncLifecycleObserver with WidgetsBindingObserver {
  final SyncEngine _engine;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicTimer;

  SyncLifecycleObserver(this._engine, this._connectivity);

  void start() {
    WidgetsBinding.instance.addObserver(this);

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        _engine.syncAll();
      }
    });

    // Foreground periodic sync every 2 minutes
    _periodicTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _engine.syncAll();
    });

    // Immediate non-blocking startup sync trigger (Push-then-Pull in background)
    _connectivity.checkConnectivity().then((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        _engine.syncAll();
      }
    }).catchError((_) {
      _engine.syncAll();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _engine.isOnline) {
      _engine.syncAll();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    _periodicTimer?.cancel();
  }
}
