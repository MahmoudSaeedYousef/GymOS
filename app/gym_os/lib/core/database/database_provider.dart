import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'daos/attendance_dao.dart';
import 'daos/members_dao.dart';
import 'daos/payments_dao.dart';
import 'daos/plans_dao.dart';
import 'daos/sync_outbox_dao.dart';

/// Provider for the local SQLite [AppDatabase] instance.
/// Automatically closes the database when disposed.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() {
    db.close();
  });
  return db;
});

/// Convenience provider for [MembersDao].
final membersDaoProvider = Provider<MembersDao>((ref) {
  return ref.watch(appDatabaseProvider).membersDao;
});

/// Convenience provider for [PlansDao].
final plansDaoProvider = Provider<PlansDao>((ref) {
  return ref.watch(appDatabaseProvider).plansDao;
});

/// Convenience provider for [AttendanceDao].
final attendanceDaoProvider = Provider<AttendanceDao>((ref) {
  return ref.watch(appDatabaseProvider).attendanceDao;
});

/// Convenience provider for [PaymentsDao].
final paymentsDaoProvider = Provider<PaymentsDao>((ref) {
  return ref.watch(appDatabaseProvider).paymentsDao;
});

/// Convenience provider for [SyncOutboxDao].
final syncOutboxDaoProvider = Provider<SyncOutboxDao>((ref) {
  return ref.watch(appDatabaseProvider).syncOutboxDao;
});
