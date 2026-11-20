/// Request payload for recording a single drop-in visit (POST /api/visits/drop-in).
class RecordDropInRequest {
  final String operationId;
  final String? planId;
  final double customAmount;
  final int method;
  final String? guestName;
  final String? guestPhone;
  final String? notes;

  const RecordDropInRequest({
    required this.operationId,
    this.planId,
    required this.customAmount,
    required this.method,
    this.guestName,
    this.guestPhone,
    this.notes,
  });

  String get paymentMethodName {
    switch (method) {
      case 1:
        return 'Cash';
      case 2:
        return 'Visa';
      case 3:
        return 'InstaPay';
      case 4:
        return 'VodafoneCash';
      case 5:
        return 'Other';
      default:
        return 'Cash';
    }
  }

  Map<String, dynamic> toJson() => {
    'operationId': operationId,
    'planId': planId,
    'customAmount': customAmount,
    'method': method,
    'paymentMethod': paymentMethodName,
    'guestName': (guestName != null && guestName!.trim().isNotEmpty) ? guestName!.trim() : null,
    'guestPhone': (guestPhone != null && guestPhone!.trim().isNotEmpty) ? guestPhone!.trim() : null,
    'notes': (notes != null && notes!.trim().isNotEmpty) ? notes!.trim() : null,
  };
}

/// Result returned from recording a drop-in visit.
class DropInVisitResult {
  final bool succeeded;
  final String message;
  final String? paymentId;
  final String? attendanceId;
  final String? memberId;
  final double amountPaid;

  const DropInVisitResult({
    required this.succeeded,
    required this.message,
    this.paymentId,
    this.attendanceId,
    this.memberId,
    this.amountPaid = 0.0,
  });

  factory DropInVisitResult.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return DropInVisitResult(
      succeeded: (json['succeeded'] ?? json['Succeeded']) as bool? ?? false,
      message: (json['message'] ?? json['Message'])?.toString() ?? '',
      paymentId: (json['paymentId'] ?? json['PaymentId'])?.toString(),
      attendanceId: (json['attendanceId'] ?? json['AttendanceId'])?.toString(),
      memberId: (json['memberId'] ?? json['MemberId'])?.toString(),
      amountPaid: parseDouble(json['amountPaid'] ?? json['AmountPaid']),
    );
  }
}
