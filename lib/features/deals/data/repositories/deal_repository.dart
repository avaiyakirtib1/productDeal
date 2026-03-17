import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/networking/api_client.dart';
import '../models/deal_models.dart';

class DealRepository {
  DealRepository(this._dio);

  final Dio _dio;

  Future<DealListPage> fetchDeals({
    int page = 1,
    int limit = 20,
    DealStatus? status,
    DealType? type,
    String? storyId,
    String? wholesalerId,
    String? productId,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null) 'status': status.name,
      if (type != null) 'type': type.name,
      if (storyId != null && storyId.isNotEmpty) 'storyId': storyId,
      if (wholesalerId != null && wholesalerId.isNotEmpty)
        'wholesalerId': wholesalerId,
      if (productId != null && productId.isNotEmpty) 'productId': productId,
    };

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/deals',
        queryParameters: query,
      );

      return DealListPage.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      debugPrint('DealListPage error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  Future<DealDetail> fetchDealDetail(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/deals/$id');
      return DealDetail.fromJson(
        response.data?['data'] as Map<String, dynamic>? ?? const {},
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<DealOrder> placeOrder({
    required String dealId,
    required int quantity,
    String? notes,
    String paymentMethodAtOrder = 'invoice',
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/deals/$dealId/orders',
        data: {
          'quantity': quantity,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          'paymentMethodAtOrder': paymentMethodAtOrder,
        },
      );

      debugPrint('DealOrder response: ${response.data}');

      return DealOrder.fromJson(
        response.data?['data'] as Map<String, dynamic>? ?? const {},
      );
    } on DioException catch (error) {
      debugPrint('DealOrder error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  Future<List<DealOrder>> fetchMyOrders({
    DealOrderStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null) 'status': status.name,
    };

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/deals/orders/my',
        queryParameters: query,
      );

      final data = response.data?['data'] as List<dynamic>? ?? [];
      return data
          .map((item) => DealOrder.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  /// Orders for a specific deal (for deal detail page history)
  Future<List<DealOrder>> fetchOrdersForDeal(String dealId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/deals/$dealId/orders',
      );

      final data = response.data?['data'] as List<dynamic>? ?? [];
      return data.map((item) {
        final map = Map<String, dynamic>.from(item as Map<String, dynamic>);
        if (!map.containsKey('dealId')) map['dealId'] = dealId;
        return DealOrder.fromJson(map);
      }).toList();
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<void> sendDealOrderPaymentInstructions(String orderId) async {
    await _dio.post<Map<String, dynamic>>('/deals/orders/$orderId/send-payment-instructions');
  }

  /// Buyer: Report payment (e.g. bank transfer reference) for deal order
  Future<void> reportDealOrderPayment(
    String orderId, {
    String? referenceNumber,
    String? transactionId,
    String? bankName,
    String? notes,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/deals/orders/$orderId/report-payment',
      data: {
        if (referenceNumber != null && referenceNumber.isNotEmpty)
          'referenceNumber': referenceNumber,
        if (transactionId != null && transactionId.isNotEmpty)
          'transactionId': transactionId,
        if (bankName != null && bankName.isNotEmpty) 'bankName': bankName,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
  }

  /// Admin/owner: mark deal order as paid (e.g. customer paid by bank transfer)
  Future<void> markDealOrderPaid(String orderId, {String? notes}) async {
    try {
      await _dio.post(
        '/deals/orders/$orderId/mark-paid',
        data: {if (notes != null && notes.isNotEmpty) 'notes': notes},
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await _dio.delete('/deals/orders/$orderId');
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  /// Admin/owner: confirm an order
  Future<void> confirmOrderAdmin(String orderId) async {
    try {
      await _dio.post('/deals/orders/$orderId/confirm');
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  /// Admin/owner: create shipment for deal order
  Future<void> createDealShipment({
    required String orderId,
    String? trackingNumber,
    String? carrier,
    String? trackingUrl,
    DateTime? estimatedDelivery,
    String? notes,
  }) async {
    try {
      await _dio.post(
        '/deals/orders/$orderId/shipment',
        data: {
          if (trackingNumber != null) 'trackingNumber': trackingNumber,
          if (carrier != null) 'carrier': carrier,
          if (trackingUrl != null) 'trackingUrl': trackingUrl,
          if (estimatedDelivery != null)
            'estimatedDelivery':
                DateFormat('yyyy-MM-dd').format(estimatedDelivery),
          if (notes != null) 'notes': notes,
        },
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  /// Admin/owner: ship an order (legacy method)
  Future<void> shipOrderAdmin({
    required String orderId,
    String? trackingNumber,
    String? carrier,
    String? trackingUrl,
    String? notes,
  }) async {
    try {
      await _dio.post(
        '/deals/orders/$orderId/ship',
        data: {
          if (trackingNumber != null) 'trackingNumber': trackingNumber,
          if (carrier != null) 'carrier': carrier,
          if (trackingUrl != null) 'trackingUrl': trackingUrl,
          if (notes != null) 'notes': notes,
        },
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  /// Admin/owner: mark order as delivered
  Future<void> deliverOrderAdmin({
    required String orderId,
    String? notes,
  }) async {
    try {
      await _dio.post(
        '/deals/orders/$orderId/deliver',
        data: {
          if (notes != null) 'notes': notes,
        },
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  /// Admin/owner: reduce order quantity (or cancel if 0)
  Future<void> reduceOrderQuantityAdmin(String orderId, int quantity, {String? reason}) async {
    try {
      await _dio.patch(
        '/deals/orders/$orderId/quantity',
        data: {
          'quantity': quantity,
          if (reason != null) 'reason': reason,
        },
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  /// Admin/owner: cancel any order
  Future<void> cancelOrderAdmin(String orderId, {String? reason}) async {
    try {
      await _dio.delete(
        '/deals/orders/$orderId/admin',
        data: reason != null ? {'reason': reason} : null,
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  /// Closes the deal. [goalReached] true = auto-confirm all pending orders (goal reached).
  /// false = just close; admin can confirm orders manually later.
  Future<bool> closeDeal(String dealId, {bool goalReached = false}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/deals/$dealId/close',
      data: {'goalReached': goalReached},
    );
    if (response.data?['status'] == 'success') {
      return true;
    } else {
      throw Exception(response.data?['message']);
    }
  }

  Future<Deal> extendDeal({
    required String dealId,
    required DateTime newEndAt,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/deals/$dealId/extend',
      data: {
        'newEndAt': newEndAt.toIso8601String(),
      },
    );

    return Deal.fromJson(
      response.data?['data'] as Map<String, dynamic>? ?? const {},
    );
  }
}

final dealRepositoryProvider = Provider<DealRepository>(
  (ref) => DealRepository(ref.watch(dioProvider)),
  name: 'DealRepositoryProvider',
);
