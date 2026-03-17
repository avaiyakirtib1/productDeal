import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationController extends AsyncNotifier<NotificationListResponse> {
  int _currentPage = 1;
  final String _status = 'all';
  String? _type;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  @override
  Future<NotificationListResponse> build() async {
    _currentPage = 1;
    _hasMore = true;
    return _loadNotifications(page: 1, refresh: true);
  }

  Future<NotificationListResponse> _loadNotifications({
    int page = 1,
    bool refresh = false,
  }) async {
    final repo = ref.read(notificationRepositoryProvider);
    final response = await repo.getNotifications(
      page: page,
      limit: 20,
      status: _status == 'all' ? null : _status,
      type: _type,
    );

    _hasMore = response.pagination.hasMore;
    return response;
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;

    final current = state.valueOrNull;
    if (current == null) return;

    _currentPage++;
    final newResponse = await _loadNotifications(page: _currentPage);

    state = AsyncData(NotificationListResponse(
      notifications: [
        ...current.notifications,
        ...newResponse.notifications,
      ],
      unreadCount: newResponse.unreadCount,
      pagination: newResponse.pagination,
    ));
  }

  Future<void> markAsRead(String notificationId) async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.markAsRead(notificationId);

    // Update local state
    final current = state.valueOrNull;
    if (current != null) {
      final updatedNotifications = current.notifications.map((notif) {
        if (notif.id == notificationId) {
          return notif.copyWith(
            status: 'read',
            readAt: DateTime.now(),
          );
        }
        return notif;
      }).toList();

      state = AsyncData(NotificationListResponse(
        notifications: updatedNotifications,
        unreadCount: current.unreadCount - 1,
        pagination: current.pagination,
      ));
    }

    // Refresh unread count
    ref.invalidate(unreadCountProvider);
  }

  Future<void> markAllAsRead() async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.markAllAsRead();

    // Update local state
    final current = state.valueOrNull;
    if (current != null) {
      final updatedNotifications = current.notifications
          .map((notif) => notif.copyWith(
                status: 'read',
                readAt: DateTime.now(),
              ))
          .toList();

      state = AsyncData(NotificationListResponse(
        notifications: updatedNotifications,
        unreadCount: 0,
        pagination: current.pagination,
      ));
    }

    // Refresh unread count
    ref.invalidate(unreadCountProvider);
  }

  Future<void> deleteNotification(String notificationId) async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.deleteNotification(notificationId);

    // Update local state
    final current = state.valueOrNull;
    if (current != null) {
      final updatedNotifications = current.notifications
          .where((notif) => notif.id != notificationId)
          .toList();

      state = AsyncData(NotificationListResponse(
        notifications: updatedNotifications,
        unreadCount: current.unreadCount,
        pagination: PaginationInfo(
          page: current.pagination.page,
          limit: current.pagination.limit,
          total: current.pagination.total - 1,
          totalPages: current.pagination.totalPages,
        ),
      ));
    }
  }

  Future<void> deleteAllNotifications() async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.deleteAllNotifications();

    // Reset state
    ref.invalidate(notificationControllerProvider);
    ref.invalidate(unreadCountProvider);
  }
}

final notificationControllerProvider =
    AsyncNotifierProvider<NotificationController, NotificationListResponse>(
  () => NotificationController(),
  name: 'NotificationControllerProvider',
);

/// Provider for unread notification count
final unreadCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return await repo.getUnreadCount();
}, name: 'UnreadCountProvider');
