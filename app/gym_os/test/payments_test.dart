import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/features/payments/providers/payments_provider.dart';

void main() {
  group('Payment Models & Enums', () {
    test('PaymentMethodHelper parses string and int values accurately', () {
      expect(PaymentMethodHelper.parseMethod(1), PaymentMethod.cash);
      expect(PaymentMethodHelper.parseMethod(2), PaymentMethod.visa);
      expect(PaymentMethodHelper.parseMethod(3), PaymentMethod.instaPay);
      expect(PaymentMethodHelper.parseMethod(4), PaymentMethod.vodafoneCash);
      expect(PaymentMethodHelper.parseMethod('cash'), PaymentMethod.cash);
      expect(PaymentMethodHelper.parseMethod('visa'), PaymentMethod.visa);
      expect(PaymentMethodHelper.parseMethod('instapay'), PaymentMethod.instaPay);
      expect(PaymentMethodHelper.parseMethod('vodafonecash'), PaymentMethod.vodafoneCash);
      expect(PaymentMethodHelper.parseMethod('unknown'), PaymentMethod.other);
      expect(PaymentMethodHelper.parseMethod(null), PaymentMethod.other);
    });

    test('PaymentItemModel fromJson and toJson work correctly', () {
      final json = {
        'id': 'pay-123',
        'memberName': 'Ali Hassan',
        'memberPhone': '01012345678',
        'planName': 'Monthly Plan',
        'amount': 500.0,
        'method': 3,
        'paymentDate': '2026-11-19T10:00:00.000Z',
        'notes': 'Paid via InstaPay',
      };

      final item = PaymentItemModel.fromJson(json);

      expect(item.id, 'pay-123');
      expect(item.memberName, 'Ali Hassan');
      expect(item.memberPhone, '01012345678');
      expect(item.planName, 'Monthly Plan');
      expect(item.amount, 500.0);
      expect(item.method, PaymentMethod.instaPay);
      expect(item.notes, 'Paid via InstaPay');

      final serialized = item.toJson();
      expect(serialized['id'], 'pay-123');
      expect(serialized['amount'], 500.0);
      expect(serialized['method'], 3);
    });

    test('PaymentsSummaryModel empty factory returns zeroed totals and empty list', () {
      final empty = PaymentsSummaryModel.empty();
      expect(empty.totalAmount, 0.0);
      expect(empty.cashTotal, 0.0);
      expect(empty.instaPayTotal, 0.0);
      expect(empty.vodafoneCashTotal, 0.0);
      expect(empty.visaTotal, 0.0);
      expect(empty.items, isEmpty);
    });

    test('PaymentsSummaryModel fromJson parses totals and items correctly', () {
      final json = {
        'totalAmount': 1500.0,
        'cashTotal': 500.0,
        'instaPayTotal': 600.0,
        'vodafoneCashTotal': 400.0,
        'visaTotal': 0.0,
        'items': [
          {
            'id': 'pay-1',
            'memberName': 'Member 1',
            'memberPhone': '01000000001',
            'planName': 'Month',
            'amount': 500.0,
            'method': 'cash',
            'paymentDate': '2026-11-19T08:00:00.000Z',
          },
        ],
      };

      final summary = PaymentsSummaryModel.fromJson(json);
      expect(summary.totalAmount, 1500.0);
      expect(summary.cashTotal, 500.0);
      expect(summary.instaPayTotal, 600.0);
      expect(summary.vodafoneCashTotal, 400.0);
      expect(summary.visaTotal, 0.0);
      expect(summary.items.length, 1);
      expect(summary.items.first.memberName, 'Member 1');
    });
  });

  group('Payments Riverpod State Management', () {
    test('paymentsPeriodProvider defaults to month and updates period', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(paymentsPeriodProvider), 'month');

      container.read(paymentsPeriodProvider.notifier).setPeriod('today');
      expect(container.read(paymentsPeriodProvider), 'today');

      container.read(paymentsPeriodProvider.notifier).setPeriod('all');
      expect(container.read(paymentsPeriodProvider), 'all');
    });
  });
}
