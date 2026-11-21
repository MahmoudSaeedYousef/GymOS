import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/core/database/app_database.dart';
import 'package:gym_os/core/database/database_provider.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('MembersDao Tests', () {
    test('insertLocalMemberWithOutbox atomically creates dirty member and outbox entry', () async {
      final now = DateTime.now();
      const memberId = 'member-uuid-1';
      const opId = 'op-uuid-1';

      final member = LocalMembersCompanion.insert(
        id: memberId,
        fullName: 'Captain America',
        phone: '01011112222',
        updatedAt: now,
      );

      final outbox = SyncOutboxCompanion.insert(
        operationId: opId,
        entityType: 'member_create',
        entityId: memberId,
        payloadJson: '{"fullName":"Captain America"}',
        createdAt: now,
      );

      await db.membersDao.insertLocalMemberWithOutbox(member, outbox);

      // Verify member row
      final storedMember = await (db.select(db.localMembers)
            ..where((t) => t.id.equals(memberId)))
          .getSingle();
      expect(storedMember.fullName, 'Captain America');
      expect(storedMember.isDirty, isTrue);

      // Verify outbox entry
      final storedOutbox = await (db.select(db.syncOutbox)
            ..where((t) => t.operationId.equals(opId)))
          .getSingle();
      expect(storedOutbox.entityId, memberId);
      expect(storedOutbox.status, 'pending');
      expect(storedOutbox.retryCount, 0);
    });

    test('upsertMembersFromServer does NOT overwrite rows with isDirty == true', () async {
      final now = DateTime.now();
      const memberId = 'member-uuid-dirty';

      // 1. Insert dirty member locally
      await db.into(db.localMembers).insert(
            LocalMembersCompanion.insert(
              id: memberId,
              fullName: 'Local Unsynced Name',
              phone: '01000000000',
              updatedAt: now,
              isDirty: const Value(true),
            ),
          );

      // 2. Server sends update for the same member
      final serverItems = [
        LocalMembersCompanion.insert(
          id: memberId,
          fullName: 'Server Overwrite Attempt',
          phone: '01099999999',
          updatedAt: now.add(const Duration(hours: 1)),
        ),
      ];

      await db.membersDao.upsertMembersFromServer(serverItems);

      // 3. Stored row must retain local unsynced edits and isDirty == true
      final member = await (db.select(db.localMembers)
            ..where((t) => t.id.equals(memberId)))
          .getSingle();
      expect(member.fullName, 'Local Unsynced Name');
      expect(member.phone, '01000000000');
      expect(member.isDirty, isTrue);
    });

    test('upsertMembersFromServer updates clean rows (isDirty == false)', () async {
      final now = DateTime.now();
      const memberId = 'member-uuid-clean';

      // 1. Insert clean member locally
      await db.into(db.localMembers).insert(
            LocalMembersCompanion.insert(
              id: memberId,
              fullName: 'Initial Clean Name',
              phone: '01000000000',
              updatedAt: now,
              isDirty: const Value(false),
            ),
          );

      // 2. Server sends update
      final serverItems = [
        LocalMembersCompanion.insert(
          id: memberId,
          fullName: 'Updated From Server',
          phone: '01088888888',
          updatedAt: now.add(const Duration(hours: 1)),
        ),
      ];

      await db.membersDao.upsertMembersFromServer(serverItems);

      // 3. Row must reflect server data and remain isDirty == false
      final member = await (db.select(db.localMembers)
            ..where((t) => t.id.equals(memberId)))
          .getSingle();
      expect(member.fullName, 'Updated From Server');
      expect(member.phone, '01088888888');
      expect(member.isDirty, isFalse);
    });

    test('upsertMembersFromServer inserts new rows with isDirty == false', () async {
      final now = DateTime.now();
      const memberId = 'member-uuid-new';

      final serverItems = [
        LocalMembersCompanion.insert(
          id: memberId,
          fullName: 'Brand New Server Member',
          phone: '01077777777',
          updatedAt: now,
        ),
      ];

      await db.membersDao.upsertMembersFromServer(serverItems);

      final member = await (db.select(db.localMembers)
            ..where((t) => t.id.equals(memberId)))
          .getSingle();
      expect(member.fullName, 'Brand New Server Member');
      expect(member.isDirty, isFalse);
    });

    test('watchAllMembers emits members sorted alphabetically by fullName', () async {
      final now = DateTime.now();
      await db.into(db.localMembers).insert(
            LocalMembersCompanion.insert(
              id: 'm-2',
              fullName: 'Zara Member',
              phone: '0102',
              updatedAt: now,
            ),
          );
      await db.into(db.localMembers).insert(
            LocalMembersCompanion.insert(
              id: 'm-1',
              fullName: 'Adam Member',
              phone: '0101',
              updatedAt: now,
            ),
          );

      final list = await db.membersDao.watchAllMembers().first;
      expect(list.length, 2);
      expect(list[0].fullName, 'Adam Member');
      expect(list[1].fullName, 'Zara Member');
    });
  });

  group('SyncOutboxDao Tests', () {
    test('markCompleted deletes outbox entry and clears isDirty on local member', () async {
      final now = DateTime.now();
      const memberId = 'member-sync-1';
      const opId = 'op-sync-1';

      // 1. Insert dirty member + outbox
      await db.membersDao.insertLocalMemberWithOutbox(
        LocalMembersCompanion.insert(
          id: memberId,
          fullName: 'Sync Me',
          phone: '01012345678',
          updatedAt: now,
        ),
        SyncOutboxCompanion.insert(
          operationId: opId,
          entityType: 'member_create',
          entityId: memberId,
          payloadJson: '{}',
          createdAt: now,
        ),
      );

      final pending = await db.syncOutboxDao.getPendingOperations();
      expect(pending.length, 1);
      final outboxId = pending.first.id;

      // 2. Mark completed
      await db.syncOutboxDao.markCompleted(outboxId);

      // 3. Outbox row must be deleted
      final remainingOutbox = await db.syncOutboxDao.getPendingOperations();
      expect(remainingOutbox, isEmpty);

      // 4. Local member row must have isDirty == false
      final updatedMember = await (db.select(db.localMembers)
            ..where((t) => t.id.equals(memberId)))
          .getSingle();
      expect(updatedMember.isDirty, isFalse);
    });

    test('markCompleted deletes outbox entry and clears isDirty on attendance', () async {
      final now = DateTime.now();
      const attendanceId = 'att-sync-1';
      const opId = 'op-att-1';

      await db.attendanceDao.recordCheckInWithOutbox(
        LocalAttendanceCompanion.insert(
          id: attendanceId,
          memberName: 'Attending Member',
          checkInTime: now,
        ),
        SyncOutboxCompanion.insert(
          operationId: opId,
          entityType: 'checkin',
          entityId: attendanceId,
          payloadJson: '{}',
          createdAt: now,
        ),
      );

      final pending = await db.syncOutboxDao.getPendingOperations();
      final outboxId = pending.first.id;

      await db.syncOutboxDao.markCompleted(outboxId);

      final remainingOutbox = await db.syncOutboxDao.getPendingOperations();
      expect(remainingOutbox, isEmpty);

      final updatedAttendance = await (db.select(db.localAttendance)
            ..where((t) => t.id.equals(attendanceId)))
          .getSingle();
      expect(updatedAttendance.isDirty, isFalse);
    });

    test('getPendingOperations returns items in strict FIFO order by id ASC', () async {
      final now = DateTime.now();

      await db.into(db.syncOutbox).insert(
            SyncOutboxCompanion.insert(
              operationId: 'op-1',
              entityType: 'type1',
              entityId: 'id1',
              payloadJson: '{}',
              createdAt: now,
            ),
          );
      await db.into(db.syncOutbox).insert(
            SyncOutboxCompanion.insert(
              operationId: 'op-2',
              entityType: 'type2',
              entityId: 'id2',
              payloadJson: '{}',
              createdAt: now,
            ),
          );

      final ops = await db.syncOutboxDao.getPendingOperations();
      expect(ops.length, 2);
      expect(ops[0].operationId, 'op-1');
      expect(ops[1].operationId, 'op-2');
      expect(ops[0].id < ops[1].id, isTrue);
    });

    test('markSyncing updates status to syncing', () async {
      final now = DateTime.now();
      final id = await db.into(db.syncOutbox).insert(
            SyncOutboxCompanion.insert(
              operationId: 'op-syncing',
              entityType: 'test',
              entityId: 'id',
              payloadJson: '{}',
              createdAt: now,
            ),
          );

      await db.syncOutboxDao.markSyncing(id);

      final row = await (db.select(db.syncOutbox)..where((t) => t.id.equals(id))).getSingle();
      expect(row.status, 'syncing');
    });

    test('markFailed increments retryCount and resets to pending if retry < 5', () async {
      final now = DateTime.now();
      final id = await db.into(db.syncOutbox).insert(
            SyncOutboxCompanion.insert(
              operationId: 'op-retry',
              entityType: 'test',
              entityId: 'id',
              payloadJson: '{}',
              createdAt: now,
            ),
          );

      await db.syncOutboxDao.markFailed(id, 'Socket timeout');

      var row = await (db.select(db.syncOutbox)..where((t) => t.id.equals(id))).getSingle();
      expect(row.retryCount, 1);
      expect(row.status, 'pending');
      expect(row.lastError, 'Socket timeout');

      // Fail 4 more times (total 5)
      for (int i = 0; i < 4; i++) {
        await db.syncOutboxDao.markFailed(id, 'Fail $i');
      }

      row = await (db.select(db.syncOutbox)..where((t) => t.id.equals(id))).getSingle();
      expect(row.retryCount, 5);
      expect(row.status, 'failed');
      expect(row.lastError, 'Fail 3');
    });

    test('watchPendingCount tracks pending outbox count', () async {
      final now = DateTime.now();

      expect(await db.syncOutboxDao.watchPendingCount().first, 0);

      await db.into(db.syncOutbox).insert(
            SyncOutboxCompanion.insert(
              operationId: 'op-count-1',
              entityType: 'test',
              entityId: 'id',
              payloadJson: '{}',
              createdAt: now,
            ),
          );

      expect(await db.syncOutboxDao.watchPendingCount().first, 1);
    });

    test('getMetadata and setMetadata persist sync timestamps correctly', () async {
      expect(await db.syncOutboxDao.getMetadata('last_pulled_at'), isNull);

      const timestamp = '2026-11-20T20:00:00Z';
      await db.syncOutboxDao.setMetadata('last_pulled_at', timestamp);

      expect(await db.syncOutboxDao.getMetadata('last_pulled_at'), timestamp);

      const updatedTimestamp = '2026-11-20T21:00:00Z';
      await db.syncOutboxDao.setMetadata('last_pulled_at', updatedTimestamp);
      expect(await db.syncOutboxDao.getMetadata('last_pulled_at'), updatedTimestamp);
    });
  });

  group('PlansDao Tests', () {
    test('watchActivePlans returns active plans and replaceAllPlans updates set', () async {
      final now = DateTime.now();
      final plans = [
        LocalPlansCompanion.insert(
          id: 'p-1',
          name: 'Monthly Gold',
          price: 500.0,
          durationDays: 30,
          isActive: const Value(true),
          updatedAt: now,
        ),
        LocalPlansCompanion.insert(
          id: 'p-2',
          name: 'Old Archival Plan',
          price: 200.0,
          durationDays: 30,
          isActive: const Value(false),
          updatedAt: now,
        ),
      ];

      await db.plansDao.replaceAllPlans(plans);

      final active = await db.plansDao.watchActivePlans().first;
      expect(active.length, 1);
      expect(active.first.name, 'Monthly Gold');
    });
  });

  group('AttendanceDao Tests', () {
    test('recordCheckInWithOutbox and recordCheckOutWithOutbox', () async {
      final now = DateTime.now();
      const attId = 'att-1';
      const opId = 'op-checkin-1';

      await db.attendanceDao.recordCheckInWithOutbox(
        LocalAttendanceCompanion.insert(
          id: attId,
          memberName: 'Hulk',
          checkInTime: now,
        ),
        SyncOutboxCompanion.insert(
          operationId: opId,
          entityType: 'checkin',
          entityId: attId,
          payloadJson: '{}',
          createdAt: now,
        ),
      );

      final inside = await db.attendanceDao.watchCurrentlyCheckedIn().first;
      expect(inside.length, 1);
      expect(inside.first.memberName, 'Hulk');
      expect(inside.first.isDirty, isTrue);

      // Now check out
      final checkOutTime = now.add(const Duration(hours: 1));
      await db.attendanceDao.recordCheckOutWithOutbox(
        attId,
        checkOutTime,
        SyncOutboxCompanion.insert(
          operationId: 'op-checkout-1',
          entityType: 'checkout',
          entityId: attId,
          payloadJson: '{}',
          createdAt: checkOutTime,
        ),
      );

      final insideAfter = await db.attendanceDao.watchCurrentlyCheckedIn().first;
      expect(insideAfter, isEmpty);

      final today = await db.attendanceDao
          .watchTodayAttendance(
            now.subtract(const Duration(minutes: 5)),
            now.add(const Duration(hours: 2)),
          )
          .first;
      expect(today.length, 1);
      expect(today.first.checkOutTime, isNotNull);
      expect(
        today.first.checkOutTime!.millisecondsSinceEpoch ~/ 1000,
        checkOutTime.millisecondsSinceEpoch ~/ 1000,
      );
    });
  });

  group('PaymentsDao Tests', () {
    test('insertPaymentWithOutbox and watchPaymentsInRange', () async {
      final now = DateTime.now();
      const paymentId = 'pay-1';

      await db.paymentsDao.insertPaymentWithOutbox(
        LocalPaymentsCompanion.insert(
          id: paymentId,
          amountPaid: 600.0,
          method: 1, // Cash
          type: 1, // Subscription
          createdAt: now,
        ),
        SyncOutboxCompanion.insert(
          operationId: 'op-pay-1',
          entityType: 'payment_create',
          entityId: paymentId,
          payloadJson: '{}',
          createdAt: now,
        ),
      );

      final payments = await db.paymentsDao
          .watchPaymentsInRange(
            now.subtract(const Duration(minutes: 1)),
            now.add(const Duration(minutes: 1)),
          )
          .first;

      expect(payments.length, 1);
      expect(payments.first.amountPaid, 600.0);
      expect(payments.first.isDirty, isTrue);
    });

    test('reconcilePaymentId replaces local temporary ID and keeps single row', () async {
      final now = DateTime.now();
      const localId = 'temp-local-pay-id';
      const serverId = 'server-pay-id-xyz';

      await db.into(db.localPayments).insert(
        LocalPaymentsCompanion.insert(
          id: localId,
          amountPaid: 100.0,
          method: 1,
          type: 3,
          createdAt: now,
          isDirty: const Value(false),
        ),
      );

      await db.paymentsDao.reconcilePaymentId(localId, serverId);

      final payments = await db.select(db.localPayments).get();
      expect(payments.length, 1);
      expect(payments.first.id, serverId);
      expect(payments.first.isDirty, isFalse);
    });

    test('upsertPaymentsFromServer deduplicates temporary clean payment row', () async {
      final now = DateTime.now();
      const localId = 'temp-local-pay-123';
      const serverId = 'server-pay-456';

      await db.into(db.localPayments).insert(
        LocalPaymentsCompanion.insert(
          id: localId,
          memberName: const Value('DropIn Guest'),
          amountPaid: 50.0,
          method: 1,
          type: 3,
          createdAt: now,
          isDirty: const Value(false),
        ),
      );

      await db.paymentsDao.upsertPaymentsFromServer([
        LocalPaymentsCompanion.insert(
          id: serverId,
          memberName: const Value('DropIn Guest'),
          amountPaid: 50.0,
          method: 1,
          type: 1,
          createdAt: now,
          isDirty: const Value(false),
        ),
      ]);

      final allPayments = await db.select(db.localPayments).get();
      expect(allPayments.length, 1);
      expect(allPayments.first.id, serverId);
    });
  });

  group('Riverpod Providers Tests', () {
    test('appDatabaseProvider creates and disposes AppDatabase', () {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(AppDatabase(NativeDatabase.memory())),
        ],
      );

      final localDb = container.read(appDatabaseProvider);
      expect(localDb, isNotNull);
      expect(container.read(membersDaoProvider), isNotNull);
      expect(container.read(plansDaoProvider), isNotNull);
      expect(container.read(attendanceDaoProvider), isNotNull);
      expect(container.read(paymentsDaoProvider), isNotNull);
      expect(container.read(syncOutboxDaoProvider), isNotNull);

      container.dispose();
    });
  });
}
