import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../models/dashboard_stats_model.dart';

export '../models/dashboard_stats_model.dart';
export '../models/drop_in_visit_models.dart';
export '../services/dashboard_api_service.dart';
export 'weekly_stats_provider.dart';

/// Reactive StreamProvider driving Dashboard KPIs directly from Drift:
/// Combines `watchMetadata('cached_dashboard_stats')` with local tables.
/// When `cached_dashboard_stats` is present, it uses server numbers as the base
/// and merges ONLY unsynced (`isDirty == true`) local delta (preventing double-counting).
/// When `cached_dashboard_stats` is null, falls back to computing totals from local Drift tables.
final dashboardStatsStreamProvider =
    StreamProvider.autoDispose<DashboardStatsModel>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final controller = StreamController<DashboardStatsModel>();

  StreamSubscription? metadataSub;
  StreamSubscription? membersSub;
  StreamSubscription? attendanceSub;
  StreamSubscription? paymentsSub;

  String? currentMetadataJson;
  List<LocalMember>? currentMembers;
  List<LocalAttendanceData>? currentAttendance;
  List<LocalPayment>? currentPayments;

  void recomputeAndEmit() {
    if (controller.isClosed) return;

    DashboardStatsModel? cachedStats;
    if (currentMetadataJson != null && currentMetadataJson!.isNotEmpty) {
      try {
        final decoded = jsonDecode(currentMetadataJson!);
        if (decoded is Map<String, dynamic>) {
          cachedStats = DashboardStatsModel.fromJson(decoded);
        }
      } catch (_) {}
    }

    // If cachedStats is not available yet, we cannot compute the local fallback
    // until local Drift tables have loaded.
    if (cachedStats == null) {
      if (currentMembers == null ||
          currentAttendance == null ||
          currentPayments == null) {
        return;
      }
    }

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);

    if (cachedStats != null) {
      // 1. Base values from cached server stats
      final baseActive = cachedStats.activeMembersCount;
      final baseExpired = cachedStats.expiredSubscriptionsCount;
      final baseTodayCheckIns = cachedStats.todayCheckInsCount;
      final baseMonthlyRevenue = cachedStats.monthlyRevenue;
      final baseInside = cachedStats.currentInside;
      final baseTodayRevenue = cachedStats.todayRevenue;
      final baseMonthlyDropInRevenue = cachedStats.monthlyDropInRevenue;

      // 2. Unsynced local payments created today / this month
      final paymentsList = currentPayments ?? const <LocalPayment>[];
      final unsyncedPayments = paymentsList.where((p) => p.isDirty == true);

      final unsyncedTodayRevenue = unsyncedPayments
          .where((p) =>
              !p.createdAt.isBefore(todayStart) &&
              !p.createdAt.isAfter(todayEnd))
          .fold<double>(0.0, (sum, p) => sum + p.amountPaid);

      final unsyncedMonthRevenue = unsyncedPayments
          .where((p) =>
              !p.createdAt.isBefore(monthStart) &&
              !p.createdAt.isAfter(monthEnd))
          .fold<double>(0.0, (sum, p) => sum + p.amountPaid);

      final unsyncedMonthDropInRevenue = unsyncedPayments
          .where((p) =>
              p.type == 2 &&
              !p.createdAt.isBefore(monthStart) &&
              !p.createdAt.isAfter(monthEnd))
          .fold<double>(0.0, (sum, p) => sum + p.amountPaid);

      // 3. Unsynced attendance for today
      // Synced member IDs who already have a record today (isDirty == false)
      final attendanceList = currentAttendance ?? const <LocalAttendanceData>[];
      final syncedTodayMemberIds = <String>{};
      for (final a in attendanceList) {
        if (a.isDirty == false &&
            !a.checkInTime.isBefore(todayStart) &&
            !a.checkInTime.isAfter(todayEnd)) {
          if (a.memberId != null && a.memberId!.isNotEmpty) {
            syncedTodayMemberIds.add(a.memberId!);
          }
        }
      }

      // Count distinct memberId (or id for guests) from unsynced localAttendance for today
      // EXCLUDING any memberId that already has a synced attendance record today
      final unsyncedTodayAttendance = attendanceList.where((a) =>
          a.isDirty == true &&
          !a.checkInTime.isBefore(todayStart) &&
          !a.checkInTime.isAfter(todayEnd));

      final unsyncedDistinctIds = <String>{};
      for (final a in unsyncedTodayAttendance) {
        final id = (a.memberId != null && a.memberId!.isNotEmpty)
            ? a.memberId!
            : a.id;
        // If it's a member with memberId, exclude if already synced today
        if (a.memberId != null && a.memberId!.isNotEmpty) {
          if (!syncedTodayMemberIds.contains(a.memberId!)) {
            unsyncedDistinctIds.add(id);
          }
        } else {
          // Guest / drop-in visit: distinct by id
          unsyncedDistinctIds.add(id);
        }
      }
      final unsyncedTodayAttendanceDelta = unsyncedDistinctIds.length;

      // 4. Currently inside: add unsynced localAttendance with checkOutTime == null (deduplicated by memberId)
      final unsyncedInsideAttendance = attendanceList.where((a) =>
          a.isDirty == true && a.checkOutTime == null);
      final unsyncedInsideDistinctIds = <String>{};
      for (final a in unsyncedInsideAttendance) {
        final id = (a.memberId != null && a.memberId!.isNotEmpty)
            ? a.memberId!
            : a.id;
        unsyncedInsideDistinctIds.add(id);
      }
      final unsyncedInsideDelta = unsyncedInsideDistinctIds.length;

      // 5. Update last7DaysAttendance today bar
      List<DailyAttendanceStat>? mergedLast7Days = cachedStats.last7DaysAttendance;
      if (mergedLast7Days != null) {
        mergedLast7Days = List<DailyAttendanceStat>.from(mergedLast7Days);
        final todayIdx = mergedLast7Days.indexWhere((stat) =>
            stat.date.year == now.year &&
            stat.date.month == now.month &&
            stat.date.day == now.day);

        if (todayIdx != -1) {
          final existing = mergedLast7Days[todayIdx];
          mergedLast7Days[todayIdx] = DailyAttendanceStat(
            date: existing.date,
            count: existing.count + unsyncedTodayAttendanceDelta,
          );
        } else if (unsyncedTodayAttendanceDelta > 0) {
          mergedLast7Days.add(
            DailyAttendanceStat(
              date: DateTime(now.year, now.month, now.day),
              count: baseTodayCheckIns + unsyncedTodayAttendanceDelta,
            ),
          );
        }
      }

      controller.add(
        DashboardStatsModel(
          activeMembersCount: baseActive,
          expiredSubscriptionsCount: baseExpired,
          todayCheckInsCount: baseTodayCheckIns + unsyncedTodayAttendanceDelta,
          monthlyRevenue: baseMonthlyRevenue + unsyncedMonthRevenue,
          currentInside: baseInside + unsyncedInsideDelta,
          todayRevenue: baseTodayRevenue + unsyncedTodayRevenue,
          monthlyDropInRevenue:
              baseMonthlyDropInRevenue + unsyncedMonthDropInRevenue,
          last7DaysAttendance: mergedLast7Days,
        ),
      );
    } else {
      // Offline fallback: compute entirely from local tables
      final membersList = currentMembers!;
      final attendanceList = currentAttendance!;
      final paymentsList = currentPayments!;

      final activeCount = membersList.where((m) => m.status == 1).length;
      final expiredCount = membersList.where((m) => m.status != 1).length;

      final todayAtt = attendanceList.where((a) =>
          !a.checkInTime.isBefore(todayStart) &&
          !a.checkInTime.isAfter(todayEnd));

      final distinctMemberIds = <String>{};
      for (final a in todayAtt) {
        final id =
            (a.memberId != null && a.memberId!.isNotEmpty) ? a.memberId! : a.id;
        distinctMemberIds.add(id);
      }
      final todayCheckIns = distinctMemberIds.length;

      final insideCount =
          attendanceList.where((a) => a.checkOutTime == null).length;

      final monthPays = paymentsList.where((p) =>
          !p.createdAt.isBefore(monthStart) && !p.createdAt.isAfter(monthEnd));
      final monthlyRevenue = monthPays.fold<double>(
        0.0,
        (sum, p) => sum + p.amountPaid,
      );

      final todayPays = paymentsList.where((p) =>
          !p.createdAt.isBefore(todayStart) && !p.createdAt.isAfter(todayEnd));
      final todayRevenue = todayPays.fold<double>(
        0.0,
        (sum, p) => sum + p.amountPaid,
      );

      final monthlyDropInRevenue = monthPays
          .where((p) => p.type == 2)
          .fold<double>(0.0, (sum, p) => sum + p.amountPaid);

      controller.add(
        DashboardStatsModel(
          activeMembersCount: activeCount,
          expiredSubscriptionsCount: expiredCount,
          todayCheckInsCount: todayCheckIns,
          monthlyRevenue: monthlyRevenue,
          currentInside: insideCount,
          todayRevenue: todayRevenue,
          monthlyDropInRevenue: monthlyDropInRevenue,
        ),
      );
    }
  }

  metadataSub = db.syncOutboxDao
      .watchMetadata('cached_dashboard_stats')
      .listen((json) {
    currentMetadataJson = json;
    recomputeAndEmit();
  });

  membersSub = db.membersDao.watchAllMembers().listen((members) {
    currentMembers = members;
    recomputeAndEmit();
  });

  attendanceSub =
      (db.select(db.localAttendance)).watch().listen((attendance) {
    currentAttendance = attendance;
    recomputeAndEmit();
  });

  paymentsSub = (db.select(db.localPayments)).watch().listen((payments) {
    currentPayments = payments;
    recomputeAndEmit();
  });

  ref.onDispose(() {
    metadataSub?.cancel();
    membersSub?.cancel();
    attendanceSub?.cancel();
    paymentsSub?.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Reactive provider fetching gym-wide dashboard statistics from Drift stream.
final dashboardStatsProvider =
    StreamProvider.autoDispose<DashboardStatsModel>((ref) {
  final stream = ref.watch(dashboardStatsStreamProvider);
  return stream.when(
    skipLoadingOnReload: true,
    skipLoadingOnRefresh: true,
    data: (data) => Stream.value(data),
    error: (err, stack) => Stream.error(err, stack),
    loading: () => const Stream.empty(),
  );
});
