import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'compact_logger_interceptor.dart';
import 'error_normalizer_interceptor.dart';
import 'request_context_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      // 10.0.2.2 للـ Android Emulator (ولو iOS Simulator غيرها لـ localhost)
      // baseUrl: 'http://10.0.2.2:5158',
      // baseUrl: 'http://127.0.0.1:5158',
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://dev-gym.orderly365.top',
      ),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  // adb -d reverse tcp:5158 tcp:5158

  // ── Interceptor pipeline (order matters) ──
  // 1. Logger captures raw request (debug only).
  if (kDebugMode) {
    dio.interceptors.add(CompactLoggerInterceptor());
  }

  // 2. Inject auth token + contextual headers.
  dio.interceptors.add(RequestContextInterceptor());

  // 3. Normalise errors into typed AppException hierarchy.
  dio.interceptors.add(ErrorNormalizerInterceptor());

  return dio;
});
