import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/core/theme/app_theme.dart';
import 'package:gym_os/features/home/providers/dashboard_provider.dart';
import 'package:gym_os/features/home/ui/dashboard_screen.dart';
import 'package:gym_os/features/members/models/member_model.dart';
import 'package:gym_os/features/members/services/gym_api_service.dart';
import 'package:gym_os/l10n/app_localizations.dart';

class _FakeGymApiService extends GymApiService {
  final List<MemberModel> members;
  _FakeGymApiService(this.members) : super(Dio());

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
      nextCursor: null,
      hasMore: false,
    );
  }
}

void main() {
  final sampleStats = const DashboardStatsModel(
    activeMembersCount: 25,
    expiredSubscriptionsCount: 4,
    todayCheckInsCount: 12,
    monthlyRevenue: 9500.0,
    currentInside: 6,
  );

  final sampleMembers = [
    MemberModel(
      id: 'm1',
      fullName: 'Ahmed Ali',
      phoneNumber: '01012345678',
      subscriptionStatus: 'Active',
    ),
    MemberModel(
      id: 'm2',
      fullName: 'Mohamed Tarek',
      phoneNumber: '01198765432',
      subscriptionStatus: 'Expired',
    ),
  ];

  Widget createWidgetUnderTest({
    Locale locale = const Locale('en'),
    double textScale = 1.0,
  }) {
    return ProviderScope(
      overrides: [
        dashboardStatsProvider.overrideWith(
          (ref) => Stream.value(sampleStats),
        ),
        gymApiServiceProvider.overrideWithValue(
          _FakeGymApiService(sampleMembers),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme(),
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: const DashboardScreen(),
      ),
    );
  }

  testWidgets('Segmented switch defaults to Operations and shows primary check-in', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Default mode should display "Operations" & "Overview" segmented options
    expect(find.text('Operations'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);

    // Header displays app logo with semantic label
    expect(find.bySemanticsLabel('Gymmy logo'), findsOneWidget);

    // In Operations view, primary check-in and quick action buttons exist
    expect(find.text('Quick Check-in'), findsOneWidget);
    expect(find.text('New Member'), findsOneWidget);
    expect(find.text('Renew Plan'), findsOneWidget);
    expect(find.text('Drop-in session'), findsOneWidget);

    // Latest members section header exists
    expect(find.text('Latest Members'), findsOneWidget);
  });

  testWidgets('Tapping Overview switches to read-only Overview view hiding mutating actions', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap on Overview segment
    await tester.tap(find.text('Overview'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Mutating actions should be hidden
    expect(find.text('New Member'), findsNothing);
    expect(find.text('Renew Plan'), findsNothing);
    expect(find.text('Drop-in session'), findsNothing);

    // Overview components: Revenue Summary and Compact KPI cards
    expect(find.text('Revenue Summary'), findsOneWidget);
    expect(find.text('Active Subscriptions'), findsOneWidget);
    expect(find.text('Expired Subscriptions'), findsOneWidget);
    expect(find.text("Today's Revenue"), findsOneWidget);
  });

  testWidgets('Overview 4-card grid order with todayRevenue and drop-in portion sub-badge', (tester) async {
    final statsWithDropIn = const DashboardStatsModel(
      activeMembersCount: 25,
      expiredSubscriptionsCount: 4,
      todayCheckInsCount: 12,
      monthlyRevenue: 9500.0,
      currentInside: 6,
      todayRevenue: 1500.0,
      monthlyDropInRevenue: 450.0,
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        dashboardStatsProvider.overrideWith((ref) => Stream.value(statsWithDropIn)),
        gymApiServiceProvider.overrideWithValue(_FakeGymApiService(sampleMembers)),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme(),
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DashboardScreen(),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Overview
    await tester.tap(find.text('Overview'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Monthly Revenue must only exist once (in the Revenue Summary card above), NOT in the grid
    expect(find.text('Monthly Revenue'), findsOneWidget);

    // Drop-in portion sub-badge is visible on the Monthly Revenue card
    expect(find.text('Includes drop-ins: 450 EGP'), findsOneWidget);

    // 4 KPI cards exist in the 2x2 grid
    final activeFinder = find.text('Active Subscriptions');
    final todayCheckInsFinder = find.text("Today's Check-ins");
    final expiredFinder = find.text('Expired Subscriptions');
    final todayRevenueFinder = find.text("Today's Revenue");

    expect(activeFinder, findsOneWidget);
    expect(todayCheckInsFinder, findsOneWidget);
    expect(expiredFinder, findsOneWidget);
    expect(todayRevenueFinder, findsOneWidget);

    // In LTR, Row 1 start (Active) has lower X coordinate than Row 1 end (Today's check-ins)
    final activeCenter = tester.getCenter(activeFinder);
    final todayCheckInsCenter = tester.getCenter(todayCheckInsFinder);
    final expiredCenter = tester.getCenter(expiredFinder);
    final todayRevenueCenter = tester.getCenter(todayRevenueFinder);

    expect(activeCenter.dx, lessThan(todayCheckInsCenter.dx));
    expect(activeCenter.dy, equals(todayCheckInsCenter.dy)); // Same row (Row 1)

    // Row 2: Expired Subscriptions (start) has lower X than Today's Revenue (end)
    expect(expiredCenter.dx, lessThan(todayRevenueCenter.dx));
    expect(expiredCenter.dy, equals(todayRevenueCenter.dy)); // Same row (Row 2)
    expect(expiredCenter.dy, greaterThan(activeCenter.dy)); // Below Row 1
  });

  testWidgets('Inline search displays matching members with Check-in button', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Enter search text into the inline search field
    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'Ahmed');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Should find matching member and a Check-in button for that member
    expect(find.text('Ahmed Ali'), findsOneWidget);
    expect(find.text('01012345678'), findsOneWidget);
    expect(find.text('Check In'), findsOneWidget);

    // Non-matching member should not be shown
    expect(find.text('Mohamed Tarek'), findsNothing);
  });

  testWidgets('Search row displays cleanly at text scale 1.3 without overflow', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(textScale: 1.3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final searchField = find.byType(TextField);
    await tester.enterText(searchField, 'Ahmed');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verifying search result rendered without layout overflow exception
    expect(find.text('Ahmed Ali'), findsOneWidget);
    expect(find.text('01012345678'), findsOneWidget);
    expect(find.text('Check In'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tapping Drop-in session button opens DropInSessionBottomSheet with validation and fields', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap "Drop-in session" button
    await tester.tap(find.text('Drop-in session'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Sheet header and elements should be visible
    expect(find.text('Record Drop-in Session'), findsOneWidget);
    expect(find.text('Record & Check In'), findsOneWidget);

    // Payment method options visible
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('InstaPay'), findsOneWidget);
    expect(find.text('Vodafone Cash'), findsOneWidget);
    expect(find.text('Visa / Card'), findsOneWidget);

    // Amount input is prefilled with 50
    final amountInput = find.byType(TextFormField).first;
    expect(amountInput, findsOneWidget);
    expect(find.descendant(of: amountInput, matching: find.text('50')), findsWidgets);

    // Optional guest fields
    expect(find.text('Guest name (optional)'), findsWidgets);
    expect(find.text('Guest phone (optional)'), findsWidgets);
    expect(find.text('Notes (optional)'), findsWidgets);

    // Test clearing amount and validating error
    await tester.enterText(amountInput, '');
    await tester.tap(find.text('Record & Check In'));
    await tester.pump();

    expect(find.text('Please enter a valid amount'), findsOneWidget);
  });

  testWidgets('Verifies hidden sections when data is absent (no drawer, no unprovided sections)', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Drawer status does not exist in backend/app, so it must not be rendered
    expect(find.text('Drawer'), findsNothing);
    expect(find.text('Drawer closed'), findsNothing);
    expect(find.text('Sync Status'), findsNothing);
  });
}
