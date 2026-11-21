import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../models/dashboard_stats_model.dart';
import '../services/dashboard_api_service.dart';

export '../models/dashboard_stats_model.dart';
export '../models/drop_in_visit_models.dart';
export '../services/dashboard_api_service.dart';
export 'weekly_stats_provider.dart';

/// StreamProvider driving Dashboard KPIs reactively from Drift local SQLite tables:
/// [LocalMembers], [LocalAttendance], and [LocalPayments].
final dashboardStatsStreamProvider =
    StreamProvider.autoDispose<DashboardStatsModel>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final controller = StreamController<DashboardStatsModel>();

  StreamSubscription? membersSub;
  StreamSubscription? attendanceSub;
  StreamSubscription? paymentsSub;

  List<LocalMember>? currentMembers;
  List<LocalAttendanceData>? currentAttendance;
  List<LocalPayment>? currentPayments;

  void recomputeAndEmit() {
    if (controller.isClosed) return;
    if (currentMembers == null ||
        currentAttendance == null ||
        currentPayments == null) {
      return;
    }

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);

    final activeCount = currentMembers!.where((m) => m.status == 1).length;
    final expiredCount = currentMembers!.where((m) => m.status != 1).length;

    final todayAtt = currentAttendance!.where((a) =>
        !a.checkInTime.isBefore(todayStart) &&
        !a.checkInTime.isAfter(todayEnd));
    
    // Deduplicate distinct member IDs (and drop-ins)
    final distinctMemberIds = <String>{};
    for (final a in todayAtt) {
      final id = (a.memberId != null && a.memberId!.isNotEmpty) ? a.memberId! : a.id;
      distinctMemberIds.add(id);
    }
    final todayCheckIns = distinctMemberIds.length;

    final insideCount =
        currentAttendance!.where((a) => a.checkOutTime == null).length;

    final monthPays = currentPayments!.where((p) =>
        !p.createdAt.isBefore(monthStart) && !p.createdAt.isAfter(monthEnd));
    final monthlyRevenue = monthPays.fold<double>(
      0.0,
      (sum, p) => sum + p.amountPaid,
    );

    final todayPays = currentPayments!.where((p) =>
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
    membersSub?.cancel();
    attendanceSub?.cancel();
    paymentsSub?.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Provider fetching gym-wide dashboard statistics.
/// Driven reactively by local Drift streams, with fallback to API.
final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStatsModel>((ref) async {
  final streamAsync = ref.watch(dashboardStatsStreamProvider);
  if (streamAsync.hasValue && streamAsync.value != null) {
    return streamAsync.value!;
  }
  final api = ref.watch(dashboardApiServiceProvider);
  return api.getStats();
});
