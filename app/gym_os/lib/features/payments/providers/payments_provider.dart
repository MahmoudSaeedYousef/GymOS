import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_models.dart';
import '../services/payment_api_service.dart';

export '../models/payment_models.dart';
export '../services/payment_api_service.dart';

class PaymentsPeriodNotifier extends Notifier<String> {
  @override
  String build() => 'month';

  void setPeriod(String period) {
    state = period;
  }
}

/// Provider for tracking selected payments period filter ('today', 'month', 'all').
final paymentsPeriodProvider =
    NotifierProvider<PaymentsPeriodNotifier, String>(
  PaymentsPeriodNotifier.new,
);

/// Provider to fetch payments summary & list for the selected period.
final paymentsSummaryProvider =
    FutureProvider.autoDispose<PaymentsSummaryModel>((ref) async {
  final period = ref.watch(paymentsPeriodProvider);
  final api = ref.watch(paymentApiProvider);
  return api.getPayments(period: period);
});
