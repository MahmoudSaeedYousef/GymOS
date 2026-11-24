import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'compact_logger_interceptor.dart';
import 'environment_store.dart';
import 'error_normalizer_interceptor.dart';
import 'request_context_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(serverBaseUrlProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

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
