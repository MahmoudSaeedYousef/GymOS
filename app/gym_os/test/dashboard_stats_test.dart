import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/core/database/app_database.dart';
import 'package:gym_os/core/database/database_provider.dart';
import 'package:gym_os/features/home/providers/dashboard_provider.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('DashboardStatsModel fromJson parsing tests', () {
    test('parses exact camelCase keys returned by .NET backend DashboardStatsDto', () {
      final json = {
        'activeMembersCount': 42,
        'expiredSubscriptionsCount': 7,
        'todayCheckInsCount': 15,
        'monthlyRevenue': 12500.5,
        'currentInside': 8,
        'todayRevenue': 1200.0,
        'monthlyDropInRevenue': 350.0,
      };

      final stats = DashboardStatsModel.fromJson(json);

      expect(stats.activeMembersCount, 42);
      expect(stats.expiredSubscriptionsCount, 7);
      expect(stats.todayCheckInsCount, 15);
      expect(stats.monthlyRevenue, 12500.5);
      expect(stats.currentInside, 8);
      expect(stats.currentInsideCount, 8);
      expect(stats.todayRevenue, 1200.0);
      expect(stats.monthlyDropInRevenue, 350.0);
    });

    test('parses PascalCase keys safely if returned by .NET serializer', () {
      final json = {
        'ActiveMembersCount': 100,
        'ExpiredSubscriptionsCount': 20,
        'TodayCheckInsCount': 35,
        'MonthlyRevenue': 50000,
        'CurrentInside': 12,
        'TodayRevenue': 2500,
        'MonthlyDropInRevenue': 800,
      };

      final stats = DashboardStatsModel.fromJson(json);

      expect(stats.activeMembersCount, 100);
      expect(stats.expiredSubscriptionsCount, 20);
      expect(stats.todayCheckInsCount, 35);
      expect(stats.monthlyRevenue, 50000.0);
      expect(stats.currentInside, 12);
      expect(stats.currentInsideCount, 12);
      expect(stats.todayRevenue, 2500.0);
      expect(stats.monthlyDropInRevenue, 800.0);
    });

    test('handles missing or null fields gracefully without crashing', () {
      final stats = DashboardStatsModel.fromJson({});

      expect(stats.activeMembersCount, 0);
      expect(stats.expiredSubscriptionsCount, 0);
      expect(stats.todayCheckInsCount, 0);
      expect(stats.monthlyRevenue, 0.0);
      expect(stats.currentInside, 0);
      expect(stats.currentInsideCount, 0);
      expect(stats.todayRevenue, 0.0);
      expect(stats.monthlyDropInRevenue, 0.0);
    });

    test('handles string-encoded numeric values safely', () {
      final json = {
        'activeMembersCount': '25',
        'expiredSubscriptionsCount': '5',
        'todayCheckInsCount': '10',
        'monthlyRevenue': '4500.75',
        'currentInside': '3',
        'todayRevenue': '600.5',
        'monthlyDropInRevenue': '150.25',
      };

      final stats = DashboardStatsModel.fromJson(json);

      expect(stats.activeMembersCount, 25);
      expect(stats.expiredSubscriptionsCount, 5);
      expect(stats.todayCheckInsCount, 10);
      expect(stats.monthlyRevenue, 4500.75);
      expect(stats.currentInside, 3);
      expect(stats.todayRevenue, 600.5);
      expect(stats.monthlyDropInRevenue, 150.25);
    });

    test('parses todayAttendanceCount and last7DaysAttendance correctly', () {
      final json = {
        'activeMembersCount': 10,
        'expiredSubscriptionsCount': 2,
        'todayAttendanceCount': 5,
        'monthlyRevenue': 1000.0,
        'currentInside': 2,
        'last7DaysAttendance': [
          {'date': '2026-11-15T00:00:00.000', 'count': 4},
          {'date': '2026-11-16T00:00:00.000', 'count': 6},
          {'date': '2026-11-17T00:00:00.000', 'count': 5},
          {'date': '2026-11-18T00:00:00.000', 'count': 3},
          {'date': '2026-11-19T00:00:00.000', 'count': 7},
          {'date': '2026-11-20T00:00:00.000', 'count': 8},
          {'date': '2026-11-21T00:00:00.000', 'count': 5},
        ],
      };

      final stats = DashboardStatsModel.fromJson(json);

      expect(stats.todayCheckInsCount, 5);
      expect(stats.todayAttendanceCount, 5);
      expect(stats.last7DaysAttendance, isNotNull);
      expect(stats.last7DaysAttendance!.length, 7);
      expect(stats.last7DaysAttendance!.first.count, 4);
      expect(stats.last7DaysAttendance!.last.count, 5);
    });

    test('parses last7DaysRevenue correctly and serializes to JSON', () {
      final json = {
        'activeMembersCount': 12,
        'expiredSubscriptionsCount': 1,
        'todayAttendanceCount': 3,
        'monthlyRevenue': 5000.0,
        'currentInside': 4,
        'todayRevenue': 1135.0,
        'monthlyDropInRevenue': 135.0,
        'last7DaysRevenue': [
          {'date': '2026-11-15T00:00:00.000', 'amount': 200.0},
          {'date': '2026-11-16T00:00:00.000', 'amount': 450.0},
          {'date': '2026-11-17T00:00:00.000', 'amount': 300.0},
          {'date': '2026-11-18T00:00:00.000', 'amount': 0.0},
          {'date': '2026-11-19T00:00:00.000', 'amount': 1500.0},
          {'date': '2026-11-20T00:00:00.000', 'amount': 800.0},
          {'date': '2026-11-21T00:00:00.000', 'amount': 1135.0},
        ],
      };

      final stats = DashboardStatsModel.fromJson(json);

      expect(stats.todayRevenue, 1135.0);
      expect(stats.last7DaysRevenue, isNotNull);
      expect(stats.last7DaysRevenue!.length, 7);
      expect(stats.last7DaysRevenue!.first.amount, 200.0);
      expect(stats.last7DaysRevenue!.last.amount, 1135.0);

      final encoded = stats.toJson();
      expect(encoded['last7DaysRevenue'], isNotNull);
      expect((encoded['last7DaysRevenue'] as List).length, 7);
    });
  });

  group('Reactive DashboardStats Drift & Deduplication Tests', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('Updating cached_dashboard_stats in Drift automatically emits updated DashboardStatsModel', () async {
      final initialStats = {
        'activeMembersCount': 50,
        'expiredSubscriptionsCount': 10,
        'todayCheckInsCount': 15,
        'monthlyRevenue': 20000.0,
        'currentInside': 5,
        'todayRevenue': 1500.0,
        'monthlyDropInRevenue': 400.0,
      };

      await db.syncOutboxDao.setMetadata(
        'cached_dashboard_stats',
        jsonEncode(initialStats),
      );

      final firstCompleter = Completer<DashboardStatsModel>();
      final updatedCompleter = Completer<DashboardStatsModel>();

      final sub = container.listen<AsyncValue<DashboardStatsModel>>(
        dashboardStatsProvider,
        (previous, next) {
          next.whenData((stats) {
            if (!firstCompleter.isCompleted) {
              firstCompleter.complete(stats);
            } else if (stats.activeMembersCount == 55 && !updatedCompleter.isCompleted) {
              updatedCompleter.complete(stats);
            }
          });
        },
        fireImmediately: true,
      );

      final firstEmission = await firstCompleter.future.timeout(const Duration(seconds: 3));
      expect(firstEmission.activeMembersCount, 50);
      expect(firstEmission.todayCheckInsCount, 15);
      expect(firstEmission.monthlyRevenue, 20000.0);

      final updatedStats = {
        'activeMembersCount': 55,
        'expiredSubscriptionsCount': 8,
        'todayCheckInsCount': 20,
        'monthlyRevenue': 25000.0,
        'currentInside': 9,
        'todayRevenue': 3000.0,
        'monthlyDropInRevenue': 600.0,
      };

      await db.syncOutboxDao.setMetadata(
        'cached_dashboard_stats',
        jsonEncode(updatedStats),
      );

      final updatedEmission = await updatedCompleter.future.timeout(const Duration(seconds: 3));
      expect(updatedEmission.activeMembersCount, 55);
      expect(updatedEmission.todayCheckInsCount, 20);
      expect(updatedEmission.monthlyRevenue, 25000.0);
      expect(updatedEmission.currentInside, 9);

      sub.close();
    });

    test('Unsynced attendance delta excludes members already synced today (zero double-counting)', () async {
      final now = DateTime.now();

      // Seed cached server stats: todayCheckInsCount = 10
      final initialStats = {
        'activeMembersCount': 30,
        'expiredSubscriptionsCount': 5,
        'todayCheckInsCount': 10,
        'monthlyRevenue': 10000.0,
        'currentInside': 4,
        'todayRevenue': 800.0,
        'monthlyDropInRevenue': 200.0,
      };
      await db.syncOutboxDao.setMetadata(
        'cached_dashboard_stats',
        jsonEncode(initialStats),
      );

      // Insert an already-synced attendance record for member 'member-A' today (isDirty == false)
      await db.into(db.localAttendance).insert(
        LocalAttendanceCompanion.insert(
          id: 'att-synced-1',
          memberId: const Value('member-A'),
          memberName: 'Member A',
          checkInTime: now,
          isDirty: const Value(false),
        ),
      );

      final completer = Completer<DashboardStatsModel>();
      final sub = container.listen<AsyncValue<DashboardStatsModel>>(
        dashboardStatsProvider,
        (previous, next) {
          next.whenData((stats) {
            // We will insert 2 unsynced records:
            // 1) member 'member-A' (already synced today -> MUST BE EXCLUDED)
            // 2) member 'member-B' (new unsynced -> MUST BE ADDED +1)
            // 3) guest drop-in (no memberId, id: 'drop-1' -> MUST BE ADDED +1)
            // Expected todayCheckInsCount = 10 + 2 = 12 (NOT 13!)
            if (stats.todayCheckInsCount == 12 && !completer.isCompleted) {
              completer.complete(stats);
            }
          });
        },
        fireImmediately: true,
      );

      // Insert unsynced record for member-A (duplicate check-in / dirty re-entry)
      await db.into(db.localAttendance).insert(
        LocalAttendanceCompanion.insert(
          id: 'att-dirty-A',
          memberId: const Value('member-A'),
          memberName: 'Member A',
          checkInTime: now,
          isDirty: const Value(true),
        ),
      );

      // Insert unsynced record for member-B (brand new member checkin)
      await db.into(db.localAttendance).insert(
        LocalAttendanceCompanion.insert(
          id: 'att-dirty-B',
          memberId: const Value('member-B'),
          memberName: 'Member B',
          checkInTime: now,
          isDirty: const Value(true),
        ),
      );

      // Insert unsynced drop-in guest (memberId null)
      await db.into(db.localAttendance).insert(
        LocalAttendanceCompanion.insert(
          id: 'drop-1',
          memberId: const Value(null),
          memberName: 'Drop In Guest',
          checkInTime: now,
          isDirty: const Value(true),
        ),
      );

      final result = await completer.future.timeout(const Duration(seconds: 3));
      // Base (10) + member-B (1) + guest (1) = 12. member-A was excluded.
      expect(result.todayCheckInsCount, 12);

      sub.close();
    });

    test('dashboardStatsProvider emits cached Drift stats immediately without an initial zero state when cached_dashboard_stats exists', () async {
      // 1. Seed cached server stats in Drift before reading the provider
      final savedStats = {
        'activeMembersCount': 142,
        'expiredSubscriptionsCount': 18,
        'todayCheckInsCount': 37,
        'monthlyRevenue': 65000.0,
        'currentInside': 14,
        'todayRevenue': 4200.0,
        'monthlyDropInRevenue': 1200.0,
      };

      await db.syncOutboxDao.setMetadata(
        'cached_dashboard_stats',
        jsonEncode(savedStats),
      );

      // 2. Track all emissions from the provider
      final emittedValues = <DashboardStatsModel>[];
      final completer = Completer<void>();

      final sub = container.listen<AsyncValue<DashboardStatsModel>>(
        dashboardStatsProvider,
        (previous, next) {
          next.whenData((stats) {
            emittedValues.add(stats);
            if (!completer.isCompleted) {
              completer.complete();
            }
          });
        },
        fireImmediately: true,
      );

      await completer.future.timeout(const Duration(seconds: 3));

      // 3. Verify the very first emission contains the cached stats, NOT zeroes
      expect(emittedValues, isNotEmpty);
      final firstStats = emittedValues.first;
      expect(firstStats.activeMembersCount, 142);
      expect(firstStats.expiredSubscriptionsCount, 18);
      expect(firstStats.todayCheckInsCount, 37);
      expect(firstStats.monthlyRevenue, 65000.0);
      expect(firstStats.currentInside, 14);
      expect(firstStats.todayRevenue, 4200.0);
      expect(firstStats.monthlyDropInRevenue, 1200.0);

      // Ensure NO emission ever had all-zero stats while cached stats existed
      for (final stats in emittedValues) {
        expect(stats.activeMembersCount, greaterThan(0));
        expect(stats.todayCheckInsCount, greaterThan(0));
      }

      sub.close();
    });
  });
}
