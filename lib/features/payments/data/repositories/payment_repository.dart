import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/networking/api_client.dart';

/// Repository for payment-related API calls.
/// Stripe/card payment removed; payment instructions are sent via email.
class PaymentRepository {
  PaymentRepository(this._dio);

  final Dio _dio;

  /// Get final payment summary for a successful deal (invoice payment via email).
  Future<DealFinalPaymentSummary> getDealFinalPaymentSummary(String dealId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/deals/$dealId/final-payment-summary',
      );
      final data = response.data?['data'] as Map<String, dynamic>? ?? {};
      return DealFinalPaymentSummary(
        totalAmountEur: (data['totalAmountEur'] as num?)?.toDouble() ?? 0,
        orderIds: (data['orderIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        dealSucceeded: data['dealSucceeded'] as bool? ?? false,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

class DealFinalPaymentSummary {
  const DealFinalPaymentSummary({
    required this.totalAmountEur,
    required this.orderIds,
    required this.dealSucceeded,
  });
  final double totalAmountEur;
  final List<String> orderIds;
  final bool dealSucceeded;

  bool get hasUnpaidOrders =>
      dealSucceeded && orderIds.isNotEmpty && totalAmountEur > 0;
}

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepository(ref.watch(dioProvider)),
  name: 'PaymentRepositoryProvider',
);
