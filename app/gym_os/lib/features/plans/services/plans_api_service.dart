import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../models/plan_model.dart';

final plansApiServiceProvider = Provider<PlansApiService>((ref) {
  return PlansApiService(ref.watch(dioProvider));
});

class PlansApiService {
  final Dio _dio;

  PlansApiService(this._dio);

  Future<List<PlanModel>> getPlans({bool activeOnly = false}) async {
    final response = await _dio.get(
      '/api/plans',
      queryParameters: activeOnly ? {'activeOnly': true} : null,
    );
    final data = response.data;
    if (data is List) {
      return data
          .map((item) => PlanModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<PlanModel> upsertPlan({
    String? id,
    required String name,
    String? description,
    required double price,
    required int durationInDays,
    bool isActive = true,
  }) async {
    final response = await _dio.post(
      '/api/plans',
      data: {
        'id': ?id,
        'name': name,
        'description': ?description,
        'price': price,
        'durationInDays': durationInDays,
        'isActive': isActive,
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic> && data['plan'] != null) {
      return PlanModel.fromJson(data['plan'] as Map<String, dynamic>);
    } else if (data is Map<String, dynamic>) {
      return PlanModel.fromJson(data);
    }

    return PlanModel(
      id: id ?? '',
      name: name,
      description: description,
      price: price,
      durationInDays: durationInDays,
      isActive: isActive,
    );
  }

  Future<bool> togglePlanStatus(String id) async {
    final response = await _dio.patch('/api/plans/$id/toggle');
    return response.statusCode == 200 || response.statusCode == 204;
  }
}
