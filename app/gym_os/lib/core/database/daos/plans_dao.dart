import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/local_plans.dart';

part 'plans_dao.g.dart';

@DriftAccessor(tables: [LocalPlans])
class PlansDao extends DatabaseAccessor<AppDatabase> with _$PlansDaoMixin {
  PlansDao(super.db);

  /// Watches all active plans ordered by name.
  Stream<List<LocalPlan>> watchActivePlans() {
    return (select(localPlans)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([
            (t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// Atomically replaces all plans with the latest set from the server.
  Future<void> replaceAllPlans(List<LocalPlansCompanion> plans) async {
    await transaction(() async {
      await delete(localPlans).go();
      for (final plan in plans) {
        await into(localPlans).insert(plan);
      }
    });
  }
}
