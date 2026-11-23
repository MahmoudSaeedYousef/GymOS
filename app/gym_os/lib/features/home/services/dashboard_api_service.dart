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
import '../models/dashboard_stats_model.dart';
import '../models/drop_in_visit_models.dart';

final dashboardApiServiceProvider = Provider<DashboardApiService>((ref) {
  return DashboardApiService(
    ref.watch(dioProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});

class DashboardApiService {
  final Dio _dio;
  final AppDatabase? _db;
  final SyncEngine? _syncEngine;

  DashboardApiService(this._dio, [this._db, this._syncEngine]);

  Future<DashboardStatsModel> getStats() async {
    // 1. Try fetching fresh summary stats from backend
    DashboardStatsModel? serverStats;
    try {
      final response = await _dio.get(
        '/api/dashboard/stats',
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      if (response.data is Map<String, dynamic>) {
        serverStats = DashboardStatsModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        // Cache to Drift metadata
        if (_db != null) {
          await _db.syncOutboxDao.setMetadata(
            'cached_dashboard_stats',
            jsonEncode(serverStats.toJson()),
          );
        }
      }
    } catch (_) {
      // Offline or network timeout - fallback to cached / local
    }

    // 2. Read cached server stats if network was unavailable
    if (serverStats == null && _db != null) {
      final cachedJson =
          await _db.syncOutboxDao.getMetadata('cached_dashboard_stats');
      if (cachedJson != null) {
        try {
          serverStats = DashboardStatsModel.fromJson(
            jsonDecode(cachedJson) as Map<String, dynamic>,
          );
        } catch (_) {}
      }
    }

    // 3. When serverStats is available, trust it directly and only merge unsynced local check-ins
    if (serverStats != null) {
      if (_db != null) {
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

        // Query ONLY unsynced (isDirty == true) local attendance rows for today
        final unsyncedTodayAttendance = await (_db.select(_db.localAttendance)
              ..where((t) =>
                  t.isDirty.equals(true) &
                  t.checkInTime.isBiggerOrEqualValue(todayStart) &
                  t.checkInTime.isSmallerOrEqualValue(todayEnd)))
            .get();

        final unsyncedDistinctMemberIds = <String>{};
        for (final a in unsyncedTodayAttendance) {
          final id = (a.memberId != null && a.memberId!.isNotEmpty)
              ? a.memberId!
              : a.id;
          unsyncedDistinctMemberIds.add(id);
        }

        final addedUnsyncedCount = unsyncedDistinctMemberIds.length;
        final mergedTodayCount =
            serverStats.todayCheckInsCount + addedUnsyncedCount;

        List<DailyAttendanceStat>? mergedLast7DaysAttendance =
            serverStats.last7DaysAttendance;
        if (mergedLast7DaysAttendance != null && addedUnsyncedCount > 0) {
          mergedLast7DaysAttendance =
              List<DailyAttendanceStat>.from(mergedLast7DaysAttendance);
          final todayIdx = mergedLast7DaysAttendance.indexWhere((stat) =>
              stat.date.year == now.year &&
              stat.date.month == now.month &&
              stat.date.day == now.day);

          if (todayIdx != -1) {
            final existing = mergedLast7DaysAttendance[todayIdx];
            mergedLast7DaysAttendance[todayIdx] = DailyAttendanceStat(
              date: existing.date,
              count: existing.count + addedUnsyncedCount,
            );
          } else {
            mergedLast7DaysAttendance.add(
              DailyAttendanceStat(
                date: DateTime(now.year, now.month, now.day),
                count: mergedTodayCount,
              ),
            );
          }
        }

        List<DailyRevenueStat>? mergedLast7DaysRevenue =
            serverStats.last7DaysRevenue;

        return DashboardStatsModel(
          activeMembersCount: serverStats.activeMembersCount,
          expiredSubscriptionsCount: serverStats.expiredSubscriptionsCount,
          todayCheckInsCount: mergedTodayCount,
          monthlyRevenue: serverStats.monthlyRevenue,
          currentInside: serverStats.currentInside,
          todayRevenue: serverStats.todayRevenue,
          monthlyDropInRevenue: serverStats.monthlyDropInRevenue,
          last7DaysAttendance: mergedLast7DaysAttendance,
          last7DaysRevenue: mergedLast7DaysRevenue,
        );
      }
      return serverStats;
    }

    // 4. Fallback: only when serverStats == null, compute counts from local Drift tables
    if (_db != null) {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final tomorrow = todayStart.add(const Duration(days: 1));
      final monthStart = DateTime(now.year, now.month, 1);
      final nextMonth = DateTime(now.year, now.month + 1, 1);

      final allMembers = await (_db.select(_db.localMembers)).get();
      final activeCount = allMembers.where((m) => m.status == 1).length;
      final expiredCount = allMembers.where((m) => m.status != 1).length;

      // Local check-ins for today: strict [todayStart, tomorrow)
      final todayAttendance = await (_db.select(_db.localAttendance)
            ..where((t) =>
                t.checkInTime.isBiggerOrEqualValue(todayStart) &
                t.checkInTime.isSmallerThanValue(tomorrow)))
          .get();

      final localTodayDistinct = <String>{};
      for (final a in todayAttendance) {
        final id = (a.memberId != null && a.memberId!.isNotEmpty)
            ? a.memberId!
            : a.id;
        localTodayDistinct.add(id);
      }
      final todayCheckIns = localTodayDistinct.length;

      final currentlyInsideList = await (_db.select(_db.localAttendance)
            ..where((t) => t.checkOutTime.isNull()))
          .get();
      final currentInside = currentlyInsideList.length;

      final monthPayments = await (_db.select(_db.localPayments)
            ..where((t) =>
                t.createdAt.isBiggerOrEqualValue(monthStart) &
                t.createdAt.isSmallerThanValue(nextMonth)))
          .get();
      final monthlyRevenue = monthPayments.fold<double>(
        0.0,
        (sum, p) => sum + p.amountPaid,
      );

      // Strict [todayStart, tomorrow) boundary including single-session / guest payments
      final todayPayments = await (_db.select(_db.localPayments)
            ..where((t) =>
                t.createdAt.isBiggerOrEqualValue(todayStart) &
                t.createdAt.isSmallerThanValue(tomorrow)))
          .get();
      final todayRevenue = todayPayments.fold<double>(
        0.0,
        (sum, p) => sum + p.amountPaid,
      );

      final monthDropIns = monthPayments.where((p) => p.type == 2 || p.type == 3);
      final monthlyDropInRevenue = monthDropIns.fold<double>(
        0.0,
        (sum, p) => sum + p.amountPaid,
      );

      return DashboardStatsModel(
        activeMembersCount: activeCount,
        expiredSubscriptionsCount: expiredCount,
        todayCheckInsCount: todayCheckIns,
        monthlyRevenue: monthlyRevenue,
        currentInside: currentInside,
        todayRevenue: todayRevenue,
        monthlyDropInRevenue: monthlyDropInRevenue,
      );
    }

    try {
      final response = await _dio.get('/api/dashboard/stats');
      if (response.data is Map<String, dynamic>) {
        return DashboardStatsModel.fromJson(
            response.data as Map<String, dynamic>);
      }
      throw Exception('Invalid dashboard stats response format');
    } on DioException catch (e) {
      final errorMsg =
          e.response?.data?['message'] ?? 'Failed to load dashboard statistics';
      throw Exception(errorMsg);
    }
  }

  /// Records a drop-in visit locally in Drift + SyncOutbox in <50ms and triggers background sync.
  Future<DropInVisitResult> recordDropInVisit(
      RecordDropInRequest request) async {
    if (_db != null) {
      final attId = UuidGenerator.v4();
      final payId = UuidGenerator.v4();
      final opId = request.operationId.isNotEmpty
          ? request.operationId
          : UuidGenerator.v4();
      final now = DateTime.now();

      await _db.attendanceDao.recordDropInWithOutbox(
        attendance: LocalAttendanceCompanion.insert(
          id: attId,
          memberName: (request.guestName != null &&
                  request.guestName!.trim().isNotEmpty)
              ? request.guestName!.trim()
              : 'Guest / زائر',
          memberPhone: Value(request.guestPhone),
          checkInTime: now,
          isDropIn: const Value(true),
          isDirty: const Value(true),
        ),
        payment: LocalPaymentsCompanion.insert(
          id: payId,
          memberName: Value(request.guestName),
          planId: Value(request.planId),
          amountPaid: request.customAmount,
          method: request.method,
          type: 3, // Drop-in
          createdAt: now,
          isDirty: const Value(true),
        ),
        outboxEntry: SyncOutboxCompanion.insert(
          operationId: opId,
          entityType: 'dropin',
          entityId: attId,
          payloadJson: jsonEncode(request.toJson()
            ..addAll({
              'clientId': attId,
              'attendanceId': attId,
              'paymentId': payId,
              'occurredAtUtc': now.toUtc().toIso8601String(),
            })),
          createdAt: now,
        ),
      );

      unawaited(_syncEngine?.syncNow());

      return DropInVisitResult(
        succeeded: true,
        message: 'تم تسجيل الزيارة بنجاح',
        attendanceId: attId,
        paymentId: payId,
        amountPaid: request.customAmount,
      );
    }

    try {
      final response = await _dio.post(
        '/api/visits/drop-in',
        data: request.toJson(),
      );
      if (response.data is Map<String, dynamic>) {
        return DropInVisitResult.fromJson(
            response.data as Map<String, dynamic>);
      }
      throw Exception('Invalid drop-in visit response format');
    } on DioException catch (e) {
      final errorMsg =
          e.response?.data?['message'] ?? 'Failed to record drop-in visit';
      throw Exception(errorMsg);
    }
  }
}
