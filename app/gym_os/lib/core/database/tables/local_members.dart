import 'package:drift/drift.dart';

/// Local storage table for gym members.
class LocalMembers extends Table {
  /// UUID matching backend Guid.
  TextColumn get id => text()();

  /// Member's full name.
  TextColumn get fullName => text()();

  /// Member's phone number.
  TextColumn get phone => text()();

  /// Member's email address (optional).
  TextColumn get email => text().nullable()();

  /// Identifier of the assigned subscription plan.
  TextColumn get planId => text().nullable()();

  /// Name of the assigned subscription plan.
  TextColumn get planName => text().nullable()();

  /// Subscription start timestamp.
  DateTimeColumn get subscriptionStartDate => dateTime().nullable()();

  /// Subscription end timestamp.
  DateTimeColumn get subscriptionEndDate => dateTime().nullable()();

  /// Whether the member is a one-time/guest user.
  BoolColumn get isGuest => boolean().withDefault(const Constant(false))();

  /// Member status code (e.g., 1 = active, 0 = inactive, etc.).
  IntColumn get status => integer().withDefault(const Constant(1))();

  /// Last updated timestamp.
  DateTimeColumn get updatedAt => dateTime()();

  /// Local dirty flag: true when modified locally and awaiting sync.
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
