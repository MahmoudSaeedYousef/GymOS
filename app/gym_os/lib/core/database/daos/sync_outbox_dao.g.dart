// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_outbox_dao.dart';

// ignore_for_file: type=lint
mixin _$SyncOutboxDaoMixin on DatabaseAccessor<AppDatabase> {
  $SyncOutboxTable get syncOutbox => attachedDatabase.syncOutbox;
  $SyncMetadataTable get syncMetadata => attachedDatabase.syncMetadata;
  $LocalMembersTable get localMembers => attachedDatabase.localMembers;
  $LocalAttendanceTable get localAttendance => attachedDatabase.localAttendance;
  $LocalPaymentsTable get localPayments => attachedDatabase.localPayments;
  SyncOutboxDaoManager get managers => SyncOutboxDaoManager(this);
}

class SyncOutboxDaoManager {
  final _$SyncOutboxDaoMixin _db;
  SyncOutboxDaoManager(this._db);
  $$SyncOutboxTableTableManager get syncOutbox =>
      $$SyncOutboxTableTableManager(_db.attachedDatabase, _db.syncOutbox);
  $$SyncMetadataTableTableManager get syncMetadata =>
      $$SyncMetadataTableTableManager(_db.attachedDatabase, _db.syncMetadata);
  $$LocalMembersTableTableManager get localMembers =>
      $$LocalMembersTableTableManager(_db.attachedDatabase, _db.localMembers);
  $$LocalAttendanceTableTableManager get localAttendance =>
      $$LocalAttendanceTableTableManager(
        _db.attachedDatabase,
        _db.localAttendance,
      );
  $$LocalPaymentsTableTableManager get localPayments =>
      $$LocalPaymentsTableTableManager(_db.attachedDatabase, _db.localPayments);
}
