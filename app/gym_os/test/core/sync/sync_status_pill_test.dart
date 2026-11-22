import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/core/database/app_database.dart';
import 'package:gym_os/core/database/database_provider.dart';
import 'package:gym_os/core/network/dio_client.dart';
import 'package:gym_os/core/sync/sync_provider.dart';
import 'package:gym_os/core/sync/sync_status_pill.dart';
import 'package:gym_os/core/theme/app_theme.dart';
import 'package:gym_os/l10n/app_localizations.dart';

class TestConnectivity implements Connectivity {
  final StreamController<List<ConnectivityResult>> _controller =
      StreamController<List<ConnectivityResult>>.broadcast();
  List<ConnectivityResult> current = [ConnectivityResult.wifi];

  void setConnectivity(List<ConnectivityResult> results) {
    current = results;
    _controller.add(results);
  }

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => current;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _controller.stream;
}

void main() {
  late AppDatabase db;
  late TestConnectivity testConnectivity;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    testConnectivity = TestConnectivity();
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestPill({
    required ProviderContainer container,
    Locale locale = const Locale('en'),
  }) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.darkTheme(),
        home: const Scaffold(
          body: Center(
            child: SyncStatusPill(),
          ),
        ),
      ),
    );
  }

  testWidgets('SyncStatusPill shows sync icon and tooltip when online and 0 pending items', (tester) async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        connectivityProvider.overrideWithValue(testConnectivity),
        dioProvider.overrideWithValue(Dio()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildTestPill(container: container));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.sync_rounded), findsOneWidget);
    expect(find.byType(Tooltip), findsOneWidget);
    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, 'Synced');
  });

  testWidgets('SyncStatusPill displays Arabic tooltip when locale is Arabic', (tester) async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        connectivityProvider.overrideWithValue(testConnectivity),
        dioProvider.overrideWithValue(Dio()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildTestPill(
      container: container,
      locale: const Locale('ar'),
    ));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.sync_rounded), findsOneWidget);
    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, 'متزامن');
  });

  testWidgets('SyncStatusPill shows badge with count when offline and pending > 0', (tester) async {
    testConnectivity.current = [ConnectivityResult.none];

    // Seed outbox
    await db.into(db.syncOutbox).insert(
          SyncOutboxCompanion.insert(
            operationId: 'op-test-pill',
            entityType: 'checkin',
            entityId: 'att-1',
            payloadJson: '{}',
            createdAt: DateTime.now(),
          ),
        );

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        connectivityProvider.overrideWithValue(testConnectivity),
        dioProvider.overrideWithValue(Dio()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildTestPill(container: container));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, 'Offline • 1 queued');
  });

  testWidgets('SyncStatusPill shows Offline tooltip and dot when offline and pending == 0', (tester) async {
    testConnectivity.current = [ConnectivityResult.none];

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        connectivityProvider.overrideWithValue(testConnectivity),
        dioProvider.overrideWithValue(Dio()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildTestPill(container: container));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, 'Offline');
  });
}
