import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/networking/api_client.dart';
import '../../domain/models/banner_model.dart';

class BannerRepository {
  BannerRepository(this._dio);

  final Dio _dio;

  // Get Public Banners
  Future<List<BannerModel>> fetchPublicBanners() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/banners');
      final data = response.data?['data'] as List<dynamic>? ?? [];
      debugPrint('Public banners: $data');
      return data
          .map((item) => BannerModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching public banners: $e');
      rethrow;
    }
  }

  // Get single banner by ID (for detail/edit)
  Future<BannerModel> fetchBannerById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/banners/$id');
      return BannerModel.fromJson(
          response.data?['data'] as Map<String, dynamic>? ?? {});
    } catch (e) {
      debugPrint('Error fetching banner: $e');
      rethrow;
    }
  }

  // Update Banner (Admin/Manager: immediate; Wholesaler: goes to pending)
  Future<BannerModel> updateBanner(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/banners/$id',
        data: data,
      );
      return BannerModel.fromJson(
          response.data?['data'] as Map<String, dynamic>? ?? {});
    } catch (e) {
      debugPrint('Error updating banner: $e');
      rethrow;
    }
  }

  // Get Mange Banners (Wholesaler/Admin)
  Future<List<BannerModel>> fetchManageBanners({String? status}) async {
    try {
      final query = <String, dynamic>{};
      if (status != null) {
        query['status'] = status;
      }

      final response = await _dio.get<Map<String, dynamic>>(
        '/banners/manage',
        queryParameters: query,
      );
      final data = response.data?['data'] as List<dynamic>? ?? [];
      return data
          .map((item) => BannerModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching manage banners: $e');
      rethrow;
    }
  }

  // Create Banner
  Future<BannerModel> createBanner(Map<String, dynamic> bannerData) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/banners',
        data: bannerData,
      );
      return BannerModel.fromJson(
          response.data?['data'] as Map<String, dynamic>? ?? {});
    } catch (e) {
      debugPrint('Error creating banner: $e');
      rethrow;
    }
  }

  // Update Banner Status (Admin)
  Future<BannerModel> updateBannerStatus(String id, String status) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/banners/$id/status',
        data: {'status': status},
      );
      return BannerModel.fromJson(
          response.data?['data'] as Map<String, dynamic>? ?? {});
    } catch (e) {
      debugPrint('Error updating banner status: $e');
      rethrow;
    }
  }

  // Delete Banner
  Future<void> deleteBanner(String id) async {
    try {
      await _dio.delete('/banners/$id');
    } catch (e) {
      debugPrint('Error deleting banner: $e');
      rethrow;
    }
  }

  // Track Banner Click
  Future<void> trackBannerClick(String id) async {
    try {
      await _dio.post('/banners/$id/click');
    } catch (e) {
      debugPrint('Error tracking banner click: $e');
      // Don't rethrow - click tracking should be fire and forget
    }
  }
}

final bannerRepositoryProvider = Provider<BannerRepository>(
  (ref) => BannerRepository(ref.watch(dioProvider)),
);
