import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/local_attendance.dart';
import '../tables/local_payments.dart';
import '../tables/sync_outbox.dart';

part 'attendance_dao.g.dart';

@DriftAccessor(tables: [LocalAttendance, LocalPayments, SyncOutbox])
class AttendanceDao extends DatabaseAccessor<AppDatabase>
    with _$AttendanceDaoMixin {
  AttendanceDao(super.db);

  /// Watches attendance records for the given time range (e.g. today).
  Stream<List<LocalAttendanceData>> watchTodayAttendance(
    DateTime dayStart,
    DateTime dayEnd,
  ) {
    return (select(localAttendance)
          ..where(
            (t) =>
                t.checkInTime.isBiggerOrEqualValue(dayStart) &
                t.checkInTime.isSmallerOrEqualValue(dayEnd),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.checkInTime, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Watches members currently inside the facility (no check-out recorded yet).
  Stream<List<LocalAttendanceData>> watchCurrentlyCheckedIn() {
    return (select(localAttendance)
          ..where((t) => t.checkOutTime.isNull())
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.checkInTime, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Records check-in and queues outbox operation in an atomic transaction.
  Future<void> recordCheckInWithOutbox(
    LocalAttendanceCompanion entry,
    SyncOutboxCompanion outboxEntry,
  ) async {
    await transaction(() async {
      await into(localAttendance).insert(
        entry.copyWith(isDirty: const Value(true)),
        mode: InsertMode.insertOrReplace,
      );
      await into(syncOutbox).insert(outboxEntry);
    });
  }

  /// Records check-out and queues outbox operation in an atomic transaction.
  Future<void> recordCheckOutWithOutbox(
    String attendanceId,
    DateTime checkOutTime,
    SyncOutboxCompanion outboxEntry,
  ) async {
    await transaction(() async {
      await (update(localAttendance)..where((t) => t.id.equals(attendanceId)))
          .write(
        LocalAttendanceCompanion(
          checkOutTime: Value(checkOutTime),
          isDirty: const Value(true),
        ),
      );
      await into(syncOutbox).insert(outboxEntry);
    });
  }

  /// Records a drop-in session: writes attendance, payment, and sync outbox
  /// atomically in a single transaction.
  Future<void> recordDropInWithOutbox({
    required LocalAttendanceCompanion attendance,
    required LocalPaymentsCompanion payment,
    required SyncOutboxCompanion outboxEntry,
  }) async {
    await transaction(() async {
      await into(localAttendance).insert(
        attendance.copyWith(isDirty: const Value(true)),
        mode: InsertMode.insertOrReplace,
      );
      await into(localPayments).insert(
        payment.copyWith(isDirty: const Value(true)),
        mode: InsertMode.insertOrReplace,
      );
      await into(syncOutbox).insert(outboxEntry);
    });
  }

  /// Upserts attendance records from the server, skipping rows with isDirty == true.
  Future<void> upsertAttendanceFromServer(
    List<LocalAttendanceCompanion> items,
  ) async {
    if (items.isEmpty) return;
    await transaction(() async {
      for (final item in items) {
        final existing = await (select(localAttendance)
              ..where((t) => t.id.equals(item.id.value)))
            .getSingleOrNull();

        if (existing != null) {
          if (existing.isDirty) {
            continue; // Skip dirty local records
          }
          await (update(localAttendance)
                ..where((t) => t.id.equals(item.id.value)))
              .write(
            item.copyWith(isDirty: const Value(false)),
          );
        } else {
          await into(localAttendance).insert(
            item.copyWith(isDirty: const Value(false)),
            mode: InsertMode.insertOrReplace,
          );
        }
      }
    });
  }
}
