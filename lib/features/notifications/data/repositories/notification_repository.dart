import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/networking/api_client.dart'
    show dioProvider, mapDioException;
import '../models/notification_model.dart';

class NotificationRepository {
  final Dio _dio;

  NotificationRepository(this._dio);

  /// Get notification history
  Future<NotificationListResponse> getNotifications({
    int page = 1,
    int limit = 20,
    String? status, // 'all', 'unread', 'read'
    String? type, // Filter by notification type
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (status != null && status != 'all') 'status': status,
        if (type != null) 'type': type,
      };

      final response = await _dio.get<Map<String, dynamic>>(
        '/notifications',
        queryParameters: queryParams,
      );

      final data = response.data?['data'] as Map<String, dynamic>? ?? {};
      return NotificationListResponse.fromJson(data);
    } on DioException catch (error) {
      debugPrint('GetNotifications error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/notifications/unread-count',
      );

      final data = response.data?['data'] as Map<String, dynamic>? ?? {};
      return data['unreadCount'] as int? ?? 0;
    } on DioException catch (error) {
      debugPrint('GetUnreadCount error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _dio.patch('/notifications/$notificationId/read');
    } on DioException catch (error) {
      debugPrint('MarkAsRead error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _dio.patch('/notifications/mark-all-read');
    } on DioException catch (error) {
      debugPrint('MarkAllAsRead error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _dio.delete('/notifications/$notificationId');
    } on DioException catch (error) {
      debugPrint('DeleteNotification error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }

  /// Delete all notifications (with optional status filter)
  Future<void> deleteAllNotifications({String? status}) async {
    try {
      final queryParams = <String, dynamic>{
        if (status != null) 'status': status,
      };

      await _dio.delete(
        '/notifications',
        queryParameters: queryParams,
      );
    } on DioException catch (error) {
      debugPrint('DeleteAllNotifications error: ${error.response?.data}');
      throw mapDioException(error);
    }
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(dioProvider)),
  name: 'NotificationRepositoryProvider',
);
