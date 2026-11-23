import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/local_attendance.dart';
import '../tables/local_members.dart';
import '../tables/local_payments.dart';
import '../tables/sync_outbox.dart';

part 'members_dao.g.dart';

@DriftAccessor(tables: [LocalMembers, LocalAttendance, LocalPayments, SyncOutbox])
class MembersDao extends DatabaseAccessor<AppDatabase> with _$MembersDaoMixin {
  MembersDao(super.db);

  /// Watches all members ordered alphabetically by full name.
  Stream<List<LocalMember>> watchAllMembers() {
    return (select(localMembers)
          ..orderBy([
            (t) => OrderingTerm(expression: t.fullName, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// Retrieves members who attended today, including guest single-session ("حصة منفردة") check-ins.
  Future<List<LocalMember>> getTodayAttendanceMembers({
    required DateTime todayStart,
    required DateTime todayEnd,
  }) async {
    final attendanceRecords = await (select(localAttendance)
          ..where((t) =>
              t.checkInTime.isBiggerOrEqualValue(todayStart) &
              t.checkInTime.isSmallerOrEqualValue(todayEnd))
          ..orderBy([(t) => OrderingTerm(expression: t.checkInTime, mode: OrderingMode.desc)]))
        .get();

    final result = <LocalMember>[];
    final seenIds = <String>{};

    for (final att in attendanceRecords) {
      if (att.memberId != null && att.memberId!.isNotEmpty) {
        if (!seenIds.add(att.memberId!)) continue;
        final member = await (select(localMembers)
              ..where((t) => t.id.equals(att.memberId!)))
            .getSingleOrNull();
        if (member != null) {
          result.add(member);
        } else {
          // If member record not locally cached, synthesize from attendance
          result.add(
            LocalMember(
              id: att.memberId!,
              fullName: att.memberName,
              phone: att.memberPhone ?? '',
              status: 1,
              isGuest: att.isDropIn,
              planName: att.isDropIn ? 'حصة منفردة' : null,
              gender: 0,
              updatedAt: att.checkInTime,
              isDirty: false,
            ),
          );
        }
      } else {
        // Guest single session (Drop-in without permanent memberId)
        if (!seenIds.add(att.id)) continue;
        result.add(
          LocalMember(
            id: att.id,
            fullName: att.memberName.isNotEmpty ? att.memberName : 'زائر حصة منفردة',
            phone: att.memberPhone ?? '',
            status: 1,
            isGuest: true,
            planName: 'حصة منفردة',
            gender: 0,
            updatedAt: att.checkInTime,
            isDirty: false,
          ),
        );
      }
    }

    return result;
  }

  /// Upserts members received from the server.
  ///
  /// MUST skip overwriting any row where `isDirty == true` so unsynced
  /// local edits are never clobbered. Clean rows (`isDirty == false`) or new
  /// rows are inserted/updated with `isDirty = false`.
  Future<void> upsertMembersFromServer(List<LocalMembersCompanion> items) async {
    if (items.isEmpty) return;

    await transaction(() async {
      for (final item in items) {
        final existing = await (select(localMembers)
              ..where((t) => t.id.equals(item.id.value)))
            .getSingleOrNull();

        if (existing != null) {
          if (existing.isDirty) {
            // Skip overwriting row awaiting local sync
            continue;
          }
          final effectivePhotoUrl = (item.photoUrl.present && item.photoUrl.value != null)
              ? item.photoUrl
              : Value(existing.photoUrl);
          final effectiveGender = item.gender.present
              ? item.gender
              : Value(existing.gender);
          await (update(localMembers)..where((t) => t.id.equals(item.id.value)))
              .write(
            item.copyWith(
              isDirty: const Value(false),
              photoUrl: effectivePhotoUrl,
              gender: effectiveGender,
            ),
          );
        } else {
          await into(localMembers).insert(
            item.copyWith(
              isDirty: const Value(false),
              photoUrl: item.photoUrl.present ? item.photoUrl : const Value(null),
              gender: item.gender.present ? item.gender : const Value(0),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      }
    });
  }

  /// Inserts or replaces a local member with an associated outbox queue entry
  /// inside an atomic database transaction.
  ///
  /// The member is explicitly marked with `isDirty: true`.
  Future<void> insertLocalMemberWithOutbox(
    LocalMembersCompanion member,
    SyncOutboxCompanion outboxEntry, {
    LocalPaymentsCompanion? payment,
  }) async {
    await transaction(() async {
      await into(localMembers).insert(
        member.copyWith(isDirty: const Value(true)),
        mode: InsertMode.insertOrReplace,
      );
      if (payment != null) {
        await into(localPayments).insert(
          payment.copyWith(isDirty: const Value(true)),
          mode: InsertMode.insertOrReplace,
        );
      }
      await into(syncOutbox).insert(outboxEntry);
    });
  }

  /// Atomically records a subscription renewal: updates member's end date,
  /// inserts payment, and queues outbox operation.
  Future<void> renewSubscriptionWithOutbox({
    required String memberId,
    required DateTime newEndDate,
    String? planId,
    String? planName,
    required LocalPaymentsCompanion payment,
    required SyncOutboxCompanion outboxEntry,
  }) async {
    await transaction(() async {
      await (update(localMembers)..where((t) => t.id.equals(memberId))).write(
        LocalMembersCompanion(
          subscriptionEndDate: Value(newEndDate),
          planId: Value(planId),
          planName: Value(planName),
          status: const Value(1),
          isDirty: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await into(localPayments).insert(
        payment.copyWith(isDirty: const Value(true)),
        mode: InsertMode.insertOrReplace,
      );
      await into(syncOutbox).insert(outboxEntry);
    });
  }
}
