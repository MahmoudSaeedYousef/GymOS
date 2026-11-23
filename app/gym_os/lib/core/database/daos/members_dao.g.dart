// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'members_dao.dart';

// ignore_for_file: type=lint
mixin _$MembersDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalMembersTable get localMembers => attachedDatabase.localMembers;
  $LocalAttendanceTable get localAttendance => attachedDatabase.localAttendance;
  $LocalPaymentsTable get localPayments => attachedDatabase.localPayments;
  $SyncOutboxTable get syncOutbox => attachedDatabase.syncOutbox;
  MembersDaoManager get managers => MembersDaoManager(this);
}

class MembersDaoManager {
  final _$MembersDaoMixin _db;
  MembersDaoManager(this._db);
  $$LocalMembersTableTableManager get localMembers =>
      $$LocalMembersTableTableManager(_db.attachedDatabase, _db.localMembers);
  $$LocalAttendanceTableTableManager get localAttendance =>
      $$LocalAttendanceTableTableManager(
        _db.attachedDatabase,
        _db.localAttendance,
      );
  $$LocalPaymentsTableTableManager get localPayments =>
      $$LocalPaymentsTableTableManager(_db.attachedDatabase, _db.localPayments);
  $$SyncOutboxTableTableManager get syncOutbox =>
      $$SyncOutboxTableTableManager(_db.attachedDatabase, _db.syncOutbox);
}
