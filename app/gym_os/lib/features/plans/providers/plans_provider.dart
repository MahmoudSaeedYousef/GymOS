import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plan_model.dart';
import '../services/plans_api_service.dart';

export '../models/plan_model.dart';
export '../services/plans_api_service.dart';

/// Provider for all plans (active and inactive), used by PlansManagementScreen.
final allPlansProvider = FutureProvider.autoDispose<List<PlanModel>>((ref) async {
  final api = ref.watch(plansApiServiceProvider);
  return api.getPlans(activeOnly: false);
});

/// Provider for active plans only, used by dropdowns (Member creation, Subscription renewal).
final activePlansProvider = FutureProvider.autoDispose<List<PlanModel>>((ref) async {
  final api = ref.watch(plansApiServiceProvider);
  return api.getPlans(activeOnly: true);
});

/// Alias for activePlansProvider for backward compatibility.
final plansProvider = activePlansProvider;
