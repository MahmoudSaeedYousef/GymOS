enum MemberSubscriptionStatus {
  active,
  expiringSoon,
  expired,
  withoutPlan,
}

class MemberModel {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? activePlanName;
  final String? subscriptionEndDate;
  final String subscriptionStatus;
  final bool isGuest;

  MemberModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.activePlanName,
    this.subscriptionEndDate,
    required this.subscriptionStatus,
    this.isGuest = false,
  });

  MemberSubscriptionStatus get status {
    final endDateStr = subscriptionEndDate;
    final planName = activePlanName;
    final hasNoPlan = planName == null || planName.trim().isEmpty;

    if (endDateStr == null || endDateStr.trim().isEmpty) {
      return MemberSubscriptionStatus.withoutPlan;
    }

    final endDate = DateTime.tryParse(endDateStr);
    if (endDate == null) {
      return MemberSubscriptionStatus.withoutPlan;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(endDate.year, endDate.month, endDate.day);
    final daysRemaining = endDay.difference(today).inDays;

    if (hasNoPlan && daysRemaining >= 0) {
      return MemberSubscriptionStatus.withoutPlan;
    }

    final statusStr = subscriptionStatus.toLowerCase();
    if (statusStr != 'active' || daysRemaining < 0) {
      return MemberSubscriptionStatus.expired;
    }

    if (daysRemaining <= 5) {
      return MemberSubscriptionStatus.expiringSoon;
    }

    return MemberSubscriptionStatus.active;
  }

  bool get isExpiringSoon {
    if (subscriptionStatus.toLowerCase() != 'active') return false;
    final endStr = subscriptionEndDate;
    if (endStr == null || endStr.trim().isEmpty) return false;
    final endDate = DateTime.tryParse(endStr);
    if (endDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(endDate.year, endDate.month, endDate.day);
    final differenceInDays = endDay.difference(today).inDays;

    return differenceInDays >= 0 && differenceInDays <= 5;
  }

  factory MemberModel.fromJson(Map<String, dynamic> json) => MemberModel(
    id: json['id'],
    fullName: json['fullName'],
    phoneNumber: json['phoneNumber'],
    activePlanName: json['activePlanName'],
    subscriptionEndDate: json['subscriptionEndDate'],
    subscriptionStatus: json['subscriptionStatus'],
    isGuest: json['isGuest'] as bool? ?? json['is_guest'] as bool? ?? false,
  );
}

class PagedMembersResponse {
  final List<MemberModel> items;
  final String? nextCursor;
  final bool hasMore;

  PagedMembersResponse({
    required this.items,
    this.nextCursor,
    required this.hasMore,
  });

  factory PagedMembersResponse.fromJson(Map<String, dynamic> json) =>
      PagedMembersResponse(
        items: (json['items'] as List)
            .map((e) => MemberModel.fromJson(e))
            .toList(),
        nextCursor: json['nextCursor'],
        hasMore: json['hasMore'],
      );
}
