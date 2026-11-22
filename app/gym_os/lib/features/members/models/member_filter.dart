enum MemberFilter {
  all,
  active,
  expiringSoon,
  expired,
  today;

  String? get apiValue {
    switch (this) {
      case MemberFilter.all:
        return null;
      case MemberFilter.active:
        return 'active';
      case MemberFilter.expiringSoon:
        return 'active'; // Query active members from backend; filter expiring-soon locally
      case MemberFilter.expired:
        return 'expired';
      case MemberFilter.today:
        return 'today';
    }
  }

  static MemberFilter fromString(String? value) {
    if (value == null) return MemberFilter.all;
    switch (value.trim().toLowerCase()) {
      case 'active':
        return MemberFilter.active;
      case 'expiring_soon':
      case 'expiringsoon':
        return MemberFilter.expiringSoon;
      case 'expired':
        return MemberFilter.expired;
      case 'today':
        return MemberFilter.today;
      default:
        return MemberFilter.all;
    }
  }
}
