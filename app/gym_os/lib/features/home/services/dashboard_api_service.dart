import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/sync/sync_provider.dart';
import '../../../core/utils/uuid_generator.dart';
import '../models/dashboard_stats_model.dart';
import '../models/drop_in_visit_models.dart';

final dashboardApiServiceProvider = Provider<DashboardApiService>((ref) {
  return DashboardApiService(
    ref.watch(dioProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});

class DashboardApiService {
  final Dio _dio;
  final AppDatabase? _db;
  final SyncEngine? _syncEngine;

  DashboardApiService(this._dio, [this._db, this._syncEngine]);

  Future<DashboardStatsModel> getStats() async {
    try {
      final response = await _dio.get('/api/dashboard/stats');
      if (response.data is Map<String, dynamic>) {
        return DashboardStatsModel.fromJson(
            response.data as Map<String, dynamic>);
      }
      throw Exception('Invalid dashboard stats response format');
    } on DioException catch (e) {
      final errorMsg =
          e.response?.data?['message'] ?? 'Failed to load dashboard statistics';
      throw Exception(errorMsg);
    }
  }

  /// Records a drop-in visit locally in Drift + SyncOutbox in <50ms and triggers background sync.
  Future<DropInVisitResult> recordDropInVisit(
      RecordDropInRequest request) async {
    if (_db != null) {
      final attId = UuidGenerator.v4();
      final payId = UuidGenerator.v4();
      final opId = request.operationId.isNotEmpty
          ? request.operationId
          : UuidGenerator.v4();
      final now = DateTime.now();

      await _db.attendanceDao.recordDropInWithOutbox(
        attendance: LocalAttendanceCompanion.insert(
          id: attId,
          memberName: (request.guestName != null &&
                  request.guestName!.trim().isNotEmpty)
              ? request.guestName!.trim()
              : 'Guest / زائر',
          memberPhone: Value(request.guestPhone),
          checkInTime: now,
          isDropIn: const Value(true),
          isDirty: const Value(true),
        ),
        payment: LocalPaymentsCompanion.insert(
          id: payId,
          memberName: Value(request.guestName),
          planId: Value(request.planId),
          amountPaid: request.customAmount,
          method: request.method,
          type: 3, // Drop-in
          createdAt: now,
          isDirty: const Value(true),
        ),
        outboxEntry: SyncOutboxCompanion.insert(
          operationId: opId,
          entityType: 'dropin',
          entityId: attId,
          payloadJson: jsonEncode(request.toJson()
            ..addAll({
              'clientId': attId,
              'attendanceId': attId,
              'paymentId': payId,
              'occurredAtUtc': now.toUtc().toIso8601String(),
            })),
          createdAt: now,
        ),
      );

      unawaited(_syncEngine?.syncNow());

      return DropInVisitResult(
        succeeded: true,
        message: 'تم تسجيل الزيارة بنجاح',
        attendanceId: attId,
        paymentId: payId,
        amountPaid: request.customAmount,
      );
    }

    try {
      final response = await _dio.post(
        '/api/visits/drop-in',
        data: request.toJson(),
      );
      if (response.data is Map<String, dynamic>) {
        return DropInVisitResult.fromJson(
            response.data as Map<String, dynamic>);
      }
      throw Exception('Invalid drop-in visit response format');
    } on DioException catch (e) {
      final errorMsg =
          e.response?.data?['message'] ?? 'Failed to record drop-in visit';
      throw Exception(errorMsg);
    }
  }
}
