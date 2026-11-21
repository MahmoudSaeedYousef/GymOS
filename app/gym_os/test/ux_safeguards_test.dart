import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/core/database/app_database.dart';
import 'package:gym_os/core/database/database_provider.dart';
import 'package:gym_os/core/theme/app_theme.dart';
import 'package:gym_os/features/home/ui/main_layout.dart';
import 'package:gym_os/features/members/providers/members_provider.dart';
import 'package:gym_os/features/settings/ui/settings_screen.dart';
import 'package:gym_os/l10n/app_localizations.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _FakeMembersNotifier extends StateNotifier<MembersState>
    implements MembersNotifier {
  _FakeMembersNotifier() : super(const MembersState());

  @override
  void resetFilters() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('UX Safeguards Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    Widget createSettingsTestWidget({
      Locale locale = const Locale('en'),
    }) {
      return ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SettingsScreen(),
        ),
      );
    }

    Widget createMainLayoutTestWidget({
      Locale locale = const Locale('en'),
    }) {
      return ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          membersProvider.overrideWith((ref) => _FakeMembersNotifier()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const MainLayout(
            children: [
              Scaffold(body: Center(child: Text('Dashboard Mock Screen'))),
              Scaffold(body: Center(child: Text('Members Mock Screen'))),
              Scaffold(body: Center(child: Text('Settings Mock Screen'))),
            ],
          ),
        ),
      );
    }

    testWidgets('Sign-out shows confirmation dialog without warning when 0 unsynced records', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createSettingsTestWidget());
      await tester.pumpAndSettle();

      final signOutBtn = find.text('Sign Out');
      await tester.ensureVisible(signOutBtn);
      await tester.tap(signOutBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Are you sure you want to sign out?'), findsOneWidget);
      expect(find.textContaining('unsynced local records'), findsNothing);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Sign-out shows confirmation dialog with unsynced warning in Arabic', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await db.into(db.syncOutbox).insert(
        SyncOutboxCompanion.insert(
          operationId: 'op-1',
          entityType: 'attendance_checkin',
          entityId: 'rec-1',
          payloadJson: '{}',
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(createSettingsTestWidget(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      final signOutBtn = find.text('تسجيل الخروج');
      await tester.ensureVisible(signOutBtn);
      await tester.tap(signOutBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'), findsOneWidget);
      expect(find.textContaining('عمليات محلية لم تتم مزامنتها'), findsOneWidget);
    });

    testWidgets('Double-back to exit on Dashboard tab navigates / pops system on second press', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int popCalls = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'SystemNavigator.pop') {
            popCalls++;
          }
          return null;
        },
      );

      await tester.pumpWidget(createMainLayoutTestWidget());
      await tester.pumpAndSettle();

      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));

      // First back press shows SnackBar
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Press back again to exit'), findsOneWidget);
      expect(popCalls, 0);

      // Second back press within 2 seconds calls SystemNavigator.pop()
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      expect(popCalls, 1);
    });

    testWidgets('Back navigation from other tabs returns to Dashboard first', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createMainLayoutTestWidget());
      await tester.pumpAndSettle();

      // Switch to Members tab
      await tester.tap(find.byIcon(LucideIcons.users));
      await tester.pumpAndSettle();
      expect(find.text('Members Mock Screen'), findsOneWidget);

      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));

      // Press back -> navigates to Dashboard
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Dashboard Mock Screen'), findsOneWidget);

      // First press back now that we are on Dashboard should show SnackBar
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Press back again to exit'), findsOneWidget);
    });
  });
}
