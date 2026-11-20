import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../models/dashboard_stats_model.dart';
import '../models/drop_in_visit_models.dart';

final dashboardApiServiceProvider = Provider<DashboardApiService>((ref) {
  return DashboardApiService(ref.watch(dioProvider));
});

class DashboardApiService {
  final Dio _dio;

  DashboardApiService(this._dio);

  Future<DashboardStatsModel> getStats() async {
    try {
      final response = await _dio.get('/api/dashboard/stats');
      if (response.data is Map<String, dynamic>) {
        return DashboardStatsModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Invalid dashboard stats response format');
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? 'Failed to load dashboard statistics';
      throw Exception(errorMsg);
    }
  }

  Future<DropInVisitResult> recordDropInVisit(RecordDropInRequest request) async {
    try {
      final response = await _dio.post(
        '/api/visits/drop-in',
        data: request.toJson(),
      );
      if (response.data is Map<String, dynamic>) {
        return DropInVisitResult.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Invalid drop-in visit response format');
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? 'Failed to record drop-in visit';
      throw Exception(errorMsg);
    }
  }
}
