import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/features/members/providers/members_provider.dart';

void main() {
  group('MemberSortOption tests', () {
    test('apiValue matches backend query param exactly', () {
      expect(MemberSortOption.newest.apiValue, 'newest');
      expect(MemberSortOption.expiringSoon.apiValue, 'expiringSoon');
      expect(MemberSortOption.endDateDesc.apiValue, 'endDateDesc');
      expect(MemberSortOption.name.apiValue, 'name');
      expect(MemberSortOption.plan.apiValue, 'plan');
      expect(MemberSortOption.lastCheckIn.apiValue, 'lastCheckIn');
    });

    test('fromString parses various representations safely', () {
      expect(MemberSortOption.fromString('newest'), MemberSortOption.newest);
      expect(MemberSortOption.fromString('expiringSoon'), MemberSortOption.expiringSoon);
      expect(MemberSortOption.fromString('EXPIRINGSOON'), MemberSortOption.expiringSoon);
      expect(MemberSortOption.fromString('endDateDesc'), MemberSortOption.endDateDesc);
      expect(MemberSortOption.fromString('name'), MemberSortOption.name);
      expect(MemberSortOption.fromString('plan'), MemberSortOption.plan);
      expect(MemberSortOption.fromString('lastCheckIn'), MemberSortOption.lastCheckIn);
      expect(MemberSortOption.fromString(null), MemberSortOption.newest);
      expect(MemberSortOption.fromString('unknown_sort'), MemberSortOption.newest);
    });

    test('each sort option has a valid icon', () {
      for (final option in MemberSortOption.values) {
        expect(option.icon, isNotNull);
      }
    });

    test('MembersState defaults to newest sort and copyWith updates it', () {
      const state = MembersState();
      expect(state.selectedSort, MemberSortOption.newest);

      final updated = state.copyWith(selectedSort: MemberSortOption.expiringSoon);
      expect(updated.selectedSort, MemberSortOption.expiringSoon);
      expect(updated.selectedFilter, MemberFilter.all);
    });
  });
}
