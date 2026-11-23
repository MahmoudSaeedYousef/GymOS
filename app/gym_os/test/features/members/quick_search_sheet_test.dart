import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/core/theme/app_theme.dart';
import 'package:gym_os/features/members/models/member_model.dart';
import 'package:gym_os/features/members/providers/members_provider.dart';
import 'package:gym_os/features/members/ui/widgets/member_avatar.dart';
import 'package:gym_os/features/members/ui/widgets/quick_search_sheet.dart';
import 'package:gym_os/l10n/app_localizations.dart';

void main() {
  testWidgets('QuickSearchSheet renders MemberAvatar with photo, male, female fallback', (tester) async {
    final members = [
      MemberModel(
        id: 'm-photo',
        fullName: 'Photo Member',
        phoneNumber: '0100000001',
        subscriptionStatus: 'active',
        photoUrl: 'https://example.com/photo.jpg',
        gender: 1,
      ),
      MemberModel(
        id: 'm-male',
        fullName: 'Male Member',
        phoneNumber: '0100000002',
        subscriptionStatus: 'active',
        photoUrl: null,
        gender: 1,
      ),
      MemberModel(
        id: 'm-female',
        fullName: 'Female Member',
        phoneNumber: '0100000003',
        subscriptionStatus: 'active',
        photoUrl: null,
        gender: 2,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          membersProvider.overrideWith(
            (ref) => _QuickSearchTestNotifier(members),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: QuickSearchSheet(
              title: 'تسجيل حضور سريع',
              onMemberSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final avatars = find.byType(MemberAvatar);
    expect(avatars, findsNWidgets(3));

    final maleAvatar = tester.widget<MemberAvatar>(avatars.at(1));
    expect(maleAvatar.gender, 1);
    expect(maleAvatar.photoUrl, isNull);

    final femaleAvatar = tester.widget<MemberAvatar>(avatars.at(2));
    expect(femaleAvatar.gender, 2);
    expect(femaleAvatar.photoUrl, isNull);
  });
}

class _QuickSearchTestNotifier extends StateNotifier<MembersState> implements MembersNotifier {
  _QuickSearchTestNotifier(List<MemberModel> members)
      : super(MembersState(members: members, allMembers: members));

  @override
  void resetFilters() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
