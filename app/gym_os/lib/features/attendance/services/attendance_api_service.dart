import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../models/current_inside_member_model.dart';

final attendanceApiProvider = Provider<AttendanceApiService>((ref) {
  return AttendanceApiService(ref.read(dioProvider));
});

class AttendanceApiService {
  final Dio _dio;

  AttendanceApiService(this._dio);

  Future<String> checkIn(String id, {String? memberId, String? notes}) async {
    try {
      final response = await _dio.post(
        '/api/attendance/check-in',
        data: {'id': id, 'memberId': memberId, 'notes': notes},
      );
      return response.data['message'];
    } on DioException catch (e) {
      final errorMsg =
          e.response?.data['message'] ?? 'حدث خطأ أثناء تسجيل الحضور';
      throw Exception(errorMsg);
    }
  }

  Future<List<CurrentInsideMemberModel>> getCurrentInside() async {
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

  Future<String> checkOut(String recordId) async {
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
