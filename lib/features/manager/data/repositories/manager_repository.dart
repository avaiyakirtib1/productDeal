import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/networking/api_client.dart';
import '../models/manager_models.dart';
import '../../../admin/data/models/admin_user_model.dart';
import 'dart:convert';

/// Page of inactive members (Kiosk users with no order in N days)
class InactiveMembersPage {
  const InactiveMembersPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.totalRows,
    required this.totalPages,
  });
  final List<AdminUser> items;
  final int page;
  final int limit;
  final int totalRows;
  final int totalPages;
}

class ManagerRepository {
  ManagerRepository(this._dio);

  final Dio _dio;

  /// Fetch manager dashboard statistics (role-aware: admin sees all, wholesaler sees only their own)
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

  /// Fetch kiosk statistics for the logged-in kiosk user
  /// (deals joined, total ordered quantity, total orders)
  Future<Map<String, dynamic>> fetchKioskStats() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/manager/kiosk-stats');
      return (response.data?['data'] as Map<String, dynamic>?) ?? const {};
    } on DioException catch (error) {
      debugPrint('KioskStats error: ${error.response?.data}');
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
    String? wholesalerId,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
      if (wholesalerId != null && wholesalerId.isNotEmpty)
        'wholesalerId': wholesalerId,
    };

    try {
      // Use generic manager endpoint which supports role-based filtering:
      // - Admin/SubAdmin: sees all products
      // - Wholesaler: sees only their own products (filtered by backend)
      final response = await _dio.get<Map<String, dynamic>>(
        '/manager/products',
        queryParameters: query,
      );
      //debugPrint('ManagerProducts response: ${jsonEncode(response.data)}');
      return ManagerProductsPage.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      debugPrint('ManagerProducts error: ${error.response?.data}');
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
      debugPrint('ManagerDeals error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Fetch inactive members (Kiosk users with no order in N days) - admin/sub-admin only
  Future<InactiveMembersPage> fetchInactiveMembers({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/manager/inactive-members',
        queryParameters: query,
      );
      final data = response.data?['data'] as List<dynamic>? ?? [];
      final meta = response.data?['meta'] as Map<String, dynamic>? ?? {};
      return InactiveMembersPage(
        items: data
            .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
            .toList(),
        page: meta['page'] as int? ?? page,
        limit: meta['limit'] as int? ?? limit,
        totalRows: meta['totalRows'] as int? ?? data.length,
        totalPages: meta['totalPages'] as int? ?? 1,
      );
    } on DioException catch (e) {
      debugPrint('FetchInactiveMembers error: ${e.response?.data}');
      throw mapDioException(e);
    }
  }

  /// Fetch revenue orders (delivered product + deal orders contributing to revenue)
  Future<RevenueOrdersPage> fetchRevenueOrders({
    int page = 1,
    int limit = 100,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/manager/revenue-orders',
        queryParameters: query,
      );
      final data = response.data?['data'] as List<dynamic>? ?? [];
      final meta = response.data?['meta'] as Map<String, dynamic>? ?? {};
      return RevenueOrdersPage(
        items: data
            .map((e) =>
                RevenueOrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        page: meta['page'] as int? ?? page,
        limit: meta['limit'] as int? ?? limit,
        totalRows: meta['totalRows'] as int? ?? data.length,
        totalPages: meta['totalPages'] as int? ?? 1,
      );
    } on DioException catch (error) {
      debugPrint('FetchRevenueOrders error: ${error.response?.data}');
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
      debugPrint('ManagerOrders error: ${error.response?.data}');
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

  /// Create a new category
  Future<void> createCategory(Map<String, dynamic> categoryData) async {
    try {
      await _dio.post('/admin/categories', data: categoryData);
    } on DioException catch (error) {
      debugPrint('CreateCategory error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Update a product
  Future<void> updateProduct(
      String productId, Map<String, dynamic> productData) async {
    try {
      debugPrint('UpdateProduct productId: $productId');
      debugPrint('Payload: ${jsonEncode(productData)}');
      await _dio.patch('/admin/products/$productId', data: productData);
    } on DioException catch (error) {
      debugPrint('UpdateProduct error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Update product status (admin only)
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

  /// Generate product content using AI
  Future<Map<String, dynamic>> generateProductContent(
    String prompt, {
    String? language,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/products/generate-content',
        data: {
          'prompt': prompt,
          if (language != null && language.isNotEmpty) 'language': language,
        },
      );
      return response.data?['data'] as Map<String, dynamic>? ?? {};
    } on DioException catch (error) {
      debugPrint('GenerateProductContent error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Generate category content using AI
  Future<Map<String, dynamic>> generateCategoryContent(
    String prompt, {
    String? language,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/categories/generate-content',
        data: {
          'prompt': prompt,
          if (language != null && language.isNotEmpty) 'language': language,
        },
      );
      return response.data?['data'] as Map<String, dynamic>? ?? {};
    } on DioException catch (error) {
      debugPrint('GenerateCategoryContent error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Generate deal content using AI. Pass productId/variantId for context-aware generation.
  Future<Map<String, dynamic>> generateDealContent(
    String prompt, {
    String? language,
    String? productId,
    String? variantId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/deals/generate-content',
        data: {
          'prompt': prompt,
          if (language != null && language.isNotEmpty) 'language': language,
          if (productId != null && productId.isNotEmpty) 'productId': productId,
          if (variantId != null && variantId.isNotEmpty) 'variantId': variantId,
        },
      );
      return response.data?['data'] as Map<String, dynamic>? ?? {};
    } on DioException catch (error) {
      debugPrint('GenerateDealContent error: ${error.response?.data}');
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

  /// Generate payment email subject/body with AI. Pass dealId (for context) or dealTitle/dealType.
  Future<Map<String, dynamic>> generateDealPaymentEmail({
    String? dealId,
    String? dealTitle,
    String? dealType,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (dealId != null && dealId.isNotEmpty) body['dealId'] = dealId;
      if (dealTitle != null && dealTitle.isNotEmpty) body['dealTitle'] = dealTitle;
      if (dealType != null && dealType.isNotEmpty) body['dealType'] = dealType;
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/deals/generate-payment-email',
        data: body,
      );
      return response.data?['data'] as Map<String, dynamic>? ?? {};
    } on DioException catch (error) {
      debugPrint('GenerateDealPaymentEmail error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Delete a deal
  Future<void> deleteDeal(String dealId) async {
    try {
      await _dio.delete('/admin/deals/$dealId');
    } on DioException catch (error) {
      debugPrint('DeleteDeal error: ${error.response?.data}');
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

  /// Update order payment status (admin/wholesaler)
  Future<void> updateOrderPaymentStatus(
      String orderId, String paymentStatus) async {
    try {
      await _dio.patch(
        '/admin/orders/$orderId',
        data: {'paymentStatus': paymentStatus},
      );
    } on DioException catch (error) {
      debugPrint('UpdateOrderPaymentStatus error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Send payment instructions for product order (admin/wholesaler)
  Future<void> sendProductOrderPaymentInstructions(String orderId) async {
    try {
      await _dio.post('/orders/$orderId/send-payment-instructions');
    } on DioException catch (error) {
      debugPrint('SendPaymentInstructions error: ${error.response?.data}');
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

  /// Fetch full deal detail with all fields including multilingual data
  Future<Map<String, dynamic>> fetchDealDetail(String dealId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/deals/$dealId',
      );
      return response.data?['data'] as Map<String, dynamic>? ?? {};
    } on DioException catch (error) {
      debugPrint('FetchDealDetail error: ${error.response?.data}');
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

  /// Bulk import products from CSV data
  /// rows: 2D array where first row is headers, rest are data rows
  /// wholesalerId: Optional wholesaler ID (for admin to import for specific wholesaler)
  Future<Map<String, dynamic>> bulkImportProducts(
    List<List<dynamic>> rows, {
    String? wholesalerId,
  }) async {
    try {
      // Convert rows to the format expected by backend
      // Backend expects: rows: array of arrays (cells can be string, number, boolean, null)
      final formattedRows = rows.map((row) {
        return row.map((cell) {
          if (cell == null) return null;
          if (cell is num) return cell;
          if (cell is bool) return cell;
          return cell.toString();
        }).toList();
      }).toList();

      final queryParams = <String, dynamic>{};
      if (wholesalerId != null && wholesalerId.isNotEmpty) {
        queryParams['wholesalerId'] = wholesalerId;
      }

      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/import/products',
        data: {
          'rows': formattedRows,
        },
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      return response.data?['data'] as Map<String, dynamic>? ??
          {
            'inserted': 0,
            'updated': 0,
            'skipped': 0,
            'errors': [],
          };
    } on DioException catch (error) {
      debugPrint('BulkImportProducts error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }
}

final managerRepositoryProvider = Provider<ManagerRepository>(
  (ref) => ManagerRepository(ref.watch(dioProvider)),
  name: 'ManagerRepositoryProvider',
);
