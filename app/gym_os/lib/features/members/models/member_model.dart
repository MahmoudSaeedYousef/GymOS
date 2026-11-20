class MemberModel {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? activePlanName;
  final String? subscriptionEndDate;
  final String subscriptionStatus;

  MemberModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.activePlanName,
    this.subscriptionEndDate,
    required this.subscriptionStatus,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) => MemberModel(
    id: json['id'],
    fullName: json['fullName'],
    phoneNumber: json['phoneNumber'],
    activePlanName: json['activePlanName'],
    subscriptionEndDate: json['subscriptionEndDate'],
    subscriptionStatus: json['subscriptionStatus'],
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
