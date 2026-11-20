import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/sync/sync_provider.dart';
import '../../../core/utils/uuid_generator.dart';
import '../models/member_model.dart';
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
      final res = await _dio.get(
        '/api/gym/members',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          'cursor': ?cursor,
          'pageSize': pageSize,
          'filter': ?filter,
          'sortBy': ?sortBy,
        },
      );
      return PagedMembersResponse.fromJson(res.data);
    } catch (e) {
      if (_db != null) {
        final localMembers = await _db.membersDao.watchAllMembers().first;
        final items = localMembers.map((m) {
          return MemberModel(
            id: m.id,
            fullName: m.fullName,
            phoneNumber: m.phone,
            activePlanName: m.planName,
            subscriptionEndDate: m.subscriptionEndDate?.toIso8601String(),
            subscriptionStatus: m.status == 1 ? 'active' : 'expired',
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

  /// Creates a member locally in Drift + SyncOutbox in <50ms and triggers background sync.
  Future<void> createMember({
    required String fullName,
    required String phoneNumber,
    String? planId,
    int? method,
    double? amountPaid,
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
      },
    );
  }
}
