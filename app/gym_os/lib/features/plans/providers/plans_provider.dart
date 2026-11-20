import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../models/plan_model.dart';
import '../services/plans_api_service.dart';

export '../models/plan_model.dart';
export '../services/plans_api_service.dart';

/// Provider for all plans (active and inactive), used by PlansManagementScreen.
final allPlansProvider =
    FutureProvider.autoDispose<List<PlanModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final localPlans = await db.plansDao.watchActivePlans().first;
  if (localPlans.isNotEmpty) {
    return localPlans
        .map((p) => PlanModel(
              id: p.id,
              name: p.name,
              price: p.price,
              durationInDays: p.durationDays,
              isActive: p.isActive,
            ))
        .toList();
  }
  final api = ref.watch(plansApiServiceProvider);
  return api.getPlans(activeOnly: false);
});

/// Provider for active plans only, reading from Drift local first with API fallback.
final activePlansProvider =
    FutureProvider.autoDispose<List<PlanModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final localPlans = await db.plansDao.watchActivePlans().first;
  if (localPlans.isNotEmpty) {
    return localPlans
        .map((p) => PlanModel(
              id: p.id,
              name: p.name,
              price: p.price,
              durationInDays: p.durationDays,
              isActive: p.isActive,
            ))
        .toList();
  }
  final api = ref.watch(plansApiServiceProvider);
  return api.getPlans(activeOnly: true);
});

/// Alias for activePlansProvider for backward compatibility.
final plansProvider = activePlansProvider;
