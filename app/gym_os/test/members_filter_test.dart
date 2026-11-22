import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/features/members/models/member_model.dart';
import 'package:gym_os/features/members/providers/members_provider.dart';

void main() {
  group('MemberFilter tests', () {
    test('fromString parses correctly', () {
      expect(MemberFilter.fromString('active'), MemberFilter.active);
      expect(MemberFilter.fromString('ACTIVE'), MemberFilter.active);
      expect(MemberFilter.fromString('expiring_soon'), MemberFilter.expiringSoon);
      expect(MemberFilter.fromString('expiringsoon'), MemberFilter.expiringSoon);
      expect(MemberFilter.fromString('expired'), MemberFilter.expired);
      expect(MemberFilter.fromString('today'), MemberFilter.today);
      expect(MemberFilter.fromString('unknown'), MemberFilter.all);
      expect(MemberFilter.fromString(null), MemberFilter.all);
    });

    test('apiValue matches backend query param', () {
      expect(MemberFilter.all.apiValue, isNull);
      expect(MemberFilter.active.apiValue, 'active');
      expect(MemberFilter.expiringSoon.apiValue, 'expiring_soon');
      expect(MemberFilter.expired.apiValue, 'expired');
      expect(MemberFilter.today.apiValue, 'today');
    });

    test('MembersState filteredMembers filters active, expiring soon, and expired accurately', () {
      final members = [
        MemberModel(
          id: '1',
          fullName: 'Active Member',
          phoneNumber: '01000000001',
          subscriptionStatus: 'Active',
          activePlanName: 'Monthly',
          subscriptionEndDate: DateTime.now().add(const Duration(days: 20)).toIso8601String(),
        ),
        MemberModel(
          id: '2',
          fullName: 'Expiring Soon Member',
          phoneNumber: '01000000002',
          subscriptionStatus: 'Active',
          activePlanName: 'Monthly',
          subscriptionEndDate: DateTime.now().add(const Duration(days: 2)).toIso8601String(),
        ),
        MemberModel(
          id: '3',
          fullName: 'Expired Member',
          phoneNumber: '01000000003',
          subscriptionStatus: 'Expired',
          activePlanName: 'Monthly',
          subscriptionEndDate: DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        ),
      ];

      // All filter
      final stateAll = MembersState(members: members, selectedFilter: MemberFilter.all);
      expect(stateAll.filteredMembers.length, 3);

      // Active filter
      final stateActive = MembersState(members: members, selectedFilter: MemberFilter.active);
      expect(stateActive.filteredMembers.length, 2);

      // Expiring soon filter
      final stateExpiringSoon = MembersState(members: members, selectedFilter: MemberFilter.expiringSoon);
      expect(stateExpiringSoon.filteredMembers.length, 1);
      expect(stateExpiringSoon.filteredMembers.first.fullName, 'Expiring Soon Member');

      // Expired filter
      final stateExpired = MembersState(members: members, selectedFilter: MemberFilter.expired);
      expect(stateExpired.filteredMembers.length, 1);
      expect(stateExpired.filteredMembers.first.fullName, 'Expired Member');
    });
  });
}
