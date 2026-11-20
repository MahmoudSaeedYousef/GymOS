import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/local_payments.dart';
import '../tables/sync_outbox.dart';

part 'payments_dao.g.dart';

@DriftAccessor(tables: [LocalPayments, SyncOutbox])
class PaymentsDao extends DatabaseAccessor<AppDatabase>
    with _$PaymentsDaoMixin {
  PaymentsDao(super.db);

  /// Watches payments recorded within a specific date-time range.
  Stream<List<LocalPayment>> watchPaymentsInRange(
    DateTime start,
    DateTime end,
  ) {
    return (select(localPayments)
          ..where(
            (t) =>
                t.createdAt.isBiggerOrEqualValue(start) &
                t.createdAt.isSmallerOrEqualValue(end),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Records a local payment and queues outbox operation in an atomic transaction.
  Future<void> insertPaymentWithOutbox(
    LocalPaymentsCompanion payment,
    SyncOutboxCompanion outboxEntry,
  ) async {
    await transaction(() async {
      await into(localPayments).insert(
        payment.copyWith(isDirty: const Value(true)),
        mode: InsertMode.insertOrReplace,
      );
      await into(syncOutbox).insert(outboxEntry);
    });
  }

  /// Upserts payments from the server, skipping rows with isDirty == true.
  Future<void> upsertPaymentsFromServer(
    List<LocalPaymentsCompanion> items,
  ) async {
    if (items.isEmpty) return;
    await transaction(() async {
      for (final item in items) {
        final existing = await (select(localPayments)
              ..where((t) => t.id.equals(item.id.value)))
            .getSingleOrNull();

        if (existing != null) {
          if (existing.isDirty) {
            continue;
          }
          await (update(localPayments)..where((t) => t.id.equals(item.id.value)))
              .write(
            item.copyWith(isDirty: const Value(false)),
          );
        } else {
          await into(localPayments).insert(
            item.copyWith(isDirty: const Value(false)),
            mode: InsertMode.insertOrReplace,
          );
        }
      }
    });
  }
}
