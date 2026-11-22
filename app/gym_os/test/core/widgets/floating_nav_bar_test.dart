import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/core/theme/app_theme.dart';
import 'package:gym_os/core/widgets/floating_nav_bar.dart';
import 'package:gym_os/features/home/providers/dashboard_provider.dart';
import 'package:gym_os/features/home/ui/main_layout.dart';
import 'package:gym_os/features/members/models/member_model.dart';
import 'package:gym_os/features/members/services/gym_api_service.dart';
import 'package:gym_os/l10n/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:dio/dio.dart';

class _FakeGymApiService extends GymApiService {
  _FakeGymApiService() : super(Dio());

  @override
  Future<PagedMembersResponse> getMembers({
    String? search,
    String? cursor,
    int pageSize = 20,
    String? filter,
    String? sortBy,
  }) async {
    return PagedMembersResponse(items: [], nextCursor: null, hasMore: false);
  }
}

void main() {
  group('FloatingNavBar Unit & Widget Tests', () {
    const items = [
      FloatingNavItem(
        icon: LucideIcons.layoutDashboard,
        activeIcon: LucideIcons.layoutDashboard,
        label: 'Dashboard',
      ),
      FloatingNavItem(
        icon: LucideIcons.users,
        activeIcon: LucideIcons.users,
        label: 'Members',
      ),
      FloatingNavItem(
        icon: LucideIcons.slidersHorizontal,
        activeIcon: LucideIcons.slidersHorizontal,
        label: 'Settings',
      ),
    ];

    Widget createTestWidget({
      required int currentIndex,
      required ValueChanged<int> onTap,
      ThemeData? theme,
      Locale locale = const Locale('en'),
      TextDirection textDirection = TextDirection.ltr,
      Size size = const Size(390, 844),
      double textScale = 1.0,
    }) {
      return MaterialApp(
        theme: theme ?? AppTheme.darkTheme(),
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Directionality(
          textDirection: textDirection,
          child: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(textScale),
            ),
            child: Scaffold(
              extendBody: true,
              body: const Center(child: Text('Body')),
              bottomNavigationBar: FloatingNavBar(
                currentIndex: currentIndex,
                onTap: onTap,
                items: items,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
      'Renders items correctly: active tab shows icon and label, inactive tabs show icons',
      (tester) async {
        int selected = 0;

        await tester.pumpWidget(
          createTestWidget(currentIndex: selected, onTap: (i) => selected = i),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Active tab: Dashboard
        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.byIcon(LucideIcons.layoutDashboard), findsOneWidget);

        // Inactive tabs: icons visible
        expect(find.byIcon(LucideIcons.users), findsOneWidget);
        expect(find.byIcon(LucideIcons.slidersHorizontal), findsOneWidget);

        // Inactive labels not visible (or sized to 0)
        expect(find.text('Members'), findsNothing);
        expect(find.text('Settings'), findsNothing);

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Tapping inactive tab triggers onTap callback', (tester) async {
      int selected = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return createTestWidget(
              currentIndex: selected,
              onTap: (i) => setState(() => selected = i),
            );
          },
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Members (tab 1)
      await tester.tap(find.byIcon(LucideIcons.users));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Now Members is active
      expect(selected, 1);
      expect(find.text('Members'), findsOneWidget);
      expect(find.byIcon(LucideIcons.users), findsOneWidget);

      // Dashboard is now inactive
      expect(find.byIcon(LucideIcons.layoutDashboard), findsOneWidget);
      expect(find.text('Dashboard'), findsNothing);
    });

    testWidgets(
      'Dynamically derives active pill gradient and glow shadow from Theme colorScheme',
      (tester) async {
        const customPrimary = Color(0xFF9333EA); // Custom purple
        const customTertiary = Color(0xFFEC4899);
        final customTheme = ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: customPrimary,
            primary: customPrimary,
            tertiary: customTertiary,
            brightness: Brightness.dark,
          ),
        );

        await tester.pumpWidget(
          createTestWidget(currentIndex: 0, onTap: (_) {}, theme: customTheme),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Find AnimatedContainer of active item
        final animatedContainers = tester.widgetList<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );

        // Find the one that has a LinearGradient
        final activeContainer = animatedContainers.firstWhere(
          (c) => (c.decoration as BoxDecoration?)?.gradient is LinearGradient,
        );

        final decoration = activeContainer.decoration as BoxDecoration;
        expect(decoration.gradient, isNotNull);
        final gradient = decoration.gradient as LinearGradient;
        expect(gradient.colors.first, customPrimary);
        expect(decoration.borderRadius, BorderRadius.circular(24));
        expect(decoration.boxShadow, isNotNull);
        expect(
          decoration.boxShadow!.first.color,
          customPrimary.withValues(alpha: 0.32),
        );
      },
    );

    testWidgets(
      'Works in Arabic (RTL) on narrow screen (320dp) with zero overflow',
      (tester) async {
        const arabicItems = [
          FloatingNavItem(
            icon: LucideIcons.layoutDashboard,
            activeIcon: LucideIcons.layoutDashboard,
            label: 'الرئيسية',
          ),
          FloatingNavItem(
            icon: LucideIcons.users,
            activeIcon: LucideIcons.users,
            label: 'المشتركين',
          ),
          FloatingNavItem(
            icon: LucideIcons.slidersHorizontal,
            activeIcon: LucideIcons.slidersHorizontal,
            label: 'الإعدادات',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme(),
            locale: const Locale('ar'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: MediaQuery(
                data: const MediaQueryData(
                  size: Size(320, 568),
                  textScaler: TextScaler.linear(1.3),
                ),
                child: Scaffold(
                  extendBody: true,
                  body: const Center(child: Text('Body')),
                  bottomNavigationBar: FloatingNavBar(
                    currentIndex: 1, // 'المشتركين' active
                    onTap: (_) {},
                    items: arabicItems,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('المشتركين'), findsOneWidget);
        expect(find.byIcon(LucideIcons.users), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'MainLayout integrates FloatingNavBar and switches screens smoothly',
      (tester) async {
        const fakeStats = DashboardStatsModel(
          activeMembersCount: 20,
          expiredSubscriptionsCount: 2,
          todayCheckInsCount: 8,
          monthlyRevenue: 10000,
          currentInside: 5,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              dashboardStatsProvider.overrideWith(
                (ref) => Stream.value(fakeStats),
              ),
              gymApiServiceProvider.overrideWithValue(_FakeGymApiService()),
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
              home: const MainLayout(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // FloatingNavBar should be present
        expect(find.byType(FloatingNavBar), findsOneWidget);

        // Initially on Operations (landing tab)
        expect(find.text('Operations'), findsOneWidget);

        // Tap Overview in FloatingNavBar
        await tester.tap(find.byIcon(Icons.insights_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Insights'), findsWidgets);

        // Tap Members in FloatingNavBar
        await tester.tap(find.byIcon(LucideIcons.users));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Members is now active in bar
        expect(find.text('Members'), findsWidgets);

        // Tap Settings in FloatingNavBar
        await tester.tap(find.byIcon(LucideIcons.slidersHorizontal));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Settings is now active in bar
        expect(find.text('Settings'), findsWidgets);

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'MainLayout supports horizontal swipe navigation in LTR (English)',
      (tester) async {
        const fakeStats = DashboardStatsModel(
          activeMembersCount: 20,
          expiredSubscriptionsCount: 2,
          todayCheckInsCount: 8,
          monthlyRevenue: 10000,
          currentInside: 5,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              dashboardStatsProvider.overrideWith(
                (ref) => Stream.value(fakeStats),
              ),
              gymApiServiceProvider.overrideWithValue(_FakeGymApiService()),
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
              home: const MainLayout(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Landing tab is Operations (index 1)
        expect(find.text('Operations'), findsOneWidget);

        // In LTR, swiping left-to-right (positive offset) moves back to page 0 (Insights)
        await tester.drag(find.byType(PageView), const Offset(500, 0));
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        // Tab 0 (Insights) is now active
        expect(find.text('Insights'), findsWidgets);

        // Swiping right-to-left (negative offset) advances forward to page 1 (Operations)
        await tester.drag(find.byType(PageView), const Offset(-500, 0));
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        expect(find.text('Operations'), findsWidgets);

        // Swipe again to page 2 (Members)
        await tester.drag(find.byType(PageView), const Offset(-500, 0));
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        // Tab 2 (Members) is now active
        expect(find.text('Members'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'MainLayout supports horizontal swipe navigation in RTL (Arabic)',
      (tester) async {
        const fakeStats = DashboardStatsModel(
          activeMembersCount: 20,
          expiredSubscriptionsCount: 2,
          todayCheckInsCount: 8,
          monthlyRevenue: 10000,
          currentInside: 5,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              dashboardStatsProvider.overrideWith(
                (ref) => Stream.value(fakeStats),
              ),
              gymApiServiceProvider.overrideWithValue(_FakeGymApiService()),
            ],
            child: MaterialApp(
              theme: AppTheme.darkTheme(),
              locale: const Locale('ar'),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: const MainLayout(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Initial active tab in Arabic is العمليات (index 1)
        expect(find.text('العمليات'), findsOneWidget);

        // In RTL, dragging right-to-left (negative offset) moves back to page 0 (المتابعة)
        await tester.drag(find.byType(PageView), const Offset(-500, 0));
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        expect(find.text('المتابعة'), findsWidgets);

        // Drag left-to-right (positive offset) returns to page 1 (العمليات)
        await tester.drag(find.byType(PageView), const Offset(500, 0));
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        expect(find.text('العمليات'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
