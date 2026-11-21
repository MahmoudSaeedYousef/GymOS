/// Strongly typed model representing daily attendance count in the dashboard.
class DailyAttendanceStat {
  final DateTime date;
  final int count;

  const DailyAttendanceStat({required this.date, required this.count});

  factory DailyAttendanceStat.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    final rawDate = json['date'] ?? json['Date'];
    if (rawDate != null) {
      final parsed = DateTime.tryParse(rawDate.toString());
      if (parsed != null) parsedDate = parsed.toLocal();
    }

    int parsedCount = 0;
    final rawCount = json['count'] ?? json['Count'];
    if (rawCount is int) {
      parsedCount = rawCount;
    } else if (rawCount is num) {
      parsedCount = rawCount.toInt();
    } else if (rawCount is String) {
      parsedCount = int.tryParse(rawCount) ?? 0;
    }

    return DailyAttendanceStat(date: parsedDate, count: parsedCount);
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'count': count,
  };
}

/// Model representing gym-wide KPI statistics for the dashboard.
class DashboardStatsModel {
  final int activeMembersCount;
  final int expiredSubscriptionsCount;
  final int todayCheckInsCount;
  final double monthlyRevenue;
  final int currentInside;
  final double todayRevenue;
  final double monthlyDropInRevenue;
  final List<DailyAttendanceStat>? last7DaysAttendance;

  const DashboardStatsModel({
    required this.activeMembersCount,
    required this.expiredSubscriptionsCount,
    required this.todayCheckInsCount,
    required this.monthlyRevenue,
    required this.currentInside,
    this.todayRevenue = 0.0,
    this.monthlyDropInRevenue = 0.0,
    this.last7DaysAttendance,
  });

  /// Alias for [todayCheckInsCount] to match backend naming
  int get todayAttendanceCount => todayCheckInsCount;

  /// Backward-compatible alias for [currentInside].
  int get currentInsideCount => currentInside;

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    List<DailyAttendanceStat>? parseLast7Days(dynamic value) {
      if (value is List) {
        return value
            .map((item) {
              if (item is Map<String, dynamic>) {
                return DailyAttendanceStat.fromJson(item);
              }
              return null;
            })
            .whereType<DailyAttendanceStat>()
            .toList();
      }
      return null;
    }

    final raw7Days =
        json['last7DaysAttendance'] ?? json['Last7DaysAttendance'];

    return DashboardStatsModel(
      activeMembersCount: parseInt(
        json['activeMembersCount'] ?? json['ActiveMembersCount'],
      ),
      expiredSubscriptionsCount: parseInt(
        json['expiredSubscriptionsCount'] ?? json['ExpiredSubscriptionsCount'],
      ),
      todayCheckInsCount: parseInt(
        json['todayAttendanceCount'] ??
            json['TodayAttendanceCount'] ??
            json['todayCheckInsCount'] ??
            json['TodayCheckInsCount'],
      ),
      monthlyRevenue: parseDouble(
        json['monthlyRevenue'] ?? json['MonthlyRevenue'],
      ),
      currentInside: parseInt(
        json['currentInside'] ?? json['CurrentInside'],
      ),
      todayRevenue: parseDouble(
        json['todayRevenue'] ?? json['TodayRevenue'],
      ),
      monthlyDropInRevenue: parseDouble(
        json['monthlyDropInRevenue'] ?? json['MonthlyDropInRevenue'],
      ),
      last7DaysAttendance: parseLast7Days(raw7Days),
    );
  }

  Map<String, dynamic> toJson() => {
    'activeMembersCount': activeMembersCount,
    'expiredSubscriptionsCount': expiredSubscriptionsCount,
    'todayCheckInsCount': todayCheckInsCount,
    'monthlyRevenue': monthlyRevenue,
    'currentInside': currentInside,
    'todayRevenue': todayRevenue,
    'monthlyDropInRevenue': monthlyDropInRevenue,
    if (last7DaysAttendance != null)
      'last7DaysAttendance':
          last7DaysAttendance!.map((d) => d.toJson()).toList(),
  };

  /// Formatted revenue string with K suffix for large amounts (e.g. 24K).
  String get formattedRevenue {
    if (monthlyRevenue >= 1000) {
      return '${(monthlyRevenue / 1000).toStringAsFixed(1)}K';
    }
    return monthlyRevenue.toInt().toString();
  }

  num get revenueDisplayValue =>
      monthlyRevenue >= 1000 ? (monthlyRevenue / 1000) : monthlyRevenue;
  String get revenueSuffix => monthlyRevenue >= 1000 ? 'K' : '';
  int get revenueFractionDigits =>
      monthlyRevenue >= 1000 && (monthlyRevenue % 1000 != 0) ? 1 : 0;
}
