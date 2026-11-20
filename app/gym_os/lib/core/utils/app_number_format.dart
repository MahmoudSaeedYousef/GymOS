import 'package:intl/intl.dart';

/// Formatter utility ensuring consistent tabular formatting and locale-aware
/// thousands separators (e.g., 3,650) without ad-hoc string manipulations.
class AppNumberFormat {
  /// Formats a numeric value with locale-aware thousands separators.
  static String format(num value, {String? locale, int fractionDigits = 0}) {
    final formatter = NumberFormat.decimalPattern(locale);
    if (fractionDigits > 0) {
      formatter.minimumFractionDigits = fractionDigits;
      formatter.maximumFractionDigits = fractionDigits;
    } else {
      formatter.minimumFractionDigits = 0;
      formatter.maximumFractionDigits = 0;
    }
    return formatter.format(fractionDigits > 0 ? value : value.round());
  }

  /// Formats a numeric value with currency suffix (e.g., "3,650 ج.م" or "3,650 EGP").
  static String formatWithCurrency(
    num value, {
    String? locale,
    String currencySuffix = '',
    int fractionDigits = 0,
  }) {
    final formatted = format(value, locale: locale, fractionDigits: fractionDigits);
    if (currencySuffix.isEmpty) return formatted;
    return '$formatted $currencySuffix';
  }
}
