import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../data/models/notification_model.dart';
import '../controllers/notification_controller.dart';
import '../widgets/notification_item.dart';

class NotificationHistoryScreen extends ConsumerStatefulWidget {
  const NotificationHistoryScreen({super.key});

  static const routePath = '/notifications';
  static const routeName = 'notifications';

  @override
  ConsumerState<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState
    extends ConsumerState<NotificationHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedFilter = 'all'; // 'all', 'unread', 'read'

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      final controller = ref.read(notificationControllerProvider.notifier);
      if (controller.hasMore) {
        controller.loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final notificationState = ref.watch(notificationControllerProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.notifications ?? 'Notifications',
        ),
        actions: [
          // Unread count badge
          if (unreadCount.valueOrNull != null && unreadCount.valueOrNull! > 0)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    // Show filter options
                    _showFilterDialog(context);
                  },
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount.valueOrNull! > 99
                          ? '99+'
                          : '${unreadCount.valueOrNull}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            )
          else
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                _showFilterDialog(context);
              },
            ),
          // Mark all as read
          if (unreadCount.valueOrNull != null && unreadCount.valueOrNull! > 0)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'mark_all_read') {
                  await _performWithLoader(
                    context,
                    () => ref
                        .read(notificationControllerProvider.notifier)
                        .markAllAsRead(),
                    onSuccess: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)?.markedAllAsRead ??
                                'All marked as read',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  );
                } else if (value == 'delete_all') {
                  _showDeleteAllDialog(context);
                }
              },
              itemBuilder: (context) {
                final l10n = AppLocalizations.of(context);
                return [
                  PopupMenuItem(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        const Icon(Icons.done_all, size: 20),
                        const SizedBox(width: 8),
                        Text(l10n?.markAllAsRead ?? 'Mark all as read'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete_all',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, size: 20),
                        const SizedBox(width: 8),
                        Text(l10n?.deleteAll ?? 'Delete all'),
                      ],
                    ),
                  ),
                ];
              },
            ),
        ],
      ),
      body: notificationState.when(
        data: (data) {
          if (data.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)?.noNotifications ??
                        'No notifications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)?.youreAllCaughtUp ??
                        "You're all caught up!",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationControllerProvider);
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount:
                  data.notifications.length + (data.pagination.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == data.notifications.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final notification = data.notifications[index];
                return NotificationItem(
                  notification: notification,
                  onTap: () async {
                    // Mark as read and navigate
                    if (notification.isUnread) {
                      await ref
                          .read(notificationControllerProvider.notifier)
                          .markAsRead(notification.id);
                    }
                    _handleNotificationTap(notification);
                  },
                  onDelete: () async {
                    await ref
                        .read(notificationControllerProvider.notifier)
                        .deleteNotification(notification.id);
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('${l10n?.error ?? 'Error'}: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(notificationControllerProvider);
                },
                child: Text(l10n?.retry ?? 'Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.filterNotifications),
        content: RadioGroup<String>(
          groupValue: _selectedFilter,
          onChanged: (value) {
            setState(() {
              _selectedFilter = value!;
            });
            Navigator.pop(dialogContext);
            ref.invalidate(notificationControllerProvider);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text(l10n.all),
                value: 'all',
              ),
              RadioListTile<String>(
                title: Text(l10n.unread),
                value: 'unread',
              ),
              RadioListTile<String>(
                title: Text(l10n.read),
                value: 'read',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAllDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteAllNotificationsConfirm),
        content: Text(l10n.deleteAllNotificationsMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _performWithLoader(
                context,
                () => ref
                    .read(notificationControllerProvider.notifier)
                    .deleteAllNotifications(),
                onSuccess: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)
                                ?.deleteAllNotificationsSuccess ??
                            'All notifications deleted',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  ref.invalidate(notificationControllerProvider);
                },
              );
            },
            child:
                Text(l10n.deleteAll, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Shows a loading overlay, runs the action, then hides and calls onSuccess.
  Future<void> _performWithLoader(
    BuildContext context,
    Future<void> Function() action, {
    VoidCallback? onSuccess,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(l10n.pleaseWait),
              ],
            ),
          ),
        ),
      ),
    );
    try {
      await action();
      if (context.mounted) navigator.pop(context);
      onSuccess?.call();
    } catch (e) {
      if (context.mounted) navigator.pop(context);
      if (context.mounted) {
        final l10nErr = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10nErr.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    final data = notification.data;
    if (data == null) return;

    final type = notification.type;

    // Navigate based on notification type
    switch (type) {
      case 'product_approval_needed':
      case 'product_status_changed':
        if (data['productId'] != null) {
          // Navigate to product detail
          context.push('/products/${data['productId']}');
        }
        break;
      case 'new_deal_order':
      case 'deal_status_changed':
      case 'deal_ending_24h':
      case 'deal_ending_7d':
        if (data['dealId'] != null) {
          // Navigate to deal detail
          context.push('/deals/${data['dealId']}');
        }
        break;
      case 'order_status_changed':
        if (data['orderId'] != null) {
          // Navigate to order detail
          context.push('/orders/my/${data['orderId']}');
        }
        break;
      default:
        // No specific navigation
        break;
    }
  }
}
