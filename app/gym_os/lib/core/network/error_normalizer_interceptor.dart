import 'package:dio/dio.dart';

import 'app_exception.dart';

/// Maps every [DioException] into a typed [AppException] attached via
/// `err.copyWith(error: appException)`.
///
/// **CRITICAL — Offline-first safety:**
/// HTTP 502, 503, 504, [DioExceptionType.connectionError], and
/// [DioExceptionType.connectionTimeout] MUST map to [OfflineException] and
/// MUST NEVER clear auth tokens or trigger logout. This preserves seamless
/// offline behaviour with `SyncEngine` and Drift.
class ErrorNormalizerInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appException = _classify(err);
    handler.next(err.copyWith(error: appException));
  }

  AppException _classify(DioException err) {
    // ── Connection-level failures → OfflineException ──
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const OfflineException(reason: 'Request timed out');
      case DioExceptionType.connectionError:
        return const OfflineException(reason: 'Connection error');
      case DioExceptionType.cancel:
        return const OfflineException(reason: 'Request cancelled');
      default:
        break;
    }

    final response = err.response;
    if (response == null) {
      return const OfflineException(reason: 'No response received');
    }

    final statusCode = response.statusCode ?? 0;
    final body = _parseBody(response);
    final message = _extractMessage(body);
    final traceId = _extractString(body, 'traceId');

    return switch (statusCode) {
      // ── Gateway / infra errors → OfflineException ──
      502 || 503 || 504 =>
        OfflineException(reason: 'Gateway error ($statusCode)'),

      // ── Auth errors ──
      401 => AuthException.sessionExpired(
          message: message,
          traceId: traceId,
        ),
      403 => AuthException.forbidden(
          message: message,
          traceId: traceId,
        ),

      // ── Business-rule errors ──
      400 || 404 || 409 || 422 => BusinessRuleException(
          message: message ?? 'حدث خطأ في البيانات المرسلة',
          errorCode: _extractString(body, 'errorCode'),
          fieldErrors: _extractFieldErrors(body),
          traceId: traceId,
        ),

      // ── Internal server error ──
      500 => ServerFailureException(
          message: message ?? 'حدث خطأ في الخادم، يرجى المحاولة لاحقاً',
          traceId: traceId,
        ),

      // ── Anything else → ServerFailure ──
      _ => ServerFailureException(
          message: message ?? 'خطأ غير متوقع ($statusCode)',
          traceId: traceId,
        ),
    };
  }

  // ── Body parsing helpers ─────────────────────────────────────────────

  /// Safely extracts the response body as a [Map] or wraps plain text.
  Map<String, dynamic>? _parseBody(Response<dynamic> response) {
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    if (data is String && data.isNotEmpty) return {'message': data};
    return null;
  }

  /// Reads the first available human-readable message from the body.
  String? _extractMessage(Map<String, dynamic>? body) {
    if (body == null) return null;
    // Try common server keys in priority order.
    for (final key in const ['message', 'detail', 'title', 'error']) {
      final value = body[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  /// Reads a single string field.
  String? _extractString(Map<String, dynamic>? body, String key) {
    if (body == null) return null;
    final value = body[key];
    return value is String && value.isNotEmpty ? value : null;
  }

  /// Extracts per-field validation errors from an `errors` map.
  ///
  /// Expects `{ "errors": { "phone": ["مطلوب"], ... } }`.
  Map<String, List<String>> _extractFieldErrors(Map<String, dynamic>? body) {
    if (body == null) return const {};
    final errors = body['errors'];
    if (errors is! Map<String, dynamic>) return const {};

    final result = <String, List<String>>{};
    for (final entry in errors.entries) {
      if (entry.value is List) {
        result[entry.key] = (entry.value as List<dynamic>)
            .whereType<String>()
            .toList(growable: false);
      }
    }
    return result;
  }
}
