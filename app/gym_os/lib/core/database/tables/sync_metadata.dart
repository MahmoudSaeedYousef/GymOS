import 'package:drift/drift.dart';

/// Key-value metadata store for synchronization tracking (e.g. 'last_pulled_at').
@DataClassName('SyncMetadataData')
class SyncMetadata extends Table {
  /// Metadata key (e.g., 'last_pulled_at').
  TextColumn get key => text()();

  /// Metadata string value.
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
