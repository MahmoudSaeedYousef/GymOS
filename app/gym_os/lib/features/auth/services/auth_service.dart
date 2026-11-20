import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/dio_client.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(dioProvider));
});

class AuthService {
  final Dio _dio;
  final _storage = const FlutterSecureStorage();

  AuthService(this._dio);

  Future<String> login(String phone, String password) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {'phoneNumber': phone, 'password': password},
      );

      final token = response.data['token'] as String;
      await _storage.write(key: 'jwt_token', value: token);
      return token;
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'فشل تسجيل الدخول، تأكد من البيانات');
    }
  }
}
