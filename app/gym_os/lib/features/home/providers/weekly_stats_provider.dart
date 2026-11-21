import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import 'dashboard_provider.dart';

/// Strongly typed model representing aggregated activity for a single calendar day.
class DailyStatPoint {
  /// The calendar day (normalized to midnight: 00:00:00).
  final DateTime date;

  /// Total count of check-ins / visits recorded on this day.
  final int attendanceCount;

  /// Total revenue collected on this day (subscriptions + renewals + drop-ins).
  final double revenueAmount;

  const DailyStatPoint({
    required this.date,
    required this.attendanceCount,
    required this.revenueAmount,
  });

  DailyStatPoint copyWith({
    DateTime? date,
    int? attendanceCount,
    double? revenueAmount,
  }) {
    return DailyStatPoint(
      date: date ?? this.date,
      attendanceCount: attendanceCount ?? this.attendanceCount,
      revenueAmount: revenueAmount ?? this.revenueAmount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyStatPoint &&
          runtimeType == other.runtimeType &&
          date.year == other.date.year &&
          date.month == other.date.month &&
          date.day == other.date.day &&
          attendanceCount == other.attendanceCount &&
          (revenueAmount - other.revenueAmount).abs() < 0.001;

  @override
  int get hashCode => Object.hash(
        date.year,
        date.month,
        date.day,
        attendanceCount,
        revenueAmount,
      );

  @override
  String toString() =>
      'DailyStatPoint(date: ${date.toIso8601String().split('T').first}, attendance: $attendanceCount, revenue: $revenueAmount)';
}

/// Optional reference date provider for weekly stats calculation (defaults to DateTime.now).
/// Allows deterministic time overrides during tests.
final weeklyStatsReferenceDateProvider = Provider<DateTime>((ref) {
  return DateTime.now();
});

/// Pure helper to combine two streams reactively without external dependencies.
Stream<R> combineLatest2Streams<T1, T2, R>(
  Stream<T1> stream1,
  Stream<T2> stream2,
  R Function(T1 a, T2 b) combiner,
) {
  late StreamController<R> controller;
  StreamSubscription<T1>? sub1;
  StreamSubscription<T2>? sub2;
  T1? val1;
  T2? val2;
  bool hasVal1 = false;
  bool hasVal2 = false;

  void emit() {
    if (hasVal1 && hasVal2 && !controller.isClosed) {
      try {
        controller.add(combiner(val1 as T1, val2 as T2));
      } catch (e, s) {
        controller.addError(e, s);
      }
    }
  }

  controller = StreamController<R>(
    onListen: () {
      sub1 = stream1.listen(
        (v) {
          val1 = v;
          hasVal1 = true;
          emit();
        },
        onError: (Object e, StackTrace s) {
          if (!controller.isClosed) controller.addError(e, s);
        },
      );
      sub2 = stream2.listen(
        (v) {
          val2 = v;
          hasVal2 = true;
          emit();
        },
        onError: (Object e, StackTrace s) {
          if (!controller.isClosed) controller.addError(e, s);
        },
      );
    },
    onCancel: () async {
      await sub1?.cancel();
      await sub2?.cancel();
    },
  );

  return controller.stream;
}

/// Aggregates attendance and payments streams into exactly 7 ordered [DailyStatPoint] items.
Stream<List<DailyStatPoint>> aggregateWeeklyStats({
  required Stream<List<LocalAttendanceData>> attendanceStream,
  required Stream<List<LocalPayment>> paymentsStream,
  required DateTime now,
}) {
  return combineLatest2Streams(
    attendanceStream,
    paymentsStream,
    (attendanceList, paymentsList) {
      final today = DateTime(now.year, now.month, now.day);
      // Generate 7 days: oldest (today - 6) to today
      final days = List.generate(
        7,
        (i) => DateTime(today.year, today.month, today.day - (6 - i)),
      );

      return days.map((d) {
        final dayRecords = attendanceList.where((a) {
          final t = a.checkInTime;
          return t.year == d.year && t.month == d.month && t.day == d.day;
        });

        // Deduplicate distinct members per day (matching Today's Attendance distinct logic)
        final distinctMemberIds = <String>{};
        for (final a in dayRecords) {
          final id = (a.memberId != null && a.memberId!.isNotEmpty) ? a.memberId! : a.id;
          distinctMemberIds.add(id);
        }
        final count = distinctMemberIds.length;

        final rev = paymentsList.where((p) {
          final t = p.createdAt;
          return t.year == d.year && t.month == d.month && t.day == d.day;
        }).fold<double>(0.0, (sum, p) => sum + p.amountPaid);

        return DailyStatPoint(
          date: d,
          attendanceCount: count,
          revenueAmount: rev,
        );
      }).toList();
    },
  );
}

/// Offline-first reactive StreamProvider that computes the last 7 calendar days
/// directly from unified dashboard stats when available (matching getStats()),
/// with fallback to local Drift SQLite tables.
final weeklyStatsProvider =
    StreamProvider.autoDispose<List<DailyStatPoint>>((ref) {
  final now = ref.watch(weeklyStatsReferenceDateProvider);
  final attendanceDao = ref.watch(attendanceDaoProvider);
  final paymentsDao = ref.watch(paymentsDaoProvider);
  final dashboardStatsAsync = ref.watch(dashboardStatsProvider);

  final today = DateTime(now.year, now.month, now.day);
  final rangeStart = DateTime(today.year, today.month, today.day - 6, 0, 0, 0, 0);
  final rangeEnd = DateTime(today.year, today.month, today.day, 23, 59, 59, 999);

  final attendanceStream =
      attendanceDao.watchAttendanceInRange(rangeStart, rangeEnd);
  final paymentsStream =
      paymentsDao.watchPaymentsInRange(rangeStart, rangeEnd);

  final localWeeklyStream = aggregateWeeklyStats(
    attendanceStream: attendanceStream,
    paymentsStream: paymentsStream,
    now: now,
  );

  return localWeeklyStream.map((localPoints) {
    final serverStats = dashboardStatsAsync.value;
    final server7Days = serverStats?.last7DaysAttendance;

    if (server7Days == null || server7Days.isEmpty) {
      return localPoints;
    }

    // Merge server last 7 days breakdown with local points (keeping payments/revenue from local)
    return localPoints.map((lp) {
      final matchingServerStat = server7Days.cast<DailyAttendanceStat?>().firstWhere(
            (s) =>
                s != null &&
                s.date.year == lp.date.year &&
                s.date.month == lp.date.month &&
                s.date.day == lp.date.day,
            orElse: () => null,
          );

      if (matchingServerStat != null) {
        return lp.copyWith(attendanceCount: matchingServerStat.count);
      }
      return lp;
    }).toList();
  });
});
