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
  int get schemaVersion => 1;
}
