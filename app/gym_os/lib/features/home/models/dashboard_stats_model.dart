/// Model representing gym-wide KPI statistics for the dashboard.
class DashboardStatsModel {
  final int activeMembersCount;
  final int expiredSubscriptionsCount;
  final int todayCheckInsCount;
  final double monthlyRevenue;
  final int currentInside;
  final double todayRevenue;
  final double monthlyDropInRevenue;

  const DashboardStatsModel({
    required this.activeMembersCount,
    required this.expiredSubscriptionsCount,
    required this.todayCheckInsCount,
    required this.monthlyRevenue,
    required this.currentInside,
    this.todayRevenue = 0.0,
    this.monthlyDropInRevenue = 0.0,
  });

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

    return DashboardStatsModel(
      activeMembersCount: parseInt(
        json['activeMembersCount'] ?? json['ActiveMembersCount'],
      ),
      expiredSubscriptionsCount: parseInt(
        json['expiredSubscriptionsCount'] ?? json['ExpiredSubscriptionsCount'],
      ),
      todayCheckInsCount: parseInt(
        json['todayCheckInsCount'] ?? json['TodayCheckInsCount'],
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
