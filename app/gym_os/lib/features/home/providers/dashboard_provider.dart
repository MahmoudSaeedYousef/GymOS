import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_stats_model.dart';
import '../services/dashboard_api_service.dart';

export '../models/dashboard_stats_model.dart';
export '../models/drop_in_visit_models.dart';
export '../services/dashboard_api_service.dart';
export 'weekly_stats_provider.dart';

/// Provider fetching gym-wide dashboard statistics.
final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStatsModel>((ref) async {
  final api = ref.watch(dashboardApiServiceProvider);
  return api.getStats();
});
