// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payments_dao.dart';

// ignore_for_file: type=lint
mixin _$PaymentsDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalPaymentsTable get localPayments => attachedDatabase.localPayments;
  $SyncOutboxTable get syncOutbox => attachedDatabase.syncOutbox;
  PaymentsDaoManager get managers => PaymentsDaoManager(this);
}

class PaymentsDaoManager {
  final _$PaymentsDaoMixin _db;
  PaymentsDaoManager(this._db);
  $$LocalPaymentsTableTableManager get localPayments =>
      $$LocalPaymentsTableTableManager(_db.attachedDatabase, _db.localPayments);
  $$SyncOutboxTableTableManager get syncOutbox =>
      $$SyncOutboxTableTableManager(_db.attachedDatabase, _db.syncOutbox);
}
