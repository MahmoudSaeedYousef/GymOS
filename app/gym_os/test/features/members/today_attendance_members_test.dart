import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/core/theme/app_theme.dart';
import 'package:gym_os/features/members/models/member_model.dart';
import 'package:gym_os/features/members/models/members_summary_data.dart';
import 'package:gym_os/features/members/providers/members_provider.dart';
import 'package:gym_os/features/members/services/gym_api_service.dart';
import 'package:gym_os/features/members/ui/members_screen.dart';
import 'package:gym_os/features/members/ui/widgets/member_avatar.dart';
import 'package:gym_os/l10n/app_localizations.dart';

class _MockGymApiServiceForToday extends Fake implements GymApiService {
  final List<MemberModel> members;

  _MockGymApiServiceForToday(this.members);

  @override
  Future<PagedMembersResponse> getMembers({
    String? search,
    String? cursor,
    int pageSize = 20,
    String? filter,
    String? sortBy,
  }) async {
    return PagedMembersResponse(
      items: members,
      hasMore: false,
      nextCursor: null,
    );
  }

  @override
  Future<MembersSummaryData> getMembersSummary() async {
    return MembersSummaryData(
      totalCount: members.length,
      activeCount: members.where((m) => m.subscriptionStatus.toLowerCase() == 'active').length,
      expiredCount: members.where((m) => m.subscriptionStatus.toLowerCase() != 'active').length,
      expiringSoonCount: 0,
      plans: [],
      planCounts: {},
    );
  }
}

void main() {
  testWidgets('MembersScreen renders single-session guests with chip, subtext, and fallback avatar', (tester) async {
    final members = [
      MemberModel(
        id: 'regular-1',
        fullName: 'عضو منتظم',
        phoneNumber: '01011111111',
        subscriptionStatus: 'active',
        activePlanName: 'باقة شهرية',
        isGuest: false,
        isSingleSession: false,
        gender: 1,
      ),
      MemberModel(
        id: 'dropin-1',
        fullName: 'أحمد علي',
        phoneNumber: '01022222222',
        subscriptionStatus: 'expired',
        activePlanName: 'حصة منفردة',
        isGuest: true,
        isSingleSession: true,
        gender: 1,
      ),
    ];

    final fakeService = _MockGymApiServiceForToday(members);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gymApiServiceProvider.overrideWithValue(fakeService),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: MembersScreen(initialFilter: 'today'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify member names rendered
    expect(find.text('عضو منتظم'), findsOneWidget);
    expect(find.text('أحمد علي'), findsOneWidget);

    // Verify single session badge / chip
    expect(find.text('حصة منفردة'), findsOneWidget);

    // Verify single session subtext
    expect(find.text('حصة منفردة • اليوم'), findsOneWidget);

    // Verify MemberAvatars rendered for both
    final avatars = find.byType(MemberAvatar);
    expect(avatars, findsNWidgets(2));
  });
}
