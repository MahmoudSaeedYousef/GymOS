import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/features/home/models/dashboard_stats_model.dart';

void main() {
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
  });
}
