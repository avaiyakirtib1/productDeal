import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/networking/api_client.dart';
import '../dashboard_snapshot_parse.dart';
import '../models/dashboard_models.dart';

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  Future<DashboardSnapshot> fetchSnapshot(
      {double? latitude, double? longitude}) async {
    debugPrint('📡 DashboardRepository: Fetching dashboard snapshot...');

    final query = <String, dynamic>{};
    if (latitude != null && longitude != null) {
      query['lat'] = latitude;
      query['lng'] = longitude;
    }

    final networkSw = Stopwatch()..start();
    final response = await _dio.get<Map<String, dynamic>>(
      '/catalog/dashboard',
      queryParameters: query.isEmpty ? null : query,
    );
    networkSw.stop();
    debugPrint(
      '⏱️ DashboardRepository: /catalog/dashboard network '
      '${networkSw.elapsedMilliseconds}ms',
    );

    final payload = response.data?['data'] as Map<String, dynamic>? ?? const {};
    final activeDealsRaw = payload['activeDeals'] as List<dynamic>? ??
        const [];
    debugPrint('Fetched Deals Count: ${activeDealsRaw.length}');

    final parseSw = Stopwatch()..start();
    final snapshot = await compute(parseDashboardSnapshotIsolate, payload);
    parseSw.stop();
    debugPrint(
      '⏱️ DashboardRepository: DashboardSnapshot parse (isolate) '
      '${parseSw.elapsedMilliseconds}ms',
    );
    return snapshot;
  }

  Future<WholesalerDirectoryPage> fetchWholesalers({
    int page = 1,
    int limit = 18,
    double? latitude,
    double? longitude,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (latitude != null && longitude != null) ...{
        'lat': latitude,
        'lng': longitude,
      },
    };

    final response = await _dio.get<Map<String, dynamic>>(
      '/catalog/wholesalers',
      queryParameters: query,
    );

    final data = (response.data?['data'] as List<dynamic>? ?? [])
        .map((item) =>
            SpotlightWholesaler.fromJson(item as Map<String, dynamic>))
        .toList();
    final meta = response.data?['meta'] as Map<String, dynamic>? ?? const {};

    return WholesalerDirectoryPage(
      items: data,
      page: meta['page'] as int? ?? page,
      limit: meta['limit'] as int? ?? limit,
      totalRows: meta['totalRows'] as int? ?? data.length,
    );
  }

  Future<WholesalerProfile> fetchWholesalerProfile(String id) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/catalog/wholesalers/$id');
    return WholesalerProfile.fromJson(
        response.data?['data'] as Map<String, dynamic>? ?? const {});
  }

  Future<ProductDetail> fetchProductDetail(String id) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/catalog/products/$id');
    return ProductDetail.fromJson(
        response.data?['data'] as Map<String, dynamic>? ?? const {});
  }

  Future<CategoryDetail> fetchCategoryDetail(
    String slug, {
    String? wholesalerId,
    double? latitude,
    double? longitude,
    int page = 1,
    int limit = 24,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (wholesalerId != null) {
      query['wholesalerId'] = wholesalerId;
    }
    if (latitude != null && longitude != null) {
      query['lat'] = latitude;
      query['lng'] = longitude;
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '/catalog/categories/$slug',
      queryParameters: query,
    );
    return CategoryDetail.fromJson(
      response.data?['data'] as Map<String, dynamic>? ?? const {},
      meta: response.data?['meta'] as Map<String, dynamic>?,
    );
  }

  Future<List<DashboardProduct>> searchProducts(
    String query, {
    double? latitude,
    double? longitude,
    int limit = 50,
    String? wholesalerId,
  }) async {
    final params = <String, dynamic>{
      'q': query,
      'limit': limit,
    };
    if (latitude != null && longitude != null) {
      params['lat'] = latitude;
      params['lng'] = longitude;
    }
    if (wholesalerId != null) {
      params['wholesalerId'] = wholesalerId;
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '/catalog/products/search',
      queryParameters: params,
    );
    final data = response.data?['data'] as List<dynamic>? ?? [];
    return data
        .map((item) => DashboardProduct.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ProductsPage> fetchAllProducts({
    int page = 1,
    int limit = 24,
    double? latitude,
    double? longitude,
    bool featuredOnly = false,
    String? wholesalerId,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (latitude != null && longitude != null) {
      query['lat'] = latitude;
      query['lng'] = longitude;
    }
    if (featuredOnly) {
      query['featured'] = true;
    }
    if (wholesalerId != null) {
      query['wholesalerId'] = wholesalerId;
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '/catalog/products/all',
      queryParameters: query,
    );

    final data = (response.data?['data'] as List<dynamic>? ?? [])
        .map((item) => DashboardProduct.fromJson(item as Map<String, dynamic>))
        .toList();
    final meta = response.data?['meta'] as Map<String, dynamic>? ?? const {};

    return ProductsPage(
      items: data,
      page: meta['page'] as int? ?? page,
      limit: meta['limit'] as int? ?? limit,
      totalRows: meta['totalRows'] as int? ?? data.length,
      totalPages: meta['totalPages'] as int? ?? 1,
    );
  }

  Future<List<DashboardCategory>> fetchCategories({String? searchQuery}) async {
    final query = <String, dynamic>{};
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      query['q'] = searchQuery.trim();
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '/catalog/categories',
      queryParameters: query.isEmpty ? null : query,
    );
    final data = response.data?['data'] as List<dynamic>? ?? [];
    debugPrint('fetchCategories data: $data');
    return data
        .map((item) => DashboardCategory.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Fetch category tree (hierarchical structure)
  Future<List<CategoryTreeNode>> fetchCategoryTree(
      {bool includeInactive = false}) async {
    final query = <String, dynamic>{};
    if (includeInactive) {
      query['includeInactive'] = 'true';
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '/catalog/categories/tree',
      queryParameters: query.isEmpty ? null : query,
    );
    final data = response.data?['data'] as List<dynamic>? ?? [];
    return data
        .map((item) => CategoryTreeNode.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Fetch children of a specific category
  Future<CategoryChildrenResponse> fetchCategoryChildren(String categoryId,
      {bool includeInactive = false}) async {
    final query = <String, dynamic>{};
    if (includeInactive) {
      query['includeInactive'] = 'true';
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '/catalog/categories/$categoryId/children',
      queryParameters: query.isEmpty ? null : query,
    );
    return CategoryChildrenResponse.fromJson(
        response.data?['data'] as Map<String, dynamic>? ?? const {});
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(dioProvider)),
  name: 'DashboardRepositoryProvider',
);
