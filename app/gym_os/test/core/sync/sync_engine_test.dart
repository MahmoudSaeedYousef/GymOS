import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/core/database/app_database.dart';
import 'package:gym_os/core/sync/sync_engine.dart';
import 'package:gym_os/features/attendance/services/attendance_api_service.dart';
import 'package:gym_os/features/home/models/drop_in_visit_models.dart';
import 'package:gym_os/features/home/services/dashboard_api_service.dart';
import 'package:gym_os/features/members/services/gym_api_service.dart';
import 'package:gym_os/features/payments/services/payment_api_service.dart';

class FakeHttpClientAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  ResponseBody Function(RequestOptions options)? handler;

  FakeHttpClientAdapter({this.handler});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (handler != null) {
      return handler!(options);
    }
    return ResponseBody.fromString(
      '{"succeeded": true, "message": "OK"}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class FakeConnectivity implements Connectivity {
  List<ConnectivityResult> currentResults;
  final StreamController<List<ConnectivityResult>> _controller =
      StreamController<List<ConnectivityResult>>.broadcast();

  FakeConnectivity([this.currentResults = const [ConnectivityResult.wifi]]);

  void emit(List<ConnectivityResult> results) {
    currentResults = results;
    _controller.add(results);
  }

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => currentResults;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;
}

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late AppDatabase db;
  late Dio dio;
  late FakeHttpClientAdapter httpAdapter;
  late FakeConnectivity connectivity;
  late SyncEngine syncEngine;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    httpAdapter = FakeHttpClientAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://gym.orderly365.top'))
      ..httpClientAdapter = httpAdapter;
    connectivity = FakeConnectivity();
    syncEngine = SyncEngine(dio: dio, db: db, connectivity: connectivity);
  });

  tearDown(() async {
    syncEngine.dispose();
    await db.close();
  });

  group('SyncEngine Push & FIFO Tests', () {
    test('pushPendingOperations dispatches outbox items with X-Idempotency-Key and clears dirty flag on 2xx', () async {
      final now = DateTime.now();
      const memberId = 'mem-push-1';
      const opId = 'op-push-1';

      // 1. Insert dirty member + outbox item
      await db.membersDao.insertLocalMemberWithOutbox(
        LocalMembersCompanion.insert(
          id: memberId,
          fullName: 'Clark Kent',
          phone: '01011112222',
          updatedAt: now,
        ),
        SyncOutboxCompanion.insert(
          operationId: opId,
          entityType: 'member_create',
          entityId: memberId,
          payloadJson: jsonEncode({'fullName': 'Clark Kent', 'phoneNumber': '01011112222'}),
          createdAt: now,
        ),
      );

      // Verify pending before push
      var pending = await db.syncOutboxDao.getPendingOperations();
      expect(pending.length, 1);

      // 2. Execute push
      await syncEngine.pushPendingOperations();

      // 3. Verify HTTP request was sent with X-Idempotency-Key
      expect(httpAdapter.requests.length, 1);
      final req = httpAdapter.requests.first;
      expect(req.path, '/api/gym/members');
      expect(req.headers['X-Idempotency-Key'], opId);
      final reqBody = req.data as Map<String, dynamic>;
      expect(reqBody['fullName'], 'Clark Kent');
      expect(reqBody['clientId'], memberId);

      // 4. Verify outbox is cleared and member is no longer dirty
      pending = await db.syncOutboxDao.getPendingOperations();
      expect(pending, isEmpty);

      final member = await (db.select(db.localMembers)..where((t) => t.id.equals(memberId))).getSingle();
      expect(member.isDirty, isFalse);
    });

    test('pushPendingOperations breaks FIFO loop on 5xx or network error without dropping item', () async {
      httpAdapter.handler = (options) {
        throw DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 500,
            statusMessage: 'Internal Server Error',
          ),
          type: DioExceptionType.badResponse,
        );
      };

      final now = DateTime.now();
      await db.into(db.syncOutbox).insert(
            SyncOutboxCompanion.insert(
              operationId: 'op-fail-1',
              entityType: 'checkin',
              entityId: 'att-1',
              payloadJson: '{}',
              createdAt: now,
            ),
          );

      await syncEngine.pushPendingOperations();

      // Row must still be in outbox with retryCount incremented
      final pending = await db.syncOutboxDao.getPendingOperations();
      expect(pending.length, 1);
      expect(pending.first.retryCount, 1);
    });

    test('pushPendingOperations marks permanent 4xx failed and continues to next FIFO item', () async {
      int callCount = 0;
      httpAdapter.handler = (options) {
        callCount++;
        if (callCount == 1) {
          throw DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 400,
              data: {'message': 'Bad validation'},
            ),
            type: DioExceptionType.badResponse,
          );
        }
        return ResponseBody.fromString('{"succeeded": true}', 200, headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        });
      };

      final now = DateTime.now();
      await db.into(db.syncOutbox).insert(
            SyncOutboxCompanion.insert(
              operationId: 'op-400',
              entityType: 'member_create',
              entityId: 'mem-bad',
              payloadJson: '{}',
              createdAt: now,
            ),
          );
      await db.into(db.syncOutbox).insert(
            SyncOutboxCompanion.insert(
              operationId: 'op-ok',
              entityType: 'checkout',
              entityId: 'att-ok',
              payloadJson: '{}',
              createdAt: now.add(const Duration(seconds: 1)),
            ),
          );

      await syncEngine.pushPendingOperations();

      // Second operation was dispatched because 4xx didn't block queue
      expect(callCount, 2);
    });
  });

  group('SyncEngine Pull Tests', () {
    test('pullLatestState pulls plans and members without overwriting dirty local records', () async {
      final now = DateTime.now();

      // Pre-seed local database with 1 clean member and 1 dirty member
      await db.into(db.localMembers).insert(
            LocalMembersCompanion.insert(
              id: 'clean-1',
              fullName: 'Clean Member',
              phone: '0100',
              updatedAt: now,
              isDirty: const Value(false),
            ),
          );
      await db.into(db.localMembers).insert(
            LocalMembersCompanion.insert(
              id: 'dirty-1',
              fullName: 'Local Dirty Edits',
              phone: '0111',
              updatedAt: now,
              isDirty: const Value(true),
            ),
          );

      httpAdapter.handler = (options) {
        if (options.path == '/api/plans') {
          return ResponseBody.fromString(
            jsonEncode([
              {'id': 'p-1', 'name': 'Gold Plan', 'price': 600, 'durationInDays': 30, 'isActive': true}
            ]),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path == '/api/gym/members') {
          return ResponseBody.fromString(
            jsonEncode({
              'items': [
                {
                  'id': 'clean-1',
                  'fullName': 'Updated Clean Name',
                  'phoneNumber': '0100-updated',
                  'activePlanName': 'Gold Plan',
                  'subscriptionStatus': 'active',
                },
                {
                  'id': 'dirty-1',
                  'fullName': 'Server Name Overwrite Attempt',
                  'phoneNumber': '0111-server',
                  'activePlanName': 'Gold Plan',
                  'subscriptionStatus': 'active',
                },
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('[]', 200, headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
      };

      await syncEngine.pullLatestState();

      // Clean member updated
      final clean = await (db.select(db.localMembers)..where((t) => t.id.equals('clean-1'))).getSingle();
      expect(clean.fullName, 'Updated Clean Name');
      expect(clean.isDirty, isFalse);

      // Dirty member preserved local modifications
      final dirty = await (db.select(db.localMembers)..where((t) => t.id.equals('dirty-1'))).getSingle();
      expect(dirty.fullName, 'Local Dirty Edits');
      expect(dirty.isDirty, isTrue);

      // Plans updated
      final activePlans = await db.plansDao.watchActivePlans().first;
      expect(activePlans.length, 1);
      expect(activePlans.first.name, 'Gold Plan');
    });

    test('syncNow runs push first then pull second, and updates last_pulled_at', () async {
      final callOrder = <String>[];
      httpAdapter.handler = (options) {
        if (options.method == 'POST') {
          callOrder.add('push:${options.path}');
        } else if (options.method == 'GET') {
          callOrder.add('pull:${options.path}');
        }
        return ResponseBody.fromString('{"items": []}', 200, headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        });
      };

      // Add 1 pending mutation
      await db.into(db.syncOutbox).insert(
            SyncOutboxCompanion.insert(
              operationId: 'op-syncnow',
              entityType: 'checkin',
              entityId: 'att-x',
              payloadJson: '{}',
              createdAt: DateTime.now(),
            ),
          );

      await syncEngine.syncNow();

      expect(callOrder.isNotEmpty, isTrue);
      expect(callOrder.first.startsWith('push'), isTrue);

      final metadata = await db.syncOutboxDao.getMetadata('last_pulled_at');
      expect(metadata, isNotNull);
    });

    test('syncNow skips network when offline', () async {
      connectivity.emit([ConnectivityResult.none]);

      await syncEngine.syncNow();

      expect(httpAdapter.requests, isEmpty);
      expect(syncEngine.isOnline, isFalse);
    });
  });

  group('Local-First Service Operations (<50ms)', () {
    test('AttendanceApiService.checkIn writes to Drift and enqueues outbox in <50ms', () async {
      connectivity.emit([ConnectivityResult.none]);
      final service = AttendanceApiService(dio, db, syncEngine);

      final stopwatch = Stopwatch()..start();
      final message = await service.checkIn('att-client-1', memberId: 'mem-1');
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(50));
      expect(message, 'تم تسجيل الحضور بنجاح');

      final inside = await db.attendanceDao.watchCurrentlyCheckedIn().first;
      expect(inside.length, 1);
      expect(inside.first.id, 'att-client-1');
      expect(inside.first.isDirty, isTrue);

      final pending = await db.syncOutboxDao.getPendingOperations();
      expect(pending.length, 1);
      expect(pending.first.entityType, 'checkin');

      // Now go online and sync
      connectivity.emit([ConnectivityResult.wifi]);
      await syncEngine.syncNow();
      expect(await db.syncOutboxDao.getPendingOperations(), isEmpty);
    });

    test('AttendanceApiService.checkOut writes to Drift and enqueues outbox in <50ms', () async {
      connectivity.emit([ConnectivityResult.none]);
      final service = AttendanceApiService(dio, db, syncEngine);
      await service.checkIn('att-out-1', memberId: 'mem-1');

      final stopwatch = Stopwatch()..start();
      final message = await service.checkOut('att-out-1');
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(50));
      expect(message, 'تم تسجيل الخروج بنجاح');

      final inside = await db.attendanceDao.watchCurrentlyCheckedIn().first;
      expect(inside, isEmpty);

      final pending = await db.syncOutboxDao.getPendingOperations();
      expect(pending.any((o) => o.entityType == 'checkout'), isTrue);
    });

    test('DashboardApiService.recordDropInVisit records attendance + payment + outbox locally', () async {
      connectivity.emit([ConnectivityResult.none]);
      final service = DashboardApiService(dio, db, syncEngine);

      const request = RecordDropInRequest(
        operationId: 'op-drop-1',
        customAmount: 50.0,
        method: 1,
        guestName: 'Visitor One',
      );

      final stopwatch = Stopwatch()..start();
      final result = await service.recordDropInVisit(request);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(50));
      expect(result.succeeded, isTrue);

      final inside = await db.attendanceDao.watchCurrentlyCheckedIn().first;
      expect(inside.length, 1);
      expect(inside.first.memberName, 'Visitor One');
      expect(inside.first.isDropIn, isTrue);
      expect(inside.first.isDirty, isTrue);

      final payments = await (db.select(db.localPayments)).get();
      expect(payments.length, 1);
      expect(payments.first.amountPaid, 50.0);
      expect(payments.first.isDirty, isTrue);
    });

    test('GymApiService.createMember records member + outbox locally in <50ms', () async {
      connectivity.emit([ConnectivityResult.none]);
      final service = GymApiService(dio, db, syncEngine);

      final stopwatch = Stopwatch()..start();
      await service.createMember(
        fullName: 'Diana Prince',
        phoneNumber: '01055556666',
        amountPaid: 300,
        method: 1,
      );
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(50));

      final members = await db.membersDao.watchAllMembers().first;
      expect(members.length, 1);
      expect(members.first.fullName, 'Diana Prince');
      expect(members.first.isDirty, isTrue);

      final pending = await db.syncOutboxDao.getPendingOperations();
      expect(pending.first.entityType, 'member_create');
    });

    test('PaymentApiService.renewSubscription records renewal + outbox locally in <50ms', () async {
      connectivity.emit([ConnectivityResult.none]);
      final paymentService = PaymentApiService(dio, db, syncEngine);
      final gymService = GymApiService(dio, db, syncEngine);

      await gymService.createMember(
        fullName: 'Bruce Wayne',
        phoneNumber: '01099998888',
      );
      final member = (await db.membersDao.watchAllMembers().first).first;

      final stopwatch = Stopwatch()..start();
      final msg = await paymentService.renewSubscription(
        memberId: member.id,
        planId: 'plan-monthly',
        paymentMethod: 1,
        amountPaid: 450,
      );
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(50));
      expect(msg, 'تم تجديد الاشتراك بنجاح');

      final updatedMember = await (db.select(db.localMembers)..where((t) => t.id.equals(member.id))).getSingle();
      expect(updatedMember.subscriptionEndDate, isNotNull);
      expect(updatedMember.isDirty, isTrue);

      final pending = await db.syncOutboxDao.getPendingOperations();
      expect(pending.any((o) => o.entityType == 'member_renew'), isTrue);
    });
  });
}
