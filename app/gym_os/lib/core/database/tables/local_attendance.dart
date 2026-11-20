import 'package:drift/drift.dart';

/// Local storage table for check-in and check-out attendance records.
@DataClassName('LocalAttendanceData')
class LocalAttendance extends Table {
  /// Attendance record UUID (client-generated UUID v4/v7).
  TextColumn get id => text()();

  /// Member UUID (nullable for unregistered walk-in/guest drop-ins).
  TextColumn get memberId => text().nullable()();

  /// Name of the member or guest attending.
  TextColumn get memberName => text()();

  /// Contact phone number (nullable).
  TextColumn get memberPhone => text().nullable()();

  /// Check-in timestamp.
  DateTimeColumn get checkInTime => dateTime()();

  /// Check-out timestamp (nullable until member checks out).
  DateTimeColumn get checkOutTime => dateTime().nullable()();

  /// Whether this attendance is a guest drop-in session.
  BoolColumn get isDropIn => boolean().withDefault(const Constant(false))();

  /// Local dirty flag: true when created/modified locally awaiting sync.
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
