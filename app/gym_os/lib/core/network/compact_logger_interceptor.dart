import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Concise request/response logger active **only** in debug mode.
///
/// Format: `[METHOD PATH -> STATUS (ms) ref:correlationId]`
///
/// Redacts `Authorization` headers and sensitive body fields
/// (`password`, `token`, `refreshToken`) to prevent credential leakage.
class CompactLoggerInterceptor extends Interceptor {
  /// Sensitive header keys (case-insensitive comparison).
  static const _redactedHeaders = {'authorization'};

  /// Sensitive body field keys.
  static const _sensitiveFields = {'password', 'token', 'refreshToken'};

  // ── Helpers ───────────────────────────────────────────────────────────

  String _path(RequestOptions options) {
    final uri = options.uri;
    final path = uri.path;
    final query = uri.query;
    return query.isEmpty ? path : '$path?$query';
  }

  String _correlationId(RequestOptions options) =>
      (options.headers['X-Correlation-Id'] as String?) ?? '--------';

  int _elapsed(RequestOptions options) {
    final sent = options.extra['_sentAt'] as int?;
    if (sent == null) return -1;
    return DateTime.now().millisecondsSinceEpoch - sent;
  }

  Map<String, dynamic> _safeHeaders(Map<String, dynamic> headers) {
    return headers.map((key, value) {
      if (_redactedHeaders.contains(key.toLowerCase())) {
        return MapEntry(key, '***');
      }
      return MapEntry(key, value);
    });
  }

  dynamic _redactBody(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data.map((key, value) {
        if (_sensitiveFields.contains(key)) {
          return MapEntry(key, '***');
        }
        return MapEntry(key, value);
      });
    }
    return data;
  }

  // ── Interceptor overrides ────────────────────────────────────────────

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      options.extra['_sentAt'] = DateTime.now().millisecondsSinceEpoch;
      final redactedHeaders = _safeHeaders(options.headers);
      final redactedBody = _redactBody(options.data);
      dev.log(
        '→ ${options.method} ${_path(options)} '
        'headers=$redactedHeaders '
        'body=$redactedBody',
        name: 'HTTP',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      final ms = _elapsed(response.requestOptions);
      final ref = _correlationId(response.requestOptions);
      dev.log(
        '← ${response.requestOptions.method} '
        '${_path(response.requestOptions)} -> '
        '${response.statusCode} '
        '(${ms}ms) ref:$ref',
        name: 'HTTP',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final ms = _elapsed(err.requestOptions);
      final ref = _correlationId(err.requestOptions);
      final status = err.response?.statusCode ?? err.type.name;
      dev.log(
        '✕ ${err.requestOptions.method} '
        '${_path(err.requestOptions)} -> '
        '$status '
        '(${ms}ms) ref:$ref',
        name: 'HTTP',
      );
    }
    handler.next(err);
  }
}
