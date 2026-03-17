import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/networking/api_client.dart';

class StoryRepository {
  StoryRepository(this._dio);

  final Dio _dio;

  /// Create a new story (for wholesalers)
  Future<Map<String, dynamic>> createStory({
    required String wholesalerId,
    required String mediaUrl,
    String? thumbnailUrl,
    required bool isVideo,
    String? expiresAt,
    String? productId,
    String? dealId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/stories',
        data: {
          'wholesalerId': wholesalerId,
          'mediaUrl': mediaUrl,
          if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
          'isVideo': isVideo,
          if (expiresAt != null) 'expiresAt': expiresAt,
          if (productId != null && productId.isNotEmpty) 'productId': productId,
          if (dealId != null && dealId.isNotEmpty) 'dealId': dealId,
        },
      );

      return response.data?['data'] as Map<String, dynamic>? ?? {};
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  /// Fetch wholesaler's own products (for linking)
  Future<List<Map<String, dynamic>>> fetchMyProducts() async {
    try {
      debugPrint('fetchMyProducts request');
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/products',
        queryParameters: {'limit': 100}, // Get all products
      );
      debugPrint('fetchMyProducts response: ${response.data}');

      final data = response.data?['data'] as List<dynamic>? ?? [];
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  /// Fetch wholesaler's own deals (for linking)
  Future<List<Map<String, dynamic>>> fetchMyDeals() async {
    try {
      debugPrint('fetchMyDeals request');
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/deals',
        queryParameters: {'limit': 100}, // Get all deals
      );

      debugPrint('fetchMyDeals response: ${response.data}');

      final data = response.data?['data'] as List<dynamic>? ?? [];
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }
}

final storyRepositoryProvider = Provider<StoryRepository>(
  (ref) => StoryRepository(ref.watch(dioProvider)),
  name: 'StoryRepositoryProvider',
);
