import 'package:drift/drift.dart';

/// Persistent queue for local mutations awaiting backend synchronization.
@DataClassName('SyncOutboxData')
class SyncOutbox extends Table {
  /// Auto-incrementing primary key for strict FIFO processing order.
  IntColumn get id => integer().autoIncrement()();

  /// Client-generated UUID used as X-Idempotency-Key on the backend.
  TextColumn get operationId => text().unique()();

  /// Entity mutation type (e.g., 'member_create', 'member_renew', 'checkin', 'checkout', 'dropin').
  TextColumn get entityType => text()();

  /// Target entity UUID.
  TextColumn get entityId => text()();

  /// Serialized JSON request payload.
  TextColumn get payloadJson => text()();

  /// Synchronization status: 'pending', 'syncing', or 'failed'.
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Number of sync attempts.
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// Last error message encountered during synchronization (nullable).
  TextColumn get lastError => text().nullable()();

  /// Record creation timestamp.
  DateTimeColumn get createdAt => dateTime()();
}
