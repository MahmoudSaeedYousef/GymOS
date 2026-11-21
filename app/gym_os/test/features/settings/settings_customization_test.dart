import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/core/providers/app_settings_provider.dart';
import 'package:gym_os/core/theme/app_theme.dart';
import 'package:gym_os/features/settings/ui/settings_screen.dart';
import 'package:gym_os/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Settings Customization Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    Widget createTestWidget({Locale locale = const Locale('ar')}) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final font = ref.watch(appFontProvider);
            final preset = ref.watch(appColorPresetProvider);
            final themeMode = ref.watch(themeModeProvider);

            return MaterialApp(
              theme: AppTheme.lightTheme(
                tenantPrimaryColor: preset.seedColor,
                fontFamily: font.fontFamily,
              ),
              darkTheme: AppTheme.darkTheme(
                tenantPrimaryColor: preset.seedColor,
                fontFamily: font.fontFamily,
              ),
              themeMode: themeMode,
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const SettingsScreen(),
            );
          },
        ),
      );
    }

    testWidgets('renders font selector and color preset selector in Arabic',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.text('خط التطبيق'), findsOneWidget);
      expect(find.text('لون التطبيق'), findsOneWidget);
      expect(find.text('الافتراضي'), findsOneWidget);

      // 5 color presets should be rendered
      expect(find.byType(InkWell), findsWidgets);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('renders font selector and color preset selector in English',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('App Font'), findsOneWidget);
      expect(find.text('Accent Color'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);
    });

    testWidgets('switching font updates state and persists in SharedPreferences',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open the font dropdown
      await tester.tap(find.text('الافتراضي'));
      await tester.pumpAndSettle();

      // Select Azer font
      await tester.tap(find.text('آزر').last);
      await tester.pumpAndSettle();

      expect(prefs.getString('gym_os_selected_font'), 'azer');
      expect(find.text('آزر'), findsOneWidget);

      // Open dropdown again and select Al-Yamama
      await tester.tap(find.text('آزر'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('اليمامة').last);
      await tester.pumpAndSettle();

      expect(prefs.getString('gym_os_selected_font'), 'alyamama');
      expect(find.text('اليمامة'), findsOneWidget);
    });

    testWidgets(
        'tapping color swatch updates preset and persists in SharedPreferences',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially default energyOrange
      expect(prefs.getString('gym_os_selected_color_preset'), isNull);

      // Find the swatches (under the accentColor row)
      final swatches = find.descendant(
        of: find.byType(Row),
        matching: find.byType(InkWell),
      );
      // Tap third swatch (emerald)
      await tester.tap(swatches.at(2));
      await tester.pumpAndSettle();

      expect(prefs.getString('gym_os_selected_color_preset'), 'emerald');

      // Tap first swatch (royalBlue)
      await tester.tap(swatches.at(0));
      await tester.pumpAndSettle();

      expect(prefs.getString('gym_os_selected_color_preset'), 'royalBlue');
    });

    testWidgets('AppTheme.lightTheme and darkTheme apply custom fontFamily correctly',
        (tester) async {
      final defaultTheme = AppTheme.lightTheme();
      // When fontFamily is null, defaultTheme inherits platform default (or null)
      expect(defaultTheme.textTheme.bodyMedium?.fontFamily, anyOf(isNull, 'Roboto'));

      final azerTheme = AppTheme.lightTheme(fontFamily: 'Azer');
      expect(azerTheme.textTheme.bodyMedium?.fontFamily, 'Azer');
      expect(azerTheme.primaryTextTheme.bodyMedium?.fontFamily, 'Azer');
      expect(azerTheme.appBarTheme.titleTextStyle?.fontFamily, 'Azer');

      final darkAlyamama = AppTheme.darkTheme(fontFamily: 'Alyamama');
      expect(darkAlyamama.textTheme.bodyMedium?.fontFamily, 'Alyamama');
      expect(darkAlyamama.primaryTextTheme.bodyMedium?.fontFamily, 'Alyamama');
      expect(darkAlyamama.appBarTheme.titleTextStyle?.fontFamily, 'Alyamama');
    });
  });
}
