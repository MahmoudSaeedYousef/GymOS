import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Injects contextual headers into every outgoing request:
///
/// * `Authorization: Bearer <token>` when a JWT is stored.
/// * `Accept-Language` (defaults to `ar`).
/// * `X-Correlation-Id` — unique 8-char hex ID per request for tracing.
/// * `X-App-Version` — if configured via [appVersion].
class RequestContextInterceptor extends Interceptor {
  RequestContextInterceptor({
    FlutterSecureStorage? storage,
    this.acceptLanguage = 'ar',
    this.appVersion,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// BCP-47 language tag sent in `Accept-Language`.
  final String acceptLanguage;

  /// Optional app version string (e.g. `1.2.0+42`).
  final String? appVersion;

  static final Random _random = Random.secure();

  /// Generates an 8-character lowercase hex correlation ID.
  static String _correlationId() {
    final bytes = List<int>.generate(4, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Bearer token
    final token = await _storage.read(key: 'jwt_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Accept-Language
    options.headers['Accept-Language'] = acceptLanguage;

    // Correlation ID
    options.headers['X-Correlation-Id'] = _correlationId();

    // App version (if configured)
    if (appVersion != null) {
      options.headers['X-App-Version'] = appVersion;
    }

    handler.next(options);
  }
}
