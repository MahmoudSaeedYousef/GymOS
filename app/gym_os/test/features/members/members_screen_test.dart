import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/core/theme/app_theme.dart';
import 'package:gym_os/features/attendance/services/attendance_api_service.dart';
import 'package:gym_os/features/members/models/member_model.dart';
import 'package:gym_os/features/members/providers/members_provider.dart';
import 'package:gym_os/features/members/services/gym_api_service.dart';
import 'package:gym_os/features/members/ui/members_screen.dart';
import 'package:gym_os/l10n/app_localizations.dart';
import 'package:dio/dio.dart';

class _FakeGymApiService extends GymApiService {
  final List<MemberModel> members;
  _FakeGymApiService({required this.members}) : super(Dio());

  @override
  Future<PagedMembersResponse> getMembers({
    String? search,
    String? cursor,
    int pageSize = 20,
    String? filter,
    String? sortBy,
  }) async {
    var result = members;
    if (filter == 'active') {
      result = result.where((m) => m.subscriptionStatus.toLowerCase() == 'active').toList();
    } else if (filter == 'expiring_soon') {
      result = result.where((m) => m.isExpiringSoon).toList();
    } else if (filter == 'expired') {
      result = result.where((m) => m.subscriptionStatus.toLowerCase() != 'active').toList();
    }
    return PagedMembersResponse(
      items: result,
      nextCursor: null,
      hasMore: false,
    );
  }

  @override
  Future<MembersSummaryData> getMembersSummary() async {
    final nonGuest = members.where((m) => !m.isGuest).toList();
    final active = nonGuest.where((m) => m.subscriptionStatus.toLowerCase() == 'active').length;
    final expired = nonGuest.where((m) => m.subscriptionStatus.toLowerCase() != 'active').length;
    final expiringSoon = nonGuest.where((m) => m.isExpiringSoon).length;
    final planMap = <String, int>{};
    for (final m in nonGuest) {
      final rawPlan = m.activePlanName?.trim();
      final planKey = (rawPlan != null && rawPlan.isNotEmpty) ? rawPlan : '';
      planMap[planKey] = (planMap[planKey] ?? 0) + 1;
    }
    final planItems = planMap.entries
        .map((e) => MembersSummaryPlanItem(planName: e.key, count: e.value))
        .toList();
    return MembersSummaryData(
      totalCount: nonGuest.length,
      activeCount: active,
      expiredCount: expired,
      expiringSoonCount: expiringSoon,
      plans: planItems,
      planCounts: planMap,
    );
  }
}

class _FakeAttendanceApiService extends AttendanceApiService {
  _FakeAttendanceApiService() : super(Dio());

  @override
  Future<String> checkIn(
    String memberId, {
    String? attendanceId,
    String? notes,
  }) async {
    return 'Check-in successful';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final activeMember = MemberModel(
    id: 'm1',
    fullName: 'Ahmed Ali',
    phoneNumber: '01012345678',
    subscriptionStatus: 'active',
    activePlanName: 'Monthly Gold',
    subscriptionEndDate: DateTime.now().add(const Duration(days: 30)).toIso8601String(),
  );

  final expiringSoonMember = MemberModel(
    id: 'm2',
    fullName: 'Sara Mohamed',
    phoneNumber: '01087654321',
    subscriptionStatus: 'active',
    activePlanName: 'Yearly VIP',
    subscriptionEndDate: DateTime.now().add(const Duration(days: 2)).toIso8601String(),
  );

  final expiredMember = MemberModel(
    id: 'm3',
    fullName: 'Khaled Hassan',
    phoneNumber: '01199887766',
    subscriptionStatus: 'expired',
    activePlanName: 'Basic Plan',
    subscriptionEndDate: DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
  );

  final withoutPlanNullDateMember = MemberModel(
    id: 'm4',
    fullName: 'Tarek Mahmoud',
    phoneNumber: '01234567890',
    subscriptionStatus: 'active',
    activePlanName: null,
    subscriptionEndDate: null,
  );

  final withoutPlanFutureDateMember = MemberModel(
    id: 'm5',
    fullName: 'Youssef Nader',
    phoneNumber: '01511223344',
    subscriptionStatus: 'active',
    activePlanName: null,
    subscriptionEndDate: DateTime.now().add(const Duration(days: 20)).toIso8601String(),
  );

  Widget createTestWidget({
    Locale locale = const Locale('ar'),
    List<MemberModel>? testMembers,
  }) {
    final membersList = testMembers ?? [
      activeMember,
      expiringSoonMember,
      expiredMember,
      withoutPlanNullDateMember,
      withoutPlanFutureDateMember,
    ];

    return ProviderScope(
      overrides: [
        gymApiServiceProvider.overrideWithValue(_FakeGymApiService(members: membersList)),
        attendanceApiProvider.overrideWithValue(_FakeAttendanceApiService()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const MembersScreen(),
      ),
    );
  }

  group('MembersScreen Redesign Widget Tests', () {
    testWidgets('renders top app bar pill button "+ مشترك جديد" and zero FAB', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Top app bar pill button "+ مشترك جديد"
      expect(find.text('مشترك جديد'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);

      // Verify no FloatingActionButton exists on screen
      expect(find.byType(FloatingActionButton), findsNothing);

      // Verify search field exists with hint
      expect(find.text('ابحث بالاسم أو رقم الموبايل...'), findsOneWidget);
    });

    testWidgets('renders filter strip with unified cohesive styling', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.text('الكل'), findsOneWidget);
      expect(find.text('سارية'), findsOneWidget);
      expect(find.text('ينتهي قريباً'), findsWidgets);
      expect(find.text('منتهية'), findsOneWidget);
      expect(find.text('حضور اليوم'), findsOneWidget);

      // Tap 'سارية'
      await tester.tap(find.text('سارية'));
      await tester.pumpAndSettle();

      // Should only show active/expiring soon members
      expect(find.text('Ahmed Ali'), findsOneWidget);
      expect(find.text('Khaled Hassan'), findsNothing);
    });

    testWidgets('renders member cards with squircle badge, status badges, and quick action buttons', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Leading squircle badges with initials
      expect(find.text('A'), findsOneWidget);
      expect(find.text('S'), findsOneWidget);
      expect(find.text('K'), findsOneWidget);

      // Quiet status badges: Normal active has no badge ("نشط" is not displayed)
      expect(find.text('نشط'), findsNothing);
      // Exceptions only (expiring soon concise badge or expired)
      expect(find.text('باقي يومين'), findsWidgets);
      expect(find.text('منتهي منذ 5 أيام'), findsWidgets);
      expect(find.text('بدون باقة'), findsAtLeastNWidgets(2));

      // Quick action check-in fingerprint button on active member
      expect(find.byIcon(Icons.fingerprint_rounded), findsOneWidget);

      // Quick action renew button on expiringSoon, expired, and withoutPlan members
      expect(find.byIcon(Icons.autorenew_rounded), findsNWidgets(4));
    });

    testWidgets('works in English LTR without overflow and with correct labels', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('New Member'), findsOneWidget);
      expect(find.text('Search by name or phone...'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      // 'Active' is present in the filter chip and status badge
      expect(find.text('Active'), findsAtLeastNWidgets(1));
      expect(find.text('Expiring Soon'), findsAtLeastNWidgets(1));
      // 'Expired' is present in filter chip and status badge
      expect(find.text('Expired'), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('triggering quick check-in resets filter to All and clears search', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Switch to "سارية" filter
      await tester.tap(find.text('سارية'));
      await tester.pumpAndSettle();

      // Trigger quick check-in on Ahmed Ali
      await tester.tap(find.byIcon(Icons.fingerprint_rounded));
      await tester.pumpAndSettle();

      // After check-in animation / dismissal, filter should be reset to 'الكل'
      // and all members (including expired Khaled Hassan) should be visible again
      expect(find.text('Khaled Hassan'), findsOneWidget);
      expect(find.text('Ahmed Ali'), findsOneWidget);
    });

    testWidgets('renders summary card with total count and plan breakdown pills', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.text('إجمالي المشتركين'), findsOneWidget);
      expect(find.text('Monthly Gold'), findsWidgets);
      expect(find.text('Yearly VIP'), findsWidgets);
      expect(find.text('Basic Plan'), findsWidgets);
      expect(find.text('بدون باقة'), findsWidgets);
      expect(find.text('نشط: 4'), findsOneWidget);
      expect(find.text('ينتهي قريباً: 1'), findsOneWidget);
      expect(find.text('منتهي: 1'), findsOneWidget);
    });

    testWidgets('filtering by expiring soon shows only members expiring within 5 days', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Tap 'ينتهي قريباً' filter chip (first widget with this text)
      await tester.tap(find.text('ينتهي قريباً').first);
      await tester.pumpAndSettle();

      // Sara Mohamed expires in 2 days (expiring soon)
      expect(find.text('Sara Mohamed'), findsOneWidget);
      // Ahmed Ali expires in 30 days (not expiring soon)
      expect(find.text('Ahmed Ali'), findsNothing);
      // Khaled Hassan is expired
      expect(find.text('Khaled Hassan'), findsNothing);
    });
  });
}
