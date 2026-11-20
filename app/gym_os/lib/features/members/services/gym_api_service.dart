import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../models/member_model.dart';
import '../models/plan_model.dart';

final gymApiServiceProvider = Provider<GymApiService>((ref) {
  return GymApiService(ref.watch(dioProvider));
});

typedef MembersApiService = GymApiService;
final membersApiServiceProvider = gymApiServiceProvider;

class GymApiService {
  final Dio _dio;
  GymApiService(this._dio);

  Future<List<PlanModel>> getPlans() async {
    final res = await _dio.get('/api/gym/plans');
    return (res.data as List).map((e) => PlanModel.fromJson(e)).toList();
  }

  Future<PagedMembersResponse> getMembers({
    String? search,
    String? cursor,
    int pageSize = 20,
    String? filter,
    String? sortBy,
  }) async {
    final res = await _dio.get(
      '/api/gym/members',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'cursor': ?cursor,
        'pageSize': pageSize,
        'filter': ?filter,
        'sortBy': ?sortBy,
      },
    );
    return PagedMembersResponse.fromJson(res.data);
  }

  Future<void> createMember({
    required String fullName,
    required String phoneNumber,
    String? planId,
    int? method,
    double? amountPaid,
  }) async {
    await _dio.post(
      '/api/gym/members',
      data: {
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'planId': ?planId,
        'method': ?method,
        'amountPaid': ?amountPaid,
      },
    );
  }
}
