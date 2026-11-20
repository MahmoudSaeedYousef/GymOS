import 'package:drift/drift.dart';

/// Local storage table for gym subscription plans.
class LocalPlans extends Table {
  /// Plan UUID.
  TextColumn get id => text()();

  /// Plan display name.
  TextColumn get name => text()();

  /// Plan price.
  RealColumn get price => real()();

  /// Duration of the plan in days.
  IntColumn get durationDays => integer()();

  /// Whether the plan is active for new subscriptions.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Last updated timestamp.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
