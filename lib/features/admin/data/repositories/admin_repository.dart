import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/networking/api_client.dart';
import '../../../../core/networking/api_client.dart' as api_client;
import '../models/admin_user_model.dart';

class AdminRepository {
  AdminRepository(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getUsers({
    String? search,
    String? role,
    String? status,
    int page = 1,
    int limit = 25,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (role != null && role.isNotEmpty) {
        queryParams['role'] = role;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/users',
        queryParameters: queryParams,
      );

      final items = (response.data?['data'] as List<dynamic>?) ?? [];
      final meta = response.data?['meta'] as Map<String, dynamic>? ?? {};

      return {
        'items': items
            .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
            .toList(),
        'totalRows': meta['totalRows'] as int? ?? items.length,
        'page': meta['page'] as int? ?? page,
        'limit': meta['limit'] as int? ?? limit,
      };
    } on DioException catch (error) {
      throw api_client.mapDioException(error);
    }
  }

  Future<AdminUser> createUser(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/users',
        data: payload,
      );
      final data = response.data?['data'] as Map<String, dynamic>? ?? {};
      return AdminUser.fromJson(data);
    } on DioException catch (error) {
      throw api_client.mapDioException(error);
    }
  }

  Future<AdminUser> updateUser(
      String userId, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/admin/users/$userId',
        data: payload,
      );
      final data = response.data?['data'] as Map<String, dynamic>? ?? {};
      return AdminUser.fromJson(data);
    } on DioException catch (error) {
      throw api_client.mapDioException(error);
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _dio.delete('/admin/users/$userId');
    } on DioException catch (error) {
      throw api_client.mapDioException(error);
    }
  }

  Future<AdminUser> getUserDetail(String userId) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/admin/users/$userId');
      final data = response.data?['data'] as Map<String, dynamic>? ?? {};
      return AdminUser.fromJson(data);
    } on DioException catch (error) {
      throw api_client.mapDioException(error);
    }
  }

  /// Send Firebase notification to selected users (admin only)
  Future<Map<String, int>> sendNotificationToUsers({
    required List<String> userIds,
    required String title,
    required String body,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/notifications/send',
        data: {'userIds': userIds, 'title': title, 'body': body},
      );
      final data = response.data?['data'] as Map<String, dynamic>? ?? {};
      return {
        'sent': (data['sent'] as num?)?.toInt() ?? 0,
        'failed': (data['failed'] as num?)?.toInt() ?? 0,
      };
    } on DioException catch (error) {
      throw api_client.mapDioException(error);
    }
  }

  /// Generate notification title and body using AI (admin only)
  Future<Map<String, String>> generateNotificationContent(
    String prompt, {
    String? language,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/notifications/generate-content',
        data: {
          'prompt': prompt,
          if (language != null && language.isNotEmpty) 'language': language,
        },
      );
      final data = response.data?['data'] as Map<String, dynamic>? ?? {};
      return {
        'title': (data['title'] as String?) ?? '',
        'body': (data['body'] as String?) ?? '',
      };
    } on DioException catch (error) {
      throw api_client.mapDioException(error);
    }
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(dioProvider));
});
