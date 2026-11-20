enum MemberFilter {
  all,
  active,
  expired,
  today;

  String? get apiValue {
    switch (this) {
      case MemberFilter.all:
        return null;
      case MemberFilter.active:
        return 'active';
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
      case 'expired':
        return MemberFilter.expired;
      case 'today':
        return MemberFilter.today;
      default:
        return MemberFilter.all;
    }
  }
}
