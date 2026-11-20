import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Available sorting options for the members directory.
enum MemberSortOption {
  newest,
  expiringSoon,
  endDateDesc,
  name,
  plan,
  lastCheckIn;

  /// Exact query parameter string expected by the backend.
  String get apiValue {
    switch (this) {
      case MemberSortOption.newest:
        return 'newest';
      case MemberSortOption.expiringSoon:
        return 'expiringSoon';
      case MemberSortOption.endDateDesc:
        return 'endDateDesc';
      case MemberSortOption.name:
        return 'name';
      case MemberSortOption.plan:
        return 'plan';
      case MemberSortOption.lastCheckIn:
        return 'lastCheckIn';
    }
  }

  /// Localized human-readable label for display in UI.
  String label(AppLocalizations l10n) {
    switch (this) {
      case MemberSortOption.newest:
        return l10n.sortNewest;
      case MemberSortOption.expiringSoon:
        return l10n.sortExpiringSoon;
      case MemberSortOption.endDateDesc:
        return l10n.sortEndDateDesc;
      case MemberSortOption.name:
        return l10n.sortNameAsc;
      case MemberSortOption.plan:
        return l10n.sortByPlan;
      case MemberSortOption.lastCheckIn:
        return l10n.sortLastCheckIn;
    }
  }

  /// Intuitive icon representing the sort criterion.
  IconData get icon {
    switch (this) {
      case MemberSortOption.newest:
        return Icons.fiber_new_rounded;
      case MemberSortOption.expiringSoon:
        return Icons.hourglass_bottom_rounded;
      case MemberSortOption.endDateDesc:
        return Icons.event_available_rounded;
      case MemberSortOption.name:
        return Icons.sort_by_alpha_rounded;
      case MemberSortOption.plan:
        return Icons.card_membership_rounded;
      case MemberSortOption.lastCheckIn:
        return Icons.fingerprint_rounded;
    }
  }

  /// Parses a string representation safely into a `MemberSortOption`.
  static MemberSortOption fromString(String? value) {
    if (value == null) return MemberSortOption.newest;
    switch (value.trim().toLowerCase()) {
      case 'expiringsoon':
        return MemberSortOption.expiringSoon;
      case 'enddatedesc':
        return MemberSortOption.endDateDesc;
      case 'name':
        return MemberSortOption.name;
      case 'plan':
        return MemberSortOption.plan;
      case 'lastcheckin':
        return MemberSortOption.lastCheckIn;
      case 'newest':
      default:
        return MemberSortOption.newest;
    }
  }
}
