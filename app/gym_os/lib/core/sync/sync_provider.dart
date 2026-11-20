import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_provider.dart';
import '../network/dio_client.dart';
import 'sync_engine.dart';

export 'sync_engine.dart' show SyncEngine, SyncState, SyncLifecycleObserver;

/// Provider for the [Connectivity] instance.
final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

/// Provider for the singleton [SyncEngine] instance.
final syncEngineProvider = Provider<SyncEngine>((ref) {
  final dio = ref.watch(dioProvider);
  final db = ref.watch(appDatabaseProvider);
  final connectivity = ref.watch(connectivityProvider);

  final engine = SyncEngine(
    dio: dio,
    db: db,
    connectivity: connectivity,
  );

  ref.onDispose(() {
    engine.dispose();
  });

  return engine;
});

/// Lifecycle observer triggering sync on network restore, resume, and timers.
final syncLifecycleObserverProvider = Provider<SyncLifecycleObserver>((ref) {
  final engine = ref.watch(syncEngineProvider);
  final connectivity = ref.watch(connectivityProvider);

  final observer = SyncLifecycleObserver(engine, connectivity);
  observer.start();

  ref.onDispose(() {
    observer.dispose();
  });

  return observer;
});

/// Stream provider for reactive [SyncState].
final syncStateProvider = StreamProvider<SyncState>((ref) {
  final engine = ref.watch(syncEngineProvider);
  return engine.stateStream;
});
