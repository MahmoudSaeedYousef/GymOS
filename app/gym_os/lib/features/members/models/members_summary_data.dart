class MembersSummaryPlanItem {
  final String? planId;
  final String planName;
  final int count;

  const MembersSummaryPlanItem({
    this.planId,
    required this.planName,
    required this.count,
  });

  factory MembersSummaryPlanItem.fromJson(Map<String, dynamic> json) {
    return MembersSummaryPlanItem(
      planId: json['planId']?.toString(),
      planName: json['planName']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class MembersSummaryData {
  final int totalCount;
  final int activeCount;
  final int expiredCount;
  final int expiringSoonCount;
  final List<MembersSummaryPlanItem> plans;
  final Map<String, int> planCounts;

  const MembersSummaryData({
    this.totalCount = 0,
    this.activeCount = 0,
    this.expiredCount = 0,
    this.expiringSoonCount = 0,
    this.plans = const [],
    this.planCounts = const {},
  });

  factory MembersSummaryData.fromJson(Map<String, dynamic> json) {
    final rawPlans = json['plans'] as List<dynamic>? ?? [];
    final planItems = rawPlans
        .whereType<Map<String, dynamic>>()
        .map((e) => MembersSummaryPlanItem.fromJson(e))
        .toList();

    final map = <String, int>{};
    for (final p in planItems) {
      map[p.planName] = p.count;
    }

    final total = (json['total'] as num?)?.toInt() ?? 0;
    final active = (json['active'] as num?)?.toInt() ?? 0;
    final expired = (json['expired'] as num?)?.toInt() ?? 0;
    final expiringSoon = (json['expiringSoon'] as num?)?.toInt() ?? 0;

    return MembersSummaryData(
      totalCount: total,
      activeCount: active,
      expiredCount: expired,
      expiringSoonCount: expiringSoon,
      plans: planItems,
      planCounts: map,
    );
  }
}
