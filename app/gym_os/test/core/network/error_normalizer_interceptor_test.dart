import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/core/network/app_exception.dart';
import 'package:gym_os/core/network/error_normalizer_interceptor.dart';

void main() {
  group('ErrorNormalizerInterceptor', () {
    late ErrorNormalizerInterceptor interceptor;

    setUp(() {
      interceptor = ErrorNormalizerInterceptor();
    });

    DioException createDioException({
      int? statusCode,
      dynamic data,
      DioExceptionType type = DioExceptionType.badResponse,
    }) {
      final requestOptions = RequestOptions(path: '/test');
      final response = statusCode != null
          ? Response<dynamic>(
              requestOptions: requestOptions,
              statusCode: statusCode,
              data: data,
            )
          : null;

      return DioException(
        requestOptions: requestOptions,
        response: response,
        type: type,
      );
    }

    AppException normalize(DioException dioException) {
      DioException? capturedException;

      // Interceptor calls handler.next(err.copyWith(error: appException))
      interceptor.onError(
        dioException,
        ErrorInterceptorHandlerWrapper((nextErr) {
          capturedException = nextErr;
        }),
      );

      expect(capturedException, isNotNull);
      expect(capturedException!.error, isA<AppException>());
      return capturedException!.error as AppException;
    }

    group('BusinessRuleException mapping (400, 409)', () {
      test('maps 400 with Arabic message and traceId preserving both', () {
        const arabicMessage = 'بيانات العضو غير مكتملة أو رقم الهاتف غير صالح';
        const traceId = 'trace-400-abc-123';

        final dioError = createDioException(
          statusCode: 400,
          data: {
            'message': arabicMessage,
            'errorCode': 'INVALID_MEMBER_DATA',
            'traceId': traceId,
            'errors': {
              'phone': ['رقم الهاتف مطلوب', 'صيغة الرقم غير صحيحة'],
            },
          },
        );

        final result = normalize(dioError);

        expect(result, isA<BusinessRuleException>());
        final businessEx = result as BusinessRuleException;
        expect(businessEx.message, equals(arabicMessage));
        expect(businessEx.traceId, equals(traceId));
        expect(businessEx.errorCode, equals('INVALID_MEMBER_DATA'));
        expect(businessEx.fieldErrors['phone'], contains('رقم الهاتف مطلوب'));
      });

      test('maps 409 conflict with Arabic message and traceId preserving both', () {
        const arabicMessage = 'رقم الهاتف مسجل بالفعل لعضو آخر';
        const traceId = 'trace-409-conflict-999';

        final dioError = createDioException(
          statusCode: 409,
          data: {
            'message': arabicMessage,
            'errorCode': 'MEMBER_DUPLICATE_PHONE',
            'traceId': traceId,
          },
        );

        final result = normalize(dioError);

        expect(result, isA<BusinessRuleException>());
        final businessEx = result as BusinessRuleException;
        expect(businessEx.message, equals(arabicMessage));
        expect(businessEx.traceId, equals(traceId));
        expect(businessEx.errorCode, equals('MEMBER_DUPLICATE_PHONE'));
      });
    });

    group('OfflineException mapping (502, 503, 504 and connection/timeout)', () {
      test('maps 502 Bad Gateway to OfflineException without clearing credentials', () {
        final dioError = createDioException(statusCode: 502);
        final result = normalize(dioError);

        expect(result, isA<OfflineException>());
        expect((result as OfflineException).reason, contains('502'));
      });

      test('maps 503 Service Unavailable to OfflineException', () {
        final dioError = createDioException(statusCode: 503);
        final result = normalize(dioError);

        expect(result, isA<OfflineException>());
        expect((result as OfflineException).reason, contains('503'));
      });

      test('maps 504 Gateway Timeout to OfflineException', () {
        final dioError = createDioException(statusCode: 504);
        final result = normalize(dioError);

        expect(result, isA<OfflineException>());
        expect((result as OfflineException).reason, contains('504'));
      });

      test('maps connectionError type to OfflineException', () {
        final dioError = createDioException(type: DioExceptionType.connectionError);
        final result = normalize(dioError);

        expect(result, isA<OfflineException>());
        expect((result as OfflineException).reason, equals('Connection error'));
      });

      test('maps connectionTimeout type to OfflineException', () {
        final dioError = createDioException(type: DioExceptionType.connectionTimeout);
        final result = normalize(dioError);

        expect(result, isA<OfflineException>());
        expect((result as OfflineException).reason, equals('Request timed out'));
      });

      test('maps receiveTimeout and sendTimeout to OfflineException', () {
        final recvError = createDioException(type: DioExceptionType.receiveTimeout);
        expect(normalize(recvError), isA<OfflineException>());

        final sendError = createDioException(type: DioExceptionType.sendTimeout);
        expect(normalize(sendError), isA<OfflineException>());
      });

      test('maps null response to OfflineException', () {
        final dioError = createDioException(statusCode: null, type: DioExceptionType.unknown);
        final result = normalize(dioError);

        expect(result, isA<OfflineException>());
      });
    });

    group('ServerFailureException mapping (500)', () {
      test('maps 500 to ServerFailureException preserving Arabic message and traceId', () {
        const arabicMessage = 'خطأ داخلي غير متوقع في الخادم';
        const traceId = 'trace-server-500-xyz';

        final dioError = createDioException(
          statusCode: 500,
          data: {
            'message': arabicMessage,
            'traceId': traceId,
          },
        );

        final result = normalize(dioError);

        expect(result, isA<ServerFailureException>());
        final serverEx = result as ServerFailureException;
        expect(serverEx.message, equals(arabicMessage));
        expect(serverEx.traceId, equals(traceId));
        expect(serverEx.refDisplay, equals('Ref: #$traceId'));
      });

      test('maps 500 without custom body to default Arabic message and optional traceId', () {
        final dioError = createDioException(statusCode: 500);
        final result = normalize(dioError);

        expect(result, isA<ServerFailureException>());
        final serverEx = result as ServerFailureException;
        expect(serverEx.message, equals('حدث خطأ في الخادم، يرجى المحاولة لاحقاً'));
        expect(serverEx.traceId, isNull);
        expect(serverEx.refDisplay, isEmpty);
      });
    });

    group('AuthException mapping (401, 403)', () {
      test('maps 401 Unauthorized to AuthException.sessionExpired', () {
        const traceId = 'trace-401-auth';
        final dioError = createDioException(
          statusCode: 401,
          data: {
            'message': 'الجلسة منتهية، يرجى إعادة تسجيل الدخول',
            'traceId': traceId,
          },
        );

        final result = normalize(dioError);

        expect(result, isA<AuthException>());
        final authEx = result as AuthException;
        expect(authEx.statusCode, equals(401));
        expect(authEx.isSessionExpired, isTrue);
        expect(authEx.isForbidden, isFalse);
        expect(authEx.traceId, equals(traceId));
        expect(authEx.message, equals('الجلسة منتهية، يرجى إعادة تسجيل الدخول'));
      });

      test('maps 403 Forbidden to AuthException.forbidden', () {
        const traceId = 'trace-403-forbidden';
        final dioError = createDioException(
          statusCode: 403,
          data: {
            'message': 'ليس لديك صلاحية لتنفيذ هذا الإجراء',
            'traceId': traceId,
          },
        );

        final result = normalize(dioError);

        expect(result, isA<AuthException>());
        final authEx = result as AuthException;
        expect(authEx.statusCode, equals(403));
        expect(authEx.isSessionExpired, isFalse);
        expect(authEx.isForbidden, isTrue);
        expect(authEx.traceId, equals(traceId));
        expect(authEx.message, equals('ليس لديك صلاحية لتنفيذ هذا الإجراء'));
      });
    });
  });
}

class ErrorInterceptorHandlerWrapper extends ErrorInterceptorHandler {
  final void Function(DioException err) onNext;

  ErrorInterceptorHandlerWrapper(this.onNext);

  @override
  void next(DioException err) {
    onNext(err);
  }
}
