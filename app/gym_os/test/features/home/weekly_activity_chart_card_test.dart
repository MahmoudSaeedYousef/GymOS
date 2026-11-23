import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/core/database/app_database.dart';
import 'package:gym_os/core/theme/app_theme.dart';
import 'package:gym_os/features/home/providers/weekly_stats_provider.dart';
import 'package:gym_os/features/home/ui/widgets/weekly_activity_chart_card.dart';
import 'package:gym_os/l10n/app_localizations.dart';

void main() {
  final fixedRefDate = DateTime(2026, 11, 20, 15, 30); // Friday Nov 20, 2026

  group('Weekly Stats Provider & Aggregation Tests', () {
    test('aggregateWeeklyStats emits exactly 7 ordered days with zero values when streams are empty', () async {
      final attendanceController = StreamController<List<LocalAttendanceData>>();
      final paymentsController = StreamController<List<LocalPayment>>();

      final stream = aggregateWeeklyStats(
        attendanceStream: attendanceController.stream,
        paymentsStream: paymentsController.stream,
        now: fixedRefDate,
      );

      final expectation = expectLater(
        stream,
        emits((List<DailyStatPoint> points) {
          expect(points.length, 7);
          // Oldest day: 2026-11-14 (6 days before Nov 20)
          expect(points.first.date.year, 2026);
          expect(points.first.date.month, 11);
          expect(points.first.date.day, 14);
          // Newest day: 2026-11-20 (today)
          expect(points.last.date.year, 2026);
          expect(points.last.date.month, 11);
          expect(points.last.date.day, 20);

          // All zero
          for (final p in points) {
            expect(p.attendanceCount, 0);
            expect(p.revenueAmount, 0.0);
          }
          return true;
        }),
      );

      attendanceController.add([]);
      paymentsController.add([]);

      await expectation;
      await attendanceController.close();
      await paymentsController.close();
    });

    test('aggregateWeeklyStats correctly maps records to their respective calendar days and ignores out of range', () async {
      final attendanceController = StreamController<List<LocalAttendanceData>>();
      final paymentsController = StreamController<List<LocalPayment>>();

      final stream = aggregateWeeklyStats(
        attendanceStream: attendanceController.stream,
        paymentsStream: paymentsController.stream,
        now: fixedRefDate,
      );

      final attendanceData = [
        // Today (Nov 20) - 2 check-ins
        LocalAttendanceData(
          id: 'a1',
          memberId: 'm1',
          memberName: 'Ahmed',
          memberPhone: null,
          checkInTime: DateTime(2026, 11, 20, 9, 0),
          checkOutTime: null,
          isDropIn: false,
          isDirty: false,
        ),
        LocalAttendanceData(
          id: 'a2',
          memberId: 'm2',
          memberName: 'Ali',
          memberPhone: null,
          checkInTime: DateTime(2026, 11, 20, 18, 30),
          checkOutTime: null,
          isDropIn: true,
          isDirty: false,
        ),
        // 2 days ago (Nov 18) - 1 check-in
        LocalAttendanceData(
          id: 'a3',
          memberId: 'm3',
          memberName: 'Sara',
          memberPhone: null,
          checkInTime: DateTime(2026, 11, 18, 14, 0),
          checkOutTime: null,
          isDropIn: false,
          isDirty: false,
        ),
        // 10 days ago (Nov 10) - out of range, should not be counted
        LocalAttendanceData(
          id: 'a4',
          memberId: 'm4',
          memberName: 'Omar',
          memberPhone: null,
          checkInTime: DateTime(2026, 11, 10, 10, 0),
          checkOutTime: null,
          isDropIn: false,
          isDirty: false,
        ),
      ];

      final paymentsData = [
        // Today (Nov 20) - 1500 EGP
        LocalPayment(
          id: 'p1',
          memberId: 'm1',
          memberName: 'Ahmed',
          planId: 'plan1',
          amountPaid: 1500.0,
          method: 1,
          type: 1,
          createdAt: DateTime(2026, 11, 20, 9, 5),
          isDirty: false,
        ),
        // 6 days ago (Nov 14) - 500 EGP + 250 EGP
        LocalPayment(
          id: 'p2',
          memberId: 'm2',
          memberName: 'Ali',
          planId: 'plan2',
          amountPaid: 500.0,
          method: 2,
          type: 1,
          createdAt: DateTime(2026, 11, 14, 11, 0),
          isDirty: false,
        ),
        LocalPayment(
          id: 'p3',
          memberId: 'm3',
          memberName: 'Sara',
          planId: null,
          amountPaid: 250.0,
          method: 1,
          type: 2,
          createdAt: DateTime(2026, 11, 14, 16, 0),
          isDirty: false,
        ),
        // Future / out of range payment
        LocalPayment(
          id: 'p4',
          memberId: 'm5',
          memberName: 'Mona',
          planId: null,
          amountPaid: 800.0,
          method: 1,
          type: 1,
          createdAt: DateTime(2026, 11, 25, 12, 0),
          isDirty: false,
        ),
      ];

      final expectation = expectLater(
        stream,
        emits((List<DailyStatPoint> points) {
          expect(points.length, 7);

          // Day 0: Nov 14 (6 days ago)
          expect(points[0].date.day, 14);
          expect(points[0].attendanceCount, 0);
          expect(points[0].revenueAmount, 750.0);

          // Day 4: Nov 18 (2 days ago)
          expect(points[4].date.day, 18);
          expect(points[4].attendanceCount, 1);
          expect(points[4].revenueAmount, 0.0);

          // Day 6: Nov 20 (today)
          expect(points[6].date.day, 20);
          expect(points[6].attendanceCount, 2);
          expect(points[6].revenueAmount, 1500.0);

          return true;
        }),
      );

      attendanceController.add(attendanceData);
      paymentsController.add(paymentsData);

      await expectation;
      await attendanceController.close();
      await paymentsController.close();
    });

    test('aggregateWeeklyStats deduplicates multiple check-ins by the same memberId on the same day', () async {
      final attendanceController = StreamController<List<LocalAttendanceData>>();
      final paymentsController = StreamController<List<LocalPayment>>();

      final stream = aggregateWeeklyStats(
        attendanceStream: attendanceController.stream,
        paymentsStream: paymentsController.stream,
        now: fixedRefDate,
      );

      final attendanceData = [
        // Member m1 checked in twice on Nov 20 (morning & evening)
        LocalAttendanceData(
          id: 'a1',
          memberId: 'm1',
          memberName: 'Ahmed',
          memberPhone: null,
          checkInTime: DateTime(2026, 11, 20, 9, 0),
          checkOutTime: DateTime(2026, 11, 20, 11, 0),
          isDropIn: false,
          isDirty: false,
        ),
        LocalAttendanceData(
          id: 'a2',
          memberId: 'm1',
          memberName: 'Ahmed',
          memberPhone: null,
          checkInTime: DateTime(2026, 11, 20, 18, 0),
          checkOutTime: null,
          isDropIn: false,
          isDirty: false,
        ),
        // Member m2 checked in once on Nov 20
        LocalAttendanceData(
          id: 'a3',
          memberId: 'm2',
          memberName: 'Sara',
          memberPhone: null,
          checkInTime: DateTime(2026, 11, 20, 15, 0),
          checkOutTime: null,
          isDropIn: false,
          isDirty: false,
        ),
      ];

      final expectation = expectLater(
        stream,
        emits((List<DailyStatPoint> points) {
          // Today's point should count 2 unique members, not 3 total check-ins
          final todayPoint = points.last;
          expect(todayPoint.date.day, 20);
          expect(todayPoint.attendanceCount, 2);
          return true;
        }),
      );

      attendanceController.add(attendanceData);
      paymentsController.add([]);

      await expectation;
      await attendanceController.close();
      await paymentsController.close();
    });

    test('aggregateWeeklyStats includes single-session / guest payments with strict [today, tomorrow) boundaries', () async {
      final attendanceController = StreamController<List<LocalAttendanceData>>();
      final paymentsController = StreamController<List<LocalPayment>>();

      final stream = aggregateWeeklyStats(
        attendanceStream: attendanceController.stream,
        paymentsStream: paymentsController.stream,
        now: fixedRefDate,
      );

      final paymentsData = [
        // Today standard payment (1000 EGP)
        LocalPayment(
          id: 'p1',
          memberId: 'm1',
          memberName: 'Member 1',
          planId: 'plan1',
          amountPaid: 1000.0,
          method: 1,
          type: 1, // Standard
          createdAt: DateTime(2026, 11, 20, 10, 0),
          isDirty: false,
        ),
        // Today guest/single-session payment (100 EGP)
        LocalPayment(
          id: 'p2',
          memberId: null,
          memberName: 'Guest 1',
          planId: null,
          amountPaid: 100.0,
          method: 3,
          type: 3, // Drop-in / guest
          createdAt: DateTime(2026, 11, 20, 14, 0),
          isDirty: false,
        ),
        // Today guest near midnight boundary at 23:59:59 (35 EGP)
        LocalPayment(
          id: 'p3',
          memberId: null,
          memberName: 'Guest 2',
          planId: null,
          amountPaid: 35.0,
          method: 4,
          type: 3, // Drop-in / guest
          createdAt: DateTime(2026, 11, 20, 23, 59, 59),
          isDirty: false,
        ),
        // Tomorrow at 00:00:00 (outside today's [targetDay, nextDay) boundary)
        LocalPayment(
          id: 'p4',
          memberId: 'm3',
          memberName: 'Member 3',
          planId: 'plan1',
          amountPaid: 500.0,
          method: 1,
          type: 1,
          createdAt: DateTime(2026, 11, 21, 0, 0, 0),
          isDirty: false,
        ),
      ];

      final expectation = expectLater(
        stream,
        emits((List<DailyStatPoint> points) {
          // Today's point: 1000 + 100 + 35 = 1135
          final todayPoint = points.last;
          expect(todayPoint.date.day, 20);
          expect(todayPoint.revenueAmount, 1135.0);
          return true;
        }),
      );

      attendanceController.add([]);
      paymentsController.add(paymentsData);

      await expectation;
      await attendanceController.close();
      await paymentsController.close();
    });
  });

  group('WeeklyActivityChartCard Widget Tests', () {
    List<DailyStatPoint> generateSamplePoints() {
      // 7 days ending on fixedRefDate (Nov 20, 2026)
      return [
        DailyStatPoint(date: DateTime(2026, 11, 14), attendanceCount: 5, revenueAmount: 500.0), // Sat
        DailyStatPoint(date: DateTime(2026, 11, 15), attendanceCount: 8, revenueAmount: 850.0), // Sun
        DailyStatPoint(date: DateTime(2026, 11, 16), attendanceCount: 6, revenueAmount: 0.0),   // Mon
        DailyStatPoint(date: DateTime(2026, 11, 17), attendanceCount: 10, revenueAmount: 1200.0),// Tue
        DailyStatPoint(date: DateTime(2026, 11, 18), attendanceCount: 7, revenueAmount: 650.0), // Wed
        DailyStatPoint(date: DateTime(2026, 11, 19), attendanceCount: 12, revenueAmount: 1400.0),// Thu
        DailyStatPoint(date: DateTime(2026, 11, 20), attendanceCount: 9, revenueAmount: 1015.0), // Fri (today)
      ];
    }

    Widget createWidgetUnderTest({
      required List<DailyStatPoint> points,
      Locale locale = const Locale('en'),
      double textScale = 1.0,
      Size screenSize = const Size(390, 844),
    }) {
      return ProviderScope(
        overrides: [
          weeklyStatsProvider.overrideWith((ref) => Stream.value(points)),
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
          home: MediaQuery(
            data: MediaQueryData(
              size: screenSize,
              textScaler: TextScaler.linear(textScale),
            ),
            child: const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16.0),
                child: WeeklyActivityChartCard(),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Always renders 7 day labels even when some/all days have 0 records (empty state)', (tester) async {
      final zeroPoints = List.generate(
        7,
        (i) => DailyStatPoint(
          date: DateTime(2026, 11, 14 + i),
          attendanceCount: 0,
          revenueAmount: 0.0,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest(points: zeroPoints, locale: const Locale('en')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Header title
      expect(find.text('Last 7 Days'), findsOneWidget);

      // Subtitle total attendance is 0
      expect(find.text('Total: 0 check-ins'), findsOneWidget);

      // Empty state hint appears
      expect(find.text('No activity data yet'), findsOneWidget);

      // All 7 English day labels are rendered: Sat, Sun, Mon, Tue, Wed, Thu, Fri
      expect(find.text('Sat'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('Toggling between Attendance and Revenue updates the displayed totals and bar values', (tester) async {
      final points = generateSamplePoints();
      // Total attendance: 5+8+6+10+7+12+9 = 57
      // Total revenue: 500+850+0+1200+650+1400+1015 = 5615.0

      await tester.pumpWidget(createWidgetUnderTest(points: points, locale: const Locale('en')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Initial mode is Attendance: total 57 check-ins
      expect(find.text('Total: 57 check-ins'), findsOneWidget);

      // Today's value (9) is displayed above today's bar
      expect(find.text('9'), findsOneWidget);

      // Tap on Revenue pill toggle
      final revenueToggle = find.text('Revenue');
      expect(revenueToggle, findsOneWidget);
      await tester.tap(revenueToggle);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Subtitle switches to total revenue formatted
      expect(find.text('Total: 5,615 EGP'), findsOneWidget);

      // Today's revenue value (1,015) is displayed above today's bar
      expect(find.text('1,015'), findsOneWidget);

      // Tap back on Attendance
      final attendanceToggle = find.text('Attendance');
      await tester.tap(attendanceToggle);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Subtitle reverts to attendance
      expect(find.text('Total: 57 check-ins'), findsOneWidget);
    });

    testWidgets('Tapping any bar selects it and displays its specific date and value in the subtitle', (tester) async {
      final points = generateSamplePoints();

      await tester.pumpWidget(createWidgetUnderTest(points: points, locale: const Locale('en')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // By default, Today (Fri) is selected
      expect(find.text('Total: 57 check-ins'), findsOneWidget);

      // Tap Tue bar (index 3, which has attendanceCount 10)
      final tueLabel = find.text('Tue');
      expect(tueLabel, findsOneWidget);
      await tester.tap(tueLabel);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Subtitle now shows Tue specific date and 10 attendance
      expect(find.text('Tue, Nov 17: 10 Attendance'), findsOneWidget);
      // Value 10 is visible
      expect(find.text('10'), findsOneWidget);

      // Switch to Revenue while Tue is selected
      await tester.tap(find.text('Revenue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Subtitle now shows Tue revenue: 1,200 EGP
      expect(find.text('Tue, Nov 17: 1,200 EGP'), findsOneWidget);
    });

    testWidgets('Works in Arabic (RTL) without overflow and with correct Arabic day labels', (tester) async {
      final points = generateSamplePoints();

      await tester.pumpWidget(createWidgetUnderTest(
        points: points,
        locale: const Locale('ar'),
        screenSize: const Size(360, 640), // Compact screen
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Arabic header & total
      expect(find.text('آخر 7 أيام'), findsOneWidget);
      expect(find.text('إجمالي: 57 حضور'), findsOneWidget);

      // Arabic pill toggles
      expect(find.text('الحضور'), findsOneWidget);
      expect(find.text('الإيرادات'), findsOneWidget);

      // Arabic day labels rendered
      expect(find.text('سبت'), findsOneWidget);
      expect(find.text('أحد'), findsOneWidget);
      expect(find.text('إثنين'), findsOneWidget);
      expect(find.text('ثلاثاء'), findsOneWidget);
      expect(find.text('أربعاء'), findsOneWidget);
      expect(find.text('خميس'), findsOneWidget);
      expect(find.text('جمعة'), findsOneWidget);

      // Tap Revenue in Arabic
      await tester.tap(find.text('الإيرادات'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('إجمالي: 5,615 ج.م'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('Works with high text scaling (1.3x) without layout overflow', (tester) async {
      final points = generateSamplePoints();

      await tester.pumpWidget(createWidgetUnderTest(
        points: points,
        locale: const Locale('ar'),
        textScale: 1.3,
        screenSize: const Size(320, 568), // iPhone SE 1st gen narrow width
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });
  });
}
