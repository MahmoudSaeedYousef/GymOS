import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/local_attendance.dart';
import '../tables/local_members.dart';
import '../tables/local_payments.dart';
import '../tables/sync_metadata.dart';
import '../tables/sync_outbox.dart';

part 'sync_outbox_dao.g.dart';

@DriftAccessor(
  tables: [
    SyncOutbox,
    SyncMetadata,
    LocalMembers,
    LocalAttendance,
    LocalPayments,
  ],
)
class SyncOutboxDao extends DatabaseAccessor<AppDatabase>
    with _$SyncOutboxDaoMixin {
  SyncOutboxDao(super.db);

  /// Watches the number of operations currently pending synchronization.
  Stream<int> watchPendingCount() {
    final countExp = syncOutbox.id.count();
    final query = selectOnly(syncOutbox)
      ..addColumns([countExp])
      ..where(syncOutbox.status.equals('pending'));

    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }

  /// Returns pending sync operations ordered strictly FIFO by `id` ASC.
  Future<List<SyncOutboxData>> getPendingOperations({int limit = 20}) {
    return (select(syncOutbox)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.id)])
          ..limit(limit))
        .get();
  }

  /// Marks an outbox operation as currently in-flight syncing.
  Future<void> markSyncing(int id) {
    return (update(syncOutbox)..where((t) => t.id.equals(id))).write(
      const SyncOutboxCompanion(status: Value('syncing')),
    );
  }

  /// Marks an operation completed inside an atomic transaction:
  /// deletes the outbox row and clears `isDirty = false` on the target local entity.
  Future<void> markCompleted(
    int id, {
    String? entityType,
    String? entityId,
  }) async {
    await transaction(() async {
      final outboxItem = await (select(syncOutbox)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();

      final resolvedType = entityType ?? outboxItem?.entityType;
      final resolvedId = entityId ?? outboxItem?.entityId;

      if (resolvedType != null && resolvedId != null) {
        if (resolvedType.startsWith('member')) {
          await (update(localMembers)..where((t) => t.id.equals(resolvedId)))
              .write(
            const LocalMembersCompanion(isDirty: Value(false)),
          );
        } else if (resolvedType == 'dropin') {
          await (update(localAttendance)..where((t) => t.id.equals(resolvedId)))
              .write(
            const LocalAttendanceCompanion(isDirty: Value(false)),
          );
          await (update(localPayments)
                ..where((t) => t.id.equals(resolvedId) | t.memberId.equals(resolvedId)))
              .write(
            const LocalPaymentsCompanion(isDirty: Value(false)),
          );
        } else if (resolvedType == 'checkin' ||
            resolvedType == 'checkout' ||
            resolvedType.startsWith('attendance')) {
          await (update(localAttendance)..where((t) => t.id.equals(resolvedId)))
              .write(
            const LocalAttendanceCompanion(isDirty: Value(false)),
          );
        } else if (resolvedType.startsWith('payment')) {
          await (update(localPayments)..where((t) => t.id.equals(resolvedId)))
              .write(
            const LocalPaymentsCompanion(isDirty: Value(false)),
          );
        }
      }

      await (delete(syncOutbox)..where((t) => t.id.equals(id))).go();
    });
  }

  /// Records a sync failure:
  /// increments `retryCount`, sets `lastError`, and resets status to `'pending'`
  /// if `retryCount < 5`, otherwise marks as permanently `'failed'`.
  Future<void> markFailed(int id, String errorMessage) async {
    await transaction(() async {
      final row = await (select(syncOutbox)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (row != null) {
        final newRetry = row.retryCount + 1;
        final newStatus = newRetry < 5 ? 'pending' : 'failed';
        await (update(syncOutbox)..where((t) => t.id.equals(id))).write(
          SyncOutboxCompanion(
            retryCount: Value(newRetry),
            lastError: Value(errorMessage),
            status: Value(newStatus),
          ),
        );
      }
    });
  }

  /// Gets a sync metadata value by key (e.g., 'last_pulled_at').
  Future<String?> getMetadata(String key) async {
    final row = await (select(syncMetadata)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  /// Sets or updates a sync metadata key-value pair.
  Future<void> setMetadata(String key, String value) async {
    await into(syncMetadata).insertOnConflictUpdate(
      SyncMetadataCompanion.insert(key: key, value: value),
    );
  }
}
