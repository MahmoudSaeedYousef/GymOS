import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../l10n/app_localizations.dart';
import '../models/payment_models.dart';

// Enum مطابق للباك إند
enum PaymentMethod {
  cash(1, 'كاش'),
  visa(2, 'فيزا'),
  instaPay(3, 'إنستاباي'),
  vodafoneCash(4, 'فودافون كاش'),
  other(5, 'أخرى');

  final int value;
  final String label;
  const PaymentMethod(this.value, this.label);

  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case PaymentMethod.cash:
        return l10n.paymentCash;
      case PaymentMethod.visa:
        return l10n.paymentVisa;
      case PaymentMethod.instaPay:
        return l10n.paymentInstaPay;
      case PaymentMethod.vodafoneCash:
        return l10n.paymentVodafoneCash;
      case PaymentMethod.other:
        return l10n.paymentOther;
    }
  }
}

final paymentApiProvider = Provider<PaymentApiService>((ref) {
  return PaymentApiService(ref.read(dioProvider));
});

class PaymentApiService {
  final Dio _dio;

  PaymentApiService(this._dio);

  Future<PaymentsSummaryModel> getPayments({String period = 'month'}) async {
    try {
      final response = await _dio.get(
        '/api/payments',
        queryParameters: {'period': period},
      );
      if (response.data is Map<String, dynamic>) {
        return PaymentsSummaryModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      return PaymentsSummaryModel.empty();
    } on DioException catch (e) {
      final errorMsg =
          e.response?.data['message'] ?? 'تعذر جلب سجل المدفوعات والإيرادات';
      throw Exception(errorMsg);
    }
  }

  Future<String> renewSubscription({
    required String memberId,
    required String planId,
    required int paymentMethod,
    required double amountPaid,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        '/api/payments/renew',
        data: {
          'memberId': memberId,
          'planId': planId,
          'paymentMethod': paymentMethod,
          'amountPaid': amountPaid,
          'notes': notes,
        },
      );
      return response.data['message'];
    } on DioException catch (e) {
      final errorMsg =
          e.response?.data['message'] ?? 'حدث خطأ أثناء تجديد الاشتراك';
      throw Exception(errorMsg);
    }
  }
}
