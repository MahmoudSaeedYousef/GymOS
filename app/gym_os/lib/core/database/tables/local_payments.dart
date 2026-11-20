import 'package:drift/drift.dart';

/// Local storage table for membership and drop-in payments.
class LocalPayments extends Table {
  /// Payment UUID (client-generated).
  TextColumn get id => text()();

  /// Associated member UUID (nullable).
  TextColumn get memberId => text().nullable()();

  /// Member name at the time of payment (nullable).
  TextColumn get memberName => text().nullable()();

  /// Associated plan UUID (nullable).
  TextColumn get planId => text().nullable()();

  /// Total amount paid.
  RealColumn get amountPaid => real()();

  /// Payment method: 1 = Cash, 2 = Visa, 3 = InstaPay, 4 = Vodafone Cash.
  IntColumn get method => integer()();

  /// Payment type: subscription, renewal, drop-in, etc.
  IntColumn get type => integer()();

  /// Payment timestamp.
  DateTimeColumn get createdAt => dateTime()();

  /// Local dirty flag: true when created locally and awaiting sync.
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
