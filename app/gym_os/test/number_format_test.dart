import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/core/utils/app_number_format.dart';

void main() {
  group('AppNumberFormat tests', () {
    test('formats integers with thousands separators in en locale', () {
      expect(AppNumberFormat.format(3650, locale: 'en'), equals('3,650'));
      expect(AppNumberFormat.format(1000000, locale: 'en'), equals('1,000,000'));
      expect(AppNumberFormat.format(0, locale: 'en'), equals('0'));
    });

    test('formats fraction digits accurately', () {
      expect(
        AppNumberFormat.format(1234.56, locale: 'en', fractionDigits: 2),
        equals('1,234.56'),
      );
    });

    test('formats with currency suffix cleanly', () {
      expect(
        AppNumberFormat.formatWithCurrency(3650, locale: 'en', currencySuffix: 'EGP'),
        equals('3,650 EGP'),
      );
    });
  });
}
