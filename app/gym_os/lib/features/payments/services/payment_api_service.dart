import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/sync/sync_provider.dart';
import '../../../core/utils/uuid_generator.dart';
import '../../../l10n/app_localizations.dart';
import '../models/payment_models.dart';

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
  return PaymentApiService(
    ref.watch(dioProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});

class PaymentApiService {
  final Dio _dio;
  final AppDatabase? _db;
  final SyncEngine? _syncEngine;

  PaymentApiService(this._dio, [this._db, this._syncEngine]);

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

  /// Renews a subscription locally in Drift + SyncOutbox in <50ms and triggers background sync.
  Future<String> renewSubscription({
    required String memberId,
    required String planId,
    required int paymentMethod,
    required double amountPaid,
    String? notes,
  }) async {
    if (_db != null) {
      final now = DateTime.now();
      final opId = UuidGenerator.v4();
      final payId = UuidGenerator.v4();

      final member = await (_db.select(_db.localMembers)
            ..where((t) => t.id.equals(memberId)))
          .getSingleOrNull();

      final plan = await (_db.select(_db.localPlans)
            ..where((t) => t.id.equals(planId)))
          .getSingleOrNull();

      final baseDate = (member?.subscriptionEndDate != null &&
              member!.subscriptionEndDate!.isAfter(now))
          ? member.subscriptionEndDate!
          : now;
      final newEndDate =
          baseDate.add(Duration(days: plan?.durationDays ?? 30));

      await _db.membersDao.renewSubscriptionWithOutbox(
        memberId: memberId,
        newEndDate: newEndDate,
        planId: planId,
        planName: plan?.name,
        payment: LocalPaymentsCompanion.insert(
          id: payId,
          memberId: Value(memberId),
          memberName: Value(member?.fullName),
          planId: Value(planId),
          amountPaid: amountPaid,
          method: paymentMethod,
          type: 2, // Renewal
          createdAt: now,
          isDirty: const Value(true),
        ),
        outboxEntry: SyncOutboxCompanion.insert(
          operationId: opId,
          entityType: 'member_renew',
          entityId: memberId,
          payloadJson: jsonEncode({
            'memberId': memberId,
            'clientId': opId,
            'planId': planId,
            'paymentMethod': paymentMethod,
            'amountPaid': amountPaid,
            'notes': notes,
            'occurredAtUtc': now.toUtc().toIso8601String(),
          }),
          createdAt: now,
        ),
      );

      unawaited(_syncEngine?.syncNow());
      return 'تم تجديد الاشتراك بنجاح';
    }

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
      return response.data['message'] ?? 'تم تجديد الاشتراك بنجاح';
    } on DioException catch (e) {
      final errorMsg =
          e.response?.data['message'] ?? 'حدث خطأ أثناء تجديد الاشتراك';
      throw Exception(errorMsg);
    }
  }
}
