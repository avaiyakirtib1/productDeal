import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/networking/api_client.dart';
import '../../../manager/data/models/manager_models.dart';

class ManagerRepository {
  ManagerRepository(this._dio);

  final Dio _dio;

  /// Fetch dashboard statistics (role-aware: admin sees all, wholesaler sees only their own)
  /// Uses generic manager endpoint which handles role-based filtering
  Future<ManagerStats> fetchStats() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/manager/stats');
      return ManagerStats.fromJson(
        response.data?['data'] as Map<String, dynamic>? ?? const {},
      );
    } on DioException catch (error) {
      debugPrint('ManagerStats error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Fetch products (role-aware: admin sees all, wholesaler sees only their own)
  /// Uses generic manager endpoint which handles role-based filtering on the backend
  Future<ManagerProductsPage> fetchProducts({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
    };

    try {
      // Use admin endpoint which supports role-based filtering:
      // - Admin/SubAdmin: sees all products
      // - Wholesaler: sees only their own products (filtered by backend)
      final response = await _dio.get<Map<String, dynamic>>(
        '/manager/products',
        queryParameters: query,
      );
      return ManagerProductsPage.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      debugPrint('WholesalerProducts error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Fetch deals (role-aware: admin sees all, wholesaler sees only their own)
  /// Uses generic manager endpoint which handles role-based filtering on the backend
  Future<ManagerDealsPage> fetchDeals({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null && status.isNotEmpty) 'status': status,
    };

    try {
      // Use generic manager endpoint which supports role-based filtering:
      // - Admin/SubAdmin: sees all deals
      // - Wholesaler: sees only their own deals (filtered by backend)
      final response = await _dio.get<Map<String, dynamic>>(
        '/manager/deals',
        queryParameters: query,
      );
      return ManagerDealsPage.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      debugPrint('WholesalerDeals error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Fetch orders (role-aware: admin sees all, wholesaler sees only their own)
  /// Uses generic manager endpoint which handles role-based filtering on the backend
  Future<ManagerOrdersPage> fetchOrders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null && status.isNotEmpty) 'status': status,
    };

    try {
      // Use generic manager endpoint which supports role-based filtering:
      // - Admin/SubAdmin: sees all orders
      // - Wholesaler: sees only their own orders (filtered by backend)
      final response = await _dio.get<Map<String, dynamic>>(
        '/manager/orders',
        queryParameters: query,
      );
      return ManagerOrdersPage.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      debugPrint('WholesalerOrders error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Create a new product
  Future<void> createProduct(Map<String, dynamic> productData) async {
    try {
      await _dio.post('/admin/products', data: productData);
    } on DioException catch (error) {
      debugPrint('CreateProduct error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Update a product
  Future<void> updateProduct(
      String productId, Map<String, dynamic> productData) async {
    try {
      await _dio.patch('/admin/products/$productId', data: productData);
    } on DioException catch (error) {
      debugPrint('UpdateProduct error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Update product status
  Future<void> updateProductStatus(String productId, String status) async {
    try {
      await _dio.patch('/admin/products/$productId', data: {'status': status});
    } on DioException catch (error) {
      debugPrint('UpdateProductStatus error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Delete a product
  Future<void> deleteProduct(String productId) async {
    try {
      await _dio.delete('/admin/products/$productId');
    } on DioException catch (error) {
      debugPrint('DeleteProduct error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Create a new deal
  Future<void> createDeal(Map<String, dynamic> dealData) async {
    try {
      await _dio.post('/admin/deals', data: dealData);
    } on DioException catch (error) {
      debugPrint('CreateDeal error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Update a deal
  Future<void> updateDeal(String dealId, Map<String, dynamic> dealData) async {
    try {
      await _dio.patch('/admin/deals/$dealId', data: dealData);
    } on DioException catch (error) {
      debugPrint('UpdateDeal error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, String status,
      {String? notes}) async {
    try {
      await _dio.patch(
        '/admin/orders/$orderId',
        data: {
          'status': status,
          if (notes != null) 'notes': notes,
        },
      );
    } on DioException catch (error) {
      debugPrint('UpdateOrderStatus error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Fetch full product detail with all fields including variants
  Future<Map<String, dynamic>> fetchProductDetail(String productId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/products/$productId',
      );
      return response.data?['data'] as Map<String, dynamic>? ?? {};
    } on DioException catch (error) {
      debugPrint('FetchProductDetail error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Fetch product variants (for admin/wholesaler operations)
  /// This endpoint works for all product statuses, not just APPROVED
  Future<List<Map<String, dynamic>>> fetchProductVariants(
      String productId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/products/$productId/variants',
      );
      final data = response.data?['data'] as Map<String, dynamic>? ?? {};
      final variants = data['variants'] as List<dynamic>? ?? [];
      return variants.map((variant) {
        final v = variant as Map<String, dynamic>;
        return {
          'id': v['_id']?.toString() ?? '',
          'sku': v['sku']?.toString() ?? '',
          'attributes': v['attributes'] as Map<String, dynamic>? ?? {},
          'price': (v['price'] as num?)?.toDouble() ?? 0.0,
          'costPrice': (v['costPrice'] as num?)?.toDouble(),
          'stock': (v['stock'] as num?)?.toInt() ?? 0,
          'reservedStock': (v['reservedStock'] as num?)?.toInt() ?? 0,
          'availableStock': (v['availableStock'] as num?)?.toInt() ?? 0,
          'images': (v['images'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          'isDefault': v['isDefault'] == true,
          'isActive':
              v['isActive'] != false, // Default to true if not specified
        };
      }).toList();
    } on DioException catch (error) {
      debugPrint('FetchProductVariants error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }
}

final managerRepositoryProvider = Provider<ManagerRepository>(
  (ref) => ManagerRepository(ref.watch(dioProvider)),
  name: 'ManagerRepositoryProvider',
);
