import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/attendance_dao.dart';
import 'daos/members_dao.dart';
import 'daos/payments_dao.dart';
import 'daos/plans_dao.dart';
import 'daos/sync_outbox_dao.dart';
import 'tables/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    LocalMembers,
    LocalPlans,
    LocalAttendance,
    LocalPayments,
    SyncOutbox,
    SyncMetadata,
  ],
  daos: [
    MembersDao,
    PlansDao,
    AttendanceDao,
    PaymentsDao,
    SyncOutboxDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'gym_os_local'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(localMembers, localMembers.photoUrl);
          }
        },
      );

  /// Clears all local tables and sync metadata for clean synchronization.
  Future<void> clearAllTablesAndMetadata() async {
    await transaction(() async {
      await delete(syncOutbox).go();
      await delete(syncMetadata).go();
      await delete(localAttendance).go();
      await delete(localPayments).go();
      await delete(localMembers).go();
      await delete(localPlans).go();
    });
  }
}
