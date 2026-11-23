import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/sync/sync_provider.dart';
import '../../../core/utils/uuid_generator.dart';
import '../models/member_model.dart';
import '../models/members_summary_data.dart';
import '../models/plan_model.dart';

final gymApiServiceProvider = Provider<GymApiService>((ref) {
  return GymApiService(
    ref.watch(dioProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});

typedef MembersApiService = GymApiService;
final membersApiServiceProvider = gymApiServiceProvider;

class GymApiService {
  final Dio _dio;
  final AppDatabase? _db;
  final SyncEngine? _syncEngine;

  GymApiService(this._dio, [this._db, this._syncEngine]);

  Future<List<PlanModel>> getPlans() async {
    if (_db != null) {
      final localPlans = await _db.plansDao.watchActivePlans().first;
      if (localPlans.isNotEmpty) {
        return localPlans
            .map((p) => PlanModel(
                  id: p.id,
                  name: p.name,
                  price: p.price,
                  durationInDays: p.durationDays,
                  isActive: p.isActive,
                ))
            .toList();
      }
    }

    try {
      final res = await _dio.get('/api/gym/plans');
      return (res.data as List).map((e) => PlanModel.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<PagedMembersResponse> getMembers({
    String? search,
    String? cursor,
    int pageSize = 20,
    String? filter,
    String? sortBy,
  }) async {
    // Try online first; on error or offline, fallback to local Drift records
    try {
      final queryParams = {
        if (search != null && search.isNotEmpty) 'search': search,
        'cursor': ?cursor,
        'pageSize': pageSize,
        'filter': ?filter,
        'status': ?filter,
        'sortBy': ?sortBy,
      };
      Response res;
      try {
        res = await _dio.get('/api/members', queryParameters: queryParams);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          res = await _dio.get('/api/gym/members', queryParameters: queryParams);
        } else {
          rethrow;
        }
      }
      return PagedMembersResponse.fromJson(res.data);
    } catch (e) {
      if (_db != null) {
        if (filter == 'today') {
          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);
          final todayEnd = todayStart.add(const Duration(days: 1));
          final todayMembers = await _db.membersDao.getTodayAttendanceMembers(
            todayStart: todayStart,
            todayEnd: todayEnd,
          );
          final items = todayMembers.map((m) {
            final isSingleSession = m.isGuest || m.planName == 'حصة منفردة';
            return MemberModel(
              id: m.id,
              fullName: m.fullName,
              phoneNumber: m.phone,
              activePlanName: isSingleSession ? 'حصة منفردة' : m.planName,
              subscriptionEndDate: m.subscriptionEndDate?.toIso8601String(),
              subscriptionStatus: m.status == 1 ? 'active' : 'expired',
              isGuest: m.isGuest,
              isSingleSession: isSingleSession,
              photoUrl: m.photoUrl,
              gender: m.gender,
            );
          }).toList();

          return PagedMembersResponse(
            items: items,
            hasMore: false,
            nextCursor: null,
          );
        }

        final localMembers = await _db.membersDao.watchAllMembers().first;
        var filtered = localMembers.where((m) => !m.isGuest);
        if (filter == 'active') {
          filtered = filtered.where((m) => m.status == 1);
        } else if (filter == 'expiring_soon') {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          filtered = filtered.where((m) {
            if (m.status != 1 || m.subscriptionEndDate == null) return false;
            final end = DateTime(
              m.subscriptionEndDate!.year,
              m.subscriptionEndDate!.month,
              m.subscriptionEndDate!.day,
            );
            final days = end.difference(today).inDays;
            return days >= 0 && days <= 5;
          });
        } else if (filter == 'expired') {
          filtered = filtered.where((m) => m.status != 1);
        }
        final items = filtered.map((m) {
          return MemberModel(
            id: m.id,
            fullName: m.fullName,
            phoneNumber: m.phone,
            activePlanName: m.planName,
            subscriptionEndDate: m.subscriptionEndDate?.toIso8601String(),
            subscriptionStatus: m.status == 1 ? 'active' : 'expired',
            photoUrl: m.photoUrl,
          );
        }).toList();

        return PagedMembersResponse(
          items: items,
          hasMore: false,
          nextCursor: null,
        );
      }
      rethrow;
    }
  }

  Future<MembersSummaryData> getMembersSummary() async {
    try {
      Response res;
      try {
        res = await _dio.get('/api/members/summary');
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          res = await _dio.get('/api/gym/members/summary');
        } else {
          rethrow;
        }
      }
      if (res.data is Map<String, dynamic>) {
        return MembersSummaryData.fromJson(res.data as Map<String, dynamic>);
      }
      throw Exception('Invalid summary response');
    } catch (e) {
      if (_db != null) {
        final list = await _db.membersDao.watchAllMembers().first;
        final nonGuestList = list.where((m) => !m.isGuest).toList();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        int active = 0;
        int expiringSoon = 0;
        int expired = 0;
        final planMap = <String, int>{};

        for (final m in nonGuestList) {
          if (m.status == 1) {
            active++;
            if (m.subscriptionEndDate != null) {
              final end = DateTime(
                m.subscriptionEndDate!.year,
                m.subscriptionEndDate!.month,
                m.subscriptionEndDate!.day,
              );
              final days = end.difference(today).inDays;
              if (days >= 0 && days <= 5) {
                expiringSoon++;
              }
            }
          } else {
            expired++;
          }

          final rawPlan = m.planName?.trim();
          final planKey = (rawPlan != null && rawPlan.isNotEmpty) ? rawPlan : '';
          planMap[planKey] = (planMap[planKey] ?? 0) + 1;
        }

        final planItems = planMap.entries
            .map((e) => MembersSummaryPlanItem(planName: e.key, count: e.value))
            .toList();

        return MembersSummaryData(
          totalCount: nonGuestList.length,
          activeCount: active,
          expiredCount: expired,
          expiringSoonCount: expiringSoon,
          plans: planItems,
          planCounts: planMap,
        );
      }
      rethrow;
    }
  }

  /// Creates a member locally in Drift + SyncOutbox in <50ms and triggers background sync.
  Future<void> createMember({
    required String fullName,
    required String phoneNumber,
    String? planId,
    int? method,
    double? amountPaid,
    int gender = 0,
  }) async {
    if (_db != null) {
      final memberId = UuidGenerator.v4();
      final opId = UuidGenerator.v4();
      final now = DateTime.now();

      LocalPlan? plan;
      if (planId != null) {
        plan = await (_db.select(_db.localPlans)
              ..where((t) => t.id.equals(planId)))
            .getSingleOrNull();
      }

      final endDate = plan != null ? now.add(Duration(days: plan.durationDays)) : null;

      LocalPaymentsCompanion? payment;
      if (amountPaid != null && amountPaid > 0) {
        payment = LocalPaymentsCompanion.insert(
          id: UuidGenerator.v4(),
          memberId: Value(memberId),
          memberName: Value(fullName),
          planId: Value(planId),
          amountPaid: amountPaid,
          method: method ?? 1,
          type: 1, // Subscription
          createdAt: now,
          isDirty: const Value(true),
        );
      }

      await _db.membersDao.insertLocalMemberWithOutbox(
        LocalMembersCompanion.insert(
          id: memberId,
          fullName: fullName,
          phone: phoneNumber,
          planId: Value(planId),
          planName: Value(plan?.name),
          subscriptionStartDate: Value(plan != null ? now : null),
          subscriptionEndDate: Value(endDate),
          gender: Value(gender),
          status: Value(plan != null ? 1 : 0),
          updatedAt: now,
          isDirty: const Value(true),
        ),
        SyncOutboxCompanion.insert(
          operationId: opId,
          entityType: 'member_create',
          entityId: memberId,
          payloadJson: jsonEncode({
            'id': memberId,
            'clientId': memberId,
            'fullName': fullName,
            'phoneNumber': phoneNumber,
            'planId': planId,
            'method': method,
            'amountPaid': amountPaid,
            'gender': gender,
            'occurredAtUtc': now.toUtc().toIso8601String(),
          }),
          createdAt: now,
        ),
        payment: payment,
      );

      unawaited(_syncEngine?.syncNow());
      return;
    }

    await _dio.post(
      '/api/gym/members',
      data: {
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'planId': ?planId,
        'method': ?method,
        'amountPaid': ?amountPaid,
        'gender': gender,
      },
    );
  }

  /// Updates member's name and phone number (Admin/Manager).
  Future<MemberModel> updateMember(
    String id, {
    required String fullName,
    required String phoneNumber,
    int? gender,
  }) async {
    final payload = <String, dynamic>{
      'fullName': fullName,
      'phoneNumber': phoneNumber,
    };
    if (gender != null) {
      payload['gender'] = gender;
    }

    final res = await _dio.put(
      '/api/members/$id',
      data: payload,
    );

    final updated = MemberModel.fromJson(res.data as Map<String, dynamic>);

    if (_db != null) {
      await (_db.update(_db.localMembers)..where((t) => t.id.equals(id))).write(
        LocalMembersCompanion(
          fullName: Value(fullName),
          phone: Value(phoneNumber),
          photoUrl: Value(updated.photoUrl),
          gender: gender != null ? Value(gender) : (updated.gender != 0 ? Value(updated.gender) : const Value.absent()),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }

    return updated;
  }

  /// Deletes a member's photo avatar and clears it locally in Drift.
  Future<void> deleteMemberPhoto(String id) async {
    // 1. Immediately clear photoUrl locally in Drift so UI updates with 0 latency
    if (_db != null) {
      await (_db.update(_db.localMembers)..where((t) => t.id.equals(id))).write(
        LocalMembersCompanion(
          photoUrl: const Value(null),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }

    // 2. Call backend delete-photo endpoint
    try {
      await _dio.delete('/api/members/$id/photo');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Fallback to /api/gym/members/$id/photo if needed
        try {
          await _dio.delete('/api/gym/members/$id/photo');
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Uploads a member's photo avatar using multipart/form-data.
  Future<String> uploadMemberPhoto(String id, File file) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      ),
    });

    final res = await _dio.post(
      '/api/members/$id/photo',
      data: formData,
    );

    final data = res.data as Map<String, dynamic>;
    final photoUrl = data['photoUrl'] as String? ?? data['photo_url'] as String? ?? '';

    if (_db != null && photoUrl.isNotEmpty) {
      await (_db.update(_db.localMembers)..where((t) => t.id.equals(id))).write(
        LocalMembersCompanion(
          photoUrl: Value(photoUrl),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }

    return photoUrl;
  }
}
