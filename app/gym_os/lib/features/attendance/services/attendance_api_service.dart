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
import '../models/current_inside_member_model.dart';

final attendanceApiProvider = Provider<AttendanceApiService>((ref) {
  return AttendanceApiService(
    ref.watch(dioProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});

class AttendanceApiService {
  final Dio _dio;
  final AppDatabase? _db;
  final SyncEngine? _syncEngine;

  AttendanceApiService(this._dio, [this._db, this._syncEngine]);

  /// Records member check-in locally in Drift + SyncOutbox in <50ms and triggers background sync.
  Future<String> checkIn(String id, {String? memberId, String? notes}) async {
    final targetMemberId = memberId ?? id;

    if (_db != null) {
      final attId = id.isNotEmpty ? id : UuidGenerator.v4();
      final opId = UuidGenerator.v4();
      final now = DateTime.now();

      // Look up member name from local database if available
      final member = await (_db.select(_db.localMembers)
            ..where((t) => t.id.equals(targetMemberId)))
          .getSingleOrNull();
      final memberName = member?.fullName ?? 'Member';
      final memberPhone = member?.phone;

      await _db.attendanceDao.recordCheckInWithOutbox(
        LocalAttendanceCompanion.insert(
          id: attId,
          memberId: Value(targetMemberId),
          memberName: memberName,
          memberPhone: Value(memberPhone),
          checkInTime: now,
          isDropIn: const Value(false),
          isDirty: const Value(true),
        ),
        SyncOutboxCompanion.insert(
          operationId: opId,
          entityType: 'checkin',
          entityId: attId,
          payloadJson: jsonEncode({
            'id': attId,
            'clientId': attId,
            'memberId': targetMemberId,
            'notes': notes,
            'occurredAtUtc': now.toUtc().toIso8601String(),
          }),
          createdAt: now,
        ),
      );

      unawaited(_syncEngine?.syncNow());
      return 'تم تسجيل الحضور بنجاح';
    }

    // Fallback if database is unavailable (e.g. basic mock testing)
    try {
      final response = await _dio.post(
        '/api/attendance/check-in',
        data: {'id': id, 'memberId': memberId, 'notes': notes},
      );
      return response.data['message'] ?? 'تم تسجيل الحضور بنجاح';
    } on DioException catch (e) {
      final errorMsg =
          e.response?.data['message'] ?? 'حدث خطأ أثناء تسجيل الحضور';
      throw Exception(errorMsg);
    }
  }

  /// Returns currently checked-in members from local Drift or API.
  Future<List<CurrentInsideMemberModel>> getCurrentInside() async {
    if (_db != null) {
      final localRows =
          await _db.attendanceDao.watchCurrentlyCheckedIn().first;
      if (localRows.isNotEmpty) {
        final memberIds = localRows
            .map((a) => a.memberId)
            .where((id) => id != null && id.isNotEmpty)
            .cast<String>()
            .toSet();

        Map<String, String?> photoMap = {};
        if (memberIds.isNotEmpty) {
          final members = await (_db.select(_db.localMembers)
                ..where((t) => t.id.isIn(memberIds)))
              .get();
          photoMap = {
            for (final m in members) m.id: m.photoUrl,
          };
        }

        return localRows
            .map((a) => CurrentInsideMemberModel(
                  recordId: a.id,
                  memberId: a.memberId ?? '',
                  fullName: a.memberName,
                  phoneNumber: a.memberPhone ?? '',
                  checkInTime: a.checkInTime,
                  photoUrl: a.memberId != null ? photoMap[a.memberId] : null,
                ))
            .toList();
      }
    }

    try {
      final response = await _dio.get('/api/attendance/current-inside');
      final data = response.data;
      if (data is List) {
        return data
            .map((item) => CurrentInsideMemberModel.fromJson(item))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      final errorMsg =
          e.response?.data['message'] ?? 'تعذر جلب قائمة المتواجدين حالياً';
      throw Exception(errorMsg);
    }
  }

  /// Records member check-out locally in Drift + SyncOutbox and triggers background sync.
  Future<String> checkOut(String recordId) async {
    if (_db != null) {
      final now = DateTime.now();
      final opId = UuidGenerator.v4();

      await _db.attendanceDao.recordCheckOutWithOutbox(
        recordId,
        now,
        SyncOutboxCompanion.insert(
          operationId: opId,
          entityType: 'checkout',
          entityId: recordId,
          payloadJson: jsonEncode({
            'attendanceId': recordId,
            'recordId': recordId,
            'occurredAtUtc': now.toUtc().toIso8601String(),
          }),
          createdAt: now,
        ),
      );

      unawaited(_syncEngine?.syncNow());
      return 'تم تسجيل الخروج بنجاح';
    }

    try {
      final response = await _dio.post('/api/attendance/$recordId/check-out');
      return response.data['message'] ?? 'تم تسجيل الخروج بنجاح';
    } on DioException catch (e) {
      final errorMsg =
          e.response?.data['message'] ?? 'حدث خطأ أثناء تسجيل الخروج';
      throw Exception(errorMsg);
    }
  }
}
