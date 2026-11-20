import '../services/payment_api_service.dart';

class PaymentItemModel {
  final String id;
  final String memberName;
  final String memberPhone;
  final String planName;
  final double amount;
  final PaymentMethod method;
  final DateTime paymentDate;
  final String? notes;

  const PaymentItemModel({
    required this.id,
    required this.memberName,
    required this.memberPhone,
    required this.planName,
    required this.amount,
    required this.method,
    required this.paymentDate,
    this.notes,
  });

  factory PaymentItemModel.fromJson(Map<String, dynamic> json) {
    return PaymentItemModel(
      id: json['id']?.toString() ?? '',
      memberName: json['memberName']?.toString() ?? '',
      memberPhone: json['memberPhone']?.toString() ?? '',
      planName: json['planName']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      method: PaymentMethodHelper.parseMethod(json['method']),
      paymentDate: _parseUtcToLocal(json['paymentDate']),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'memberName': memberName,
    'memberPhone': memberPhone,
    'planName': planName,
    'amount': amount,
    'method': method.value,
    'paymentDate': paymentDate.toIso8601String(),
    'notes': notes,
  };

  static DateTime _parseUtcToLocal(dynamic raw) {
    if (raw == null) return DateTime.now();
    final str = raw.toString();
    final parsed = DateTime.tryParse(str);
    if (parsed == null) return DateTime.now();
    if (parsed.isUtc) return parsed.toLocal();
    return DateTime.tryParse('${str}Z')?.toLocal() ?? parsed.toLocal();
  }
}

class PaymentsSummaryModel {
  final double totalAmount;
  final double cashTotal;
  final double instaPayTotal;
  final double vodafoneCashTotal;
  final double visaTotal;
  final List<PaymentItemModel> items;

  const PaymentsSummaryModel({
    required this.totalAmount,
    required this.cashTotal,
    required this.instaPayTotal,
    required this.vodafoneCashTotal,
    required this.visaTotal,
    required this.items,
  });

  factory PaymentsSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return PaymentsSummaryModel(
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      cashTotal: (json['cashTotal'] as num?)?.toDouble() ?? 0.0,
      instaPayTotal: (json['instaPayTotal'] as num?)?.toDouble() ?? 0.0,
      vodafoneCashTotal: (json['vodafoneCashTotal'] as num?)?.toDouble() ?? 0.0,
      visaTotal: (json['visaTotal'] as num?)?.toDouble() ?? 0.0,
      items: rawItems
          .map((e) => PaymentItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory PaymentsSummaryModel.empty() => const PaymentsSummaryModel(
    totalAmount: 0.0,
    cashTotal: 0.0,
    instaPayTotal: 0.0,
    vodafoneCashTotal: 0.0,
    visaTotal: 0.0,
    items: [],
  );
}

extension PaymentMethodHelper on PaymentMethod {
  static PaymentMethod parseMethod(dynamic raw) {
    if (raw == null) return PaymentMethod.other;
    if (raw is int) {
      for (final m in PaymentMethod.values) {
        if (m.value == raw) return m;
      }
      return PaymentMethod.other;
    }
    final str = raw.toString().trim().toLowerCase();
    final asInt = int.tryParse(str);
    if (asInt != null) {
      return parseMethod(asInt);
    }
    switch (str) {
      case 'cash':
        return PaymentMethod.cash;
      case 'visa':
        return PaymentMethod.visa;
      case 'instapay':
        return PaymentMethod.instaPay;
      case 'vodafonecash':
        return PaymentMethod.vodafoneCash;
      default:
        return PaymentMethod.other;
    }
  }
}
