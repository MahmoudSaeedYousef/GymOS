import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/core/theme/app_theme.dart';
import 'package:gym_os/features/members/models/member_model.dart';
import 'package:gym_os/features/members/models/plan_model.dart';
import 'package:gym_os/features/members/providers/members_provider.dart';
import 'package:gym_os/features/members/services/gym_api_service.dart';
import 'package:gym_os/features/members/ui/add_member_sheet.dart';
import 'package:gym_os/l10n/app_localizations.dart';

class _FakeGymApiService extends GymApiService {
  final List<PlanModel> plans;
  String? lastCreatedFullName;
  String? lastCreatedPhone;
  String? lastCreatedPlanId;
  int? lastCreatedMethod;
  double? lastCreatedAmountPaid;
  int? lastCreatedGender;

  _FakeGymApiService({required this.plans}) : super(Dio());

  @override
  Future<List<PlanModel>> getPlans() async => plans;

  @override
  Future<void> createMember({
    required String fullName,
    required String phoneNumber,
    String? planId,
    int? method,
    double? amountPaid,
    int gender = 0,
  }) async {
    lastCreatedFullName = fullName;
    lastCreatedPhone = phoneNumber;
    lastCreatedPlanId = planId;
    lastCreatedMethod = method;
    lastCreatedAmountPaid = amountPaid;
    lastCreatedGender = gender;
  }

  @override
  Future<PagedMembersResponse> getMembers({
    String? search,
    String? cursor,
    int pageSize = 20,
    String? filter,
    String? sortBy,
  }) async {
    return PagedMembersResponse(
      items: const [],
      nextCursor: null,
      hasMore: false,
    );
  }
}

void main() {
  const samplePlans = [
    PlanModel(
      id: 'plan-1',
      name: 'Monthly Fitness',
      price: 350.0,
      durationInDays: 30,
      isActive: true,
    ),
    PlanModel(
      id: 'plan-2',
      name: 'Quarterly Pro',
      price: 900.0,
      durationInDays: 90,
      isActive: true,
    ),
  ];

  late _FakeGymApiService fakeApiService;

  setUp(() {
    fakeApiService = _FakeGymApiService(plans: samplePlans);
  });

  Widget createWidgetUnderTest({Locale locale = const Locale('en')}) {
    return ProviderScope(
      overrides: [
        gymApiServiceProvider.overrideWithValue(fakeApiService),
        plansProvider.overrideWith((ref) async => samplePlans),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ar')],
        theme: AppTheme.lightTheme(),
        home: const Scaffold(body: AddMemberSheet()),
      ),
    );
  }

  testWidgets(
    'Initial render: payment method chips and amount paid field are hidden when no plan is selected',
    (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Form fields for name and phone exist
      expect(find.byType(AddMemberSheet), findsOneWidget);

      // Payment method selector and amount field are NOT present initially
      expect(find.byKey(const Key('payment_method_cash')), findsNothing);
      expect(find.byKey(const Key('payment_method_instaPay')), findsNothing);
      expect(find.byKey(const Key('payment_method_vodafoneCash')), findsNothing);
      expect(find.byKey(const Key('payment_method_visa')), findsNothing);
      expect(find.byIcon(Icons.payments_rounded), findsNothing);
    },
  );

  testWidgets(
    'Selecting a plan reveals payment method selector (defaulting to Cash) and pre-fills amount with plan price',
    (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap on plan dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Select 'Monthly Fitness'
      await tester.tap(find.text('Monthly Fitness - 350 EGP').last);
      await tester.pumpAndSettle();

      // Payment method selector is now displayed with all 4 methods
      expect(find.byKey(const Key('payment_method_cash')), findsOneWidget);
      expect(find.byKey(const Key('payment_method_instaPay')), findsOneWidget);
      expect(
        find.byKey(const Key('payment_method_vodafoneCash')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('payment_method_visa')), findsOneWidget);

      // Default is cash (radio button checked)
      expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);

      // Amount field is displayed and pre-filled with 350
      expect(find.text('350'), findsOneWidget);
      expect(find.byIcon(Icons.payments_rounded), findsOneWidget);
    },
  );

  testWidgets(
    'Switching plans updates amount dynamically; switching payment method and overriding amount sends chosen values on submit',
    (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // 1. Fill Name and Phone
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Mahmoud Saeed');
      await tester.enterText(textFields.at(1), '01012345678');
      await tester.pumpAndSettle();

      // 2. Select Plan 1 (Monthly Fitness - 350 EGP)
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Monthly Fitness - 350 EGP').last);
      await tester.pumpAndSettle();

      expect(find.text('350'), findsOneWidget);

      // 3. Switch to Plan 2 (Quarterly Pro - 900 EGP)
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quarterly Pro - 900 EGP').last);
      await tester.pumpAndSettle();

      expect(find.text('900'), findsOneWidget);

      // 4. Select InstaPay payment method (value = 3)
      await tester.tap(find.byKey(const Key('payment_method_instaPay')));
      await tester.pumpAndSettle();

      // 5. Override amount to 850 (discount)
      final amountField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.keyboardType ==
                const TextInputType.numberWithOptions(decimal: true),
      );
      expect(amountField, findsOneWidget);
      await tester.enterText(amountField, '850');
      await tester.pumpAndSettle();

      // 6. Submit
      await tester.ensureVisible(find.text('Save & Activate'));
      await tester.ensureVisible(find.text('Save & Activate'));
      await tester.tap(find.text('Save & Activate'));
      await tester.pumpAndSettle();

      // Verify API was called with exact matching parameters
      expect(fakeApiService.lastCreatedFullName, 'Mahmoud Saeed');
      expect(fakeApiService.lastCreatedPhone, '01012345678');
      expect(fakeApiService.lastCreatedPlanId, 'plan-2');
      expect(fakeApiService.lastCreatedMethod, 3); // InstaPay = 3
      expect(fakeApiService.lastCreatedAmountPaid, 850.0);
    },
  );

  testWidgets(
    'Submitting without plan passes null planId, null method, and null amountPaid',
    (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Ali Nour');
      await tester.enterText(textFields.at(1), '01234567890');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save & Activate'));
      await tester.tap(find.text('Save & Activate'));
      await tester.pumpAndSettle();

      expect(fakeApiService.lastCreatedFullName, 'Ali Nour');
      expect(fakeApiService.lastCreatedPhone, '01234567890');
      expect(fakeApiService.lastCreatedPlanId, isNull);
      expect(fakeApiService.lastCreatedMethod, isNull);
      expect(fakeApiService.lastCreatedAmountPaid, isNull);
    },
  );

  testWidgets(
    'Validation: empty or non-positive amount prevents submit and displays error',
    (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Test User');
      await tester.enterText(textFields.at(1), '01234567890');
      await tester.pumpAndSettle();

      // Select plan
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Monthly Fitness - 350 EGP').last);
      await tester.pumpAndSettle();

      // Clear amount field
      final amountField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.keyboardType ==
                const TextInputType.numberWithOptions(decimal: true),
      );
      await tester.enterText(amountField, '0');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save & Activate'));
      await tester.tap(find.text('Save & Activate'));
      await tester.pumpAndSettle();

      // Did not call API because validation failed
      expect(fakeApiService.lastCreatedFullName, isNull);
      expect(find.text('Please enter a valid amount'), findsOneWidget);
    },
  );

  testWidgets(
    'Arabic locale: renders payment method chips and localized labels in Arabic RTL',
    (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Select plan
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Monthly Fitness - 350 ج.م').last);
      await tester.pumpAndSettle();

      // Payment methods in Arabic
      expect(find.text('طريقة الدفع'), findsOneWidget);
      expect(find.text('كاش'), findsOneWidget);
      expect(find.text('إنستاباي'), findsOneWidget);
      expect(find.text('فودافون كاش'), findsOneWidget);
      expect(find.text('فيزا'), findsOneWidget);
    },
  );
}
