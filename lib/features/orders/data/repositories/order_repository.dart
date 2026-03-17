import 'package:dio/dio.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/networking/api_client.dart';
import '../models/order_models.dart';
import 'dart:convert';

class OrderRepository {
  OrderRepository(this._dio);

  final Dio _dio;

  Future<OrderSummary> createOrder({
    required List<Map<String, dynamic>> items,
    String paymentMethod = 'cash_on_delivery',
    String? notes,
    Map<String, dynamic>? shippingAddress,
  }) async {
    final payload = <String, dynamic>{
      'items': items,
      'paymentMethod': paymentMethod,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (shippingAddress != null) 'shippingAddress': shippingAddress,
    };

    debugPrint('Order payload: ${jsonEncode(payload)}');

    final response = await _dio.post<Map<String, dynamic>>(
      '/orders',
      data: payload,
    );
    debugPrint('Order Response Status: ${response.statusCode}');
    debugPrint('Order response: ${jsonEncode(response.data)}');

    return OrderSummary.fromJson(
      response.data?['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<List<OrderSummary>> fetchMyOrders({
    OrderStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null) 'status': status.apiName,
    };

    final response = await _dio.get<Map<String, dynamic>>(
      '/orders/my',
      queryParameters: query,
    );

    final data = response.data?['data'] as List<dynamic>? ?? [];
    return data
        .map((item) => OrderSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<OrderSummary> fetchOrderDetail(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/orders/$id');
    return OrderSummary.fromJson(
      response.data?['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<List<OrderStatusHistoryEntry>> fetchOrderHistory(
      String orderId) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/orders/$orderId/history');
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    final history = data['history'] as List<dynamic>? ?? [];
    return history
        .map((item) =>
            OrderStatusHistoryEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Shipment> trackShipment(String trackingNumber) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/catalog/shipments/$trackingNumber',
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return Shipment.fromJson(
        data['shipment'] as Map<String, dynamic>? ?? const {});
  }

  // Admin/Wholesaler: Update order status
  Future<OrderSummary> updateOrderStatus(
    String orderId, {
    required String status,
    String? reason,
    String? notes,
    String? internalNotes,
  }) async {
    final payload = <String, dynamic>{
      'status': status,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (internalNotes != null && internalNotes.isNotEmpty)
        'internalNotes': internalNotes,
    };

    final response = await _dio.put<Map<String, dynamic>>(
      '/admin/orders/$orderId/status',
      data: payload,
    );

    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    final orderData = data['order'] as Map<String, dynamic>? ?? data;
    return OrderSummary.fromJson(orderData);
  }

  // Admin/Wholesaler: Update order item status
  Future<OrderSummary> updateOrderItemStatus(
    String orderId,
    String itemId, {
    required String status,
    String? reason,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'status': status,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response = await _dio.put<Map<String, dynamic>>(
      '/admin/orders/$orderId/items/$itemId/status',
      data: payload,
    );

    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    final orderData = data['order'] as Map<String, dynamic>? ?? data;
    return OrderSummary.fromJson(orderData);
  }

  Future<void> sendPaymentInstructions(String orderId) async {
    await _dio.post<Map<String, dynamic>>('/orders/$orderId/send-payment-instructions');
  }

  /// Admin/Wholesaler: Mark order payment as completed (for invoice/bank_transfer orders)
  Future<void> updateOrderPaymentStatus(
      String orderId, String paymentStatus) async {
    await _dio.patch<Map<String, dynamic>>(
      '/admin/orders/$orderId',
      data: {'paymentStatus': paymentStatus},
    );
  }

  /// Buyer: Report payment (e.g. bank transfer reference) for product order
  Future<void> reportPayment(
    String orderId, {
    String? referenceNumber,
    String? transactionId,
    String? bankName,
    String? notes,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/orders/$orderId/report-payment',
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

  // Admin/Wholesaler: Create shipment for order
  Future<Shipment> createShipment({
    required String orderId,
    required List<Map<String, dynamic>> items,
    String? trackingNumber,
    String? carrier,
    String? trackingUrl,
    DateTime? estimatedDelivery,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'items': items,
      if (trackingNumber != null && trackingNumber.isNotEmpty)
        'trackingNumber': trackingNumber,
      if (carrier != null && carrier.isNotEmpty) 'carrier': carrier,
      if (trackingUrl != null && trackingUrl.isNotEmpty)
        'trackingUrl': trackingUrl,
      if (estimatedDelivery != null)
        'estimatedDelivery': DateFormat('yyyy-MM-dd').format(estimatedDelivery),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response = await _dio.post<Map<String, dynamic>>(
      '/admin/orders/$orderId/shipments',
      data: payload,
    );

    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    final shipmentData = data['shipment'] as Map<String, dynamic>? ?? data;
    return Shipment.fromJson(shipmentData);
  }
}

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => OrderRepository(ref.watch(dioProvider)),
  name: 'OrderRepositoryProvider',
);
