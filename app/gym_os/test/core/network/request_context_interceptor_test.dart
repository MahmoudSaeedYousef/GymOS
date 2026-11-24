import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/core/network/compact_logger_interceptor.dart';
import 'package:gym_os/core/network/request_context_interceptor.dart';

class InMemorySecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  InMemorySecureStorage([Map<String, String>? initialData]) {
    if (initialData != null) {
      _data.addAll(initialData);
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }

  @override
  Future<bool> containsKey({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data.containsKey(key);
  }
}

void main() {
  group('RequestContextInterceptor', () {
    test('injects an 8-char lowercase hex X-Correlation-Id header', () async {
      final storage = InMemorySecureStorage();
      final interceptor = RequestContextInterceptor(storage: storage);

      final options = RequestOptions(path: '/api/members');
      final handler = RequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      final correlationId = options.headers['X-Correlation-Id'];
      expect(correlationId, isNotNull);
      expect(correlationId, isA<String>());
      expect(
        RegExp(r'^[0-9a-f]{8}$').hasMatch(correlationId as String),
        isTrue,
        reason: 'Correlation ID must be exactly 8 lowercase hex characters',
      );
    });

    test('injects Authorization bearer token when token exists in storage', () async {
      final storage = InMemorySecureStorage({'jwt_token': 'test_jwt_token_12345'});
      final interceptor = RequestContextInterceptor(storage: storage);

      final options = RequestOptions(path: '/api/members');
      final handler = RequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], equals('Bearer test_jwt_token_12345'));
    });

    test('omits Authorization header when token is null or empty', () async {
      final storage = InMemorySecureStorage();
      final interceptor = RequestContextInterceptor(storage: storage);

      final options = RequestOptions(path: '/api/members');
      final handler = RequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers.containsKey('Authorization'), isFalse);
    });

    test('injects Accept-Language and optional app version', () async {
      final storage = InMemorySecureStorage();
      final interceptor = RequestContextInterceptor(
        storage: storage,
        acceptLanguage: 'ar-EG',
        appVersion: '2.1.0+42',
      );

      final options = RequestOptions(path: '/api/members');
      final handler = RequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers['Accept-Language'], equals('ar-EG'));
      expect(options.headers['X-App-Version'], equals('2.1.0+42'));
    });
  });

  group('CompactLoggerInterceptor (credential security)', () {
    test('redacts Authorization bearer token to prevent leakage in logs', () {
      final logger = CompactLoggerInterceptor();
      final options = RequestOptions(
        path: '/api/profile',
        headers: {
          'Authorization': 'Bearer sensitive_secret_token_abc',
          'X-Correlation-Id': 'abcdef12',
        },
        data: {
          'password': 'superSecretPassword',
          'token': 'secretJwt',
          'refreshToken': 'secretRefresh',
          'name': 'Captain Ahmed',
        },
      );

      final handler = RequestInterceptorHandler();
      expect(() => logger.onRequest(options, handler), returnsNormally);
    });
  });
}
