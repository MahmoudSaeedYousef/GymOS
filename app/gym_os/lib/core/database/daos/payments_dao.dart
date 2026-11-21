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

  /// Deletes a local payment by its ID.
  Future<void> deletePaymentById(String paymentId) {
    return (delete(localPayments)..where((t) => t.id.equals(paymentId))).go();
  }

  /// Reconciles a temporary local payment ID with the server's persisted payment ID.
  Future<void> reconcilePaymentId(String localPaymentId, String serverPaymentId) async {
    if (localPaymentId == serverPaymentId) return;
    await transaction(() async {
      final local = await (select(localPayments)..where((t) => t.id.equals(localPaymentId))).getSingleOrNull();
      if (local != null) {
        await (delete(localPayments)..where((t) => t.id.equals(localPaymentId))).go();
        await into(localPayments).insert(
          local.copyWith(
            id: serverPaymentId,
            isDirty: false,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Upserts payments from the server, skipping rows with isDirty == true.
  /// If a clean local payment exists with the same amount and created within 60 seconds
  /// (e.g. from a just-pushed outbox operation before ID reconciliation), it reconciles/removes
  /// the temporary local row to prevent duplicates.
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
          // Check if there is an existing clean local payment created around the same time
          // with matching amount and member name that has a different temporary ID.
          final itemTime = item.createdAt.value;
          final timeWindowStart = itemTime.subtract(const Duration(minutes: 5));
          final timeWindowEnd = itemTime.add(const Duration(minutes: 5));

          final duplicates = await (select(localPayments)
                ..where((t) =>
                    t.isDirty.equals(false) &
                    t.amountPaid.equals(item.amountPaid.value) &
                    t.createdAt.isBiggerOrEqualValue(timeWindowStart) &
                    t.createdAt.isSmallerOrEqualValue(timeWindowEnd)))
              .get();

          // If a matching payment exists that doesn't have the server ID, remove it
          for (final dup in duplicates) {
            if (dup.id != item.id.value) {
              final sameMember = (dup.memberName == null && item.memberName.value == null) ||
                  (dup.memberName == item.memberName.value);
              if (sameMember) {
                await (delete(localPayments)..where((t) => t.id.equals(dup.id))).go();
              }
            }
          }

          await into(localPayments).insert(
            item.copyWith(isDirty: const Value(false)),
            mode: InsertMode.insertOrReplace,
          );
        }
      }
    });
  }
}
