import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/core/network/app_exception.dart';
import 'package:gym_os/core/theme/app_theme.dart';
import 'package:gym_os/features/auth/services/auth_service.dart';
import 'package:gym_os/features/auth/ui/login_screen.dart';
import 'package:gym_os/l10n/app_localizations.dart';

class MockRateLimitAuthService extends AuthService {
  final int retryAfterSeconds;
  MockRateLimitAuthService({this.retryAfterSeconds = 10}) : super(Dio());

  @override
  Future<String> login(String phone, String password) async {
    throw RateLimitException(
      retryAfterSeconds: retryAfterSeconds,
      message: 'Rate limit exceeded',
    );
  }
}

Widget createLoginScreen({
  Locale locale = const Locale('en'),
  double textScale = 1.0,
  bool disableAnimations = false,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
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
          disableAnimations: disableAnimations,
        ),
        child: child!,
      ),
      home: const LoginScreen(),
    ),
  );
}

void main() {
  group('LoginScreen Tests', () {
    testWidgets('title shows Gymmy in English', (tester) async {
      await tester.pumpWidget(createLoginScreen(locale: const Locale('en')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('Gymmy'), findsOneWidget);
      expect(find.text('Sign in to manage your gym'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is Image && w.semanticLabel == 'Gymmy logo',
        ),
        findsOneWidget,
      );
    });

    testWidgets('title shows Gymmy in Arabic', (tester) async {
      await tester.pumpWidget(createLoginScreen(locale: const Locale('ar')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('Gymmy'), findsOneWidget);
      expect(find.text('سجل دخول لإدارة صالتك الرياضية'), findsOneWidget);
      expect(find.text('رقم الموبايل'), findsOneWidget);
      expect(find.text('كلمة المرور'), findsOneWidget);
      expect(find.text('تسجيل الدخول'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is Image && w.semanticLabel == 'شعار جيمي',
        ),
        findsOneWidget,
      );
    });

    testWidgets('empty password validation shows error text below field', (tester) async {
      await tester.pumpWidget(createLoginScreen(locale: const Locale('en')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      // Enter phone number so the empty-phone auto-fill block does not run
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      await tester.enterText(textFields.first, '01012345678');
      await tester.pump();

      // Tap Sign In with empty password
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('reduced-motion path renders final state immediately without animation exceptions', (tester) async {
      await tester.pumpWidget(createLoginScreen(
        locale: const Locale('en'),
        disableAnimations: true,
      ));
      await tester.pump();

      // In reduced motion, elements are immediately visible on turn 1
      expect(find.text('Gymmy'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at text scale 1.3 without overflow', (tester) async {
      await tester.pumpWidget(createLoginScreen(
        locale: const Locale('ar'),
        textScale: 1.3,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('Gymmy'), findsOneWidget);
      expect(find.text('تسجيل الدخول'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('rate limit response displays localized cooldown and countdown', (tester) async {
      await tester.pumpWidget(createLoginScreen(
        locale: const Locale('en'),
        disableAnimations: true,
        overrides: [
          authServiceProvider.overrideWithValue(
            MockRateLimitAuthService(retryAfterSeconds: 5),
          ),
        ],
      ));
      await tester.pump();

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      await tester.enterText(textFields.first, '01012345678');
      await tester.enterText(textFields.last, 'Password123!');
      await tester.pump();

      // Tap Sign In -> triggers 429 RateLimitException
      await tester.tap(find.text('Sign In'));
      await tester.pump(); // Start async call
      await tester.pump(); // Handle error & setState

      // Expect cooldown message and disabled button with countdown
      expect(find.text('Too many login attempts. Please wait 5 seconds before trying again.'), findsWidgets);
      expect(find.text('Please wait 5s'), findsOneWidget);

      // Advance by 1 second
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Please wait 4s'), findsOneWidget);

      // Advance remaining seconds
      await tester.pump(const Duration(seconds: 4));
      // Cooldown finished -> returns to Sign In
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('rate limit response displays localized cooldown in Arabic', (tester) async {
      await tester.pumpWidget(createLoginScreen(
        locale: const Locale('ar'),
        disableAnimations: true,
        overrides: [
          authServiceProvider.overrideWithValue(
            MockRateLimitAuthService(retryAfterSeconds: 3),
          ),
        ],
      ));
      await tester.pump();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, '01012345678');
      await tester.enterText(textFields.last, 'Password123!');
      await tester.pump();

      // Tap Sign In in Arabic
      await tester.tap(find.text('تسجيل الدخول'));
      await tester.pump();
      await tester.pump();

      // Expect Arabic cooldown text
      expect(find.text('لقد تجاوزت الحد المسموح به من محاولات تسجيل الدخول. يرجى الانتظار 3 ثانية قبل المحاولة مجدداً.'), findsWidgets);
      expect(find.text('يرجى الانتظار 3 ث'), findsOneWidget);

      // Advance by 1 second
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('يرجى الانتظار 2 ث'), findsOneWidget);

      // Advance to end
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('تسجيل الدخول'), findsOneWidget);
    });
  });
}
