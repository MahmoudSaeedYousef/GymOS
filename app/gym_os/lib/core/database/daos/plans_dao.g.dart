// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plans_dao.dart';

// ignore_for_file: type=lint
mixin _$PlansDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalPlansTable get localPlans => attachedDatabase.localPlans;
  PlansDaoManager get managers => PlansDaoManager(this);
}

class PlansDaoManager {
  final _$PlansDaoMixin _db;
  PlansDaoManager(this._db);
  $$LocalPlansTableTableManager get localPlans =>
      $$LocalPlansTableTableManager(_db.attachedDatabase, _db.localPlans);
}
