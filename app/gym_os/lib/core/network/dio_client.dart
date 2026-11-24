import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      // 10.0.2.2 للـ Android Emulator (ولو iOS Simulator غيرها لـ localhost)
      // baseUrl: 'http://10.0.2.2:5158',
      // baseUrl: 'http://127.0.0.1:5158',
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://gym.orderly365.top',
      ),
      connectTimeout: const Duration(seconds: 100),
      receiveTimeout: const Duration(seconds: 100),
    ),
  );
  // adb -d reverse tcp:5158 tcp:5158
  const storage = FlutterSecureStorage();

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: 'jwt_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ),
  );

  return dio;
});
