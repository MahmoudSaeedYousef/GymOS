/// Typed exception hierarchy for the network layer.
///
/// Every [DioException] is normalised into one of these subtypes by
/// [ErrorNormalizerInterceptor] so that feature-layer code can pattern-match
/// on a small, stable set of failure modes.
sealed class AppException implements Exception {
  const AppException();
}

/// Network-level failures that are safe for Drift offline-first fallback.
///
/// Covers timeouts, connection errors, and gateway errors (502/503/504).
/// **MUST NEVER** clear auth tokens or trigger logout.
final class OfflineException extends AppException {
  const OfflineException({this.reason});

  /// Optional human-readable reason (e.g. "Connection timeout").
  final String? reason;

  @override
  String toString() => 'OfflineException(${reason ?? 'no network'})';
}

/// Business-rule violations returned by the server (400/404/409/422).
final class BusinessRuleException extends AppException {
  const BusinessRuleException({
    required this.message,
    this.errorCode,
    this.fieldErrors = const {},
    this.traceId,
  });

  /// Arabic server message, or a safe fallback.
  final String message;

  /// Machine-readable code (e.g. `MEMBER_DUPLICATE_PHONE`).
  final String? errorCode;

  /// Per-field validation errors (`{ "phone": ["مطلوب"] }`).
  final Map<String, List<String>> fieldErrors;

  /// Correlation / trace ID returned by the server.
  final String? traceId;

  @override
  String toString() =>
      'BusinessRuleException($message, code=$errorCode, traceId=$traceId)';
}

/// Authentication / authorisation failures (401/403).
final class AuthException extends AppException {
  const AuthException._({
    required this.statusCode,
    this.message,
    this.traceId,
  });

  /// Factory for HTTP 401 — expired or invalid session.
  const factory AuthException.sessionExpired({
    String? message,
    String? traceId,
  }) = _SessionExpiredAuth;

  /// Factory for HTTP 403 — authenticated but not permitted.
  const factory AuthException.forbidden({
    String? message,
    String? traceId,
  }) = _ForbiddenAuth;

  final int statusCode;
  final String? message;
  final String? traceId;

  bool get isSessionExpired => statusCode == 401;
  bool get isForbidden => statusCode == 403;

  @override
  String toString() =>
      'AuthException(status=$statusCode, traceId=$traceId)';
}

/// Rate limiting / throttling exception (HTTP 429).
///
/// Carries [retryAfterSeconds] indicating how long the client should wait
/// before retrying the request.
final class RateLimitException extends AppException {
  const RateLimitException({
    required this.retryAfterSeconds,
    this.message,
    this.traceId,
  });

  /// The cooldown duration in seconds before next attempt is allowed.
  final int retryAfterSeconds;

  /// Optional message from server or fallback.
  final String? message;

  /// Correlation / trace ID returned by the server.
  final String? traceId;

  @override
  String toString() =>
      'RateLimitException(retryAfter=$retryAfterSeconds s, message=$message, traceId=$traceId)';
}

final class _SessionExpiredAuth extends AuthException {
  const _SessionExpiredAuth({super.message, super.traceId})
      : super._(statusCode: 401);
}

final class _ForbiddenAuth extends AuthException {
  const _ForbiddenAuth({super.message, super.traceId})
      : super._(statusCode: 403);
}

/// Internal server error (HTTP 500).
final class ServerFailureException extends AppException {
  const ServerFailureException({
    required this.message,
    this.traceId,
  });

  /// User-friendly Arabic message.
  final String message;

  /// Server trace ID surfaced as `Ref: #<traceId>`.
  final String? traceId;

  /// Formatted reference string for user display.
  String get refDisplay =>
      traceId != null ? 'Ref: #$traceId' : '';

  @override
  String toString() =>
      'ServerFailureException($message, traceId=$traceId)';
}
