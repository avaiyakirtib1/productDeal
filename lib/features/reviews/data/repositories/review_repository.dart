import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/networking/api_client.dart';
import '../models/review_models.dart';

class ReviewRepository {
  ReviewRepository(this._dio);

  final Dio _dio;

  /// Get reviews for a product
  Future<ProductReviewsPage> getProductReviews(
    String productId, {
    int page = 1,
    int limit = 10,
    int? rating,
    String? sortBy, // 'newest', 'oldest', 'highest', 'lowest', 'helpful'
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (rating != null) 'rating': rating,
        if (sortBy != null) 'sortBy': sortBy,
      };

      final response = await _dio.get<Map<String, dynamic>>(
        '/reviews/product/$productId',
        queryParameters: queryParams,
      );

      return ProductReviewsPage.fromJson(response.data ?? {});
    } on DioException catch (error) {
      debugPrint('GetProductReviews error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Get user's reviews
  Future<Map<String, dynamic>> getUserReviews({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/reviews/user/me',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      return {
        'reviews': (response.data?['data'] as List<dynamic>?)
                ?.map((e) => Review.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        'pagination': PaginationMeta.fromJson(
          response.data?['meta'] as Map<String, dynamic>? ?? {},
        ),
      };
    } on DioException catch (error) {
      debugPrint('GetUserReviews error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Create a review
  Future<Review> createReview({
    required String productId,
    required String orderId,
    String? orderItemId,
    required int rating,
    String? title,
    String? comment,
    List<String>? images,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/reviews',
        data: {
          'productId': productId,
          'orderId': orderId,
          if (orderItemId != null) 'orderItemId': orderItemId,
          'rating': rating,
          if (title != null) 'title': title,
          if (comment != null) 'comment': comment,
          if (images != null) 'images': images,
        },
      );

      return Review.fromJson(response.data?['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      debugPrint('CreateReview error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Update a review
  Future<Review> updateReview({
    required String reviewId,
    int? rating,
    String? title,
    String? comment,
    List<String>? images,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/reviews/$reviewId',
        data: {
          if (rating != null) 'rating': rating,
          if (title != null) 'title': title,
          if (comment != null) 'comment': comment,
          if (images != null) 'images': images,
        },
      );

      return Review.fromJson(response.data?['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      debugPrint('UpdateReview error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Delete a review
  Future<void> deleteReview(String reviewId) async {
    try {
      await _dio.delete('/reviews/$reviewId');
    } on DioException catch (error) {
      debugPrint('DeleteReview error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Mark review as helpful
  Future<void> markReviewHelpful(String reviewId, bool helpful) async {
    try {
      await _dio.post(
        '/reviews/$reviewId/helpful',
        data: {'helpful': helpful},
      );
    } on DioException catch (error) {
      debugPrint('MarkReviewHelpful error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Respond to a review (wholesaler/admin)
  Future<Review> respondToReview(String reviewId, String responseText) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/reviews/$reviewId/respond',
        data: {'response': responseText},
      );

      return Review.fromJson(response.data?['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      debugPrint('RespondToReview error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Get orders eligible for review
  Future<List<EligibleOrder>> getEligibleOrders({String? productId}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/reviews/eligible-orders',
        queryParameters: {
          if (productId != null) 'productId': productId,
        },
      );
      debugPrint('GetEligibleOrders response: ${response.data}');

      return (response.data?['data'] as List<dynamic>?)
              ?.map((e) => EligibleOrder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
    } on DioException catch (error) {
      debugPrint('GetEligibleOrders error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }
}

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.watch(dioProvider));
});
