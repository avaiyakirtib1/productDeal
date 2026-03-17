import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/notification_model.dart';
import '../../../../core/localization/app_localizations.dart';

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  IconData _getIconForType(String type) {
    switch (type) {
      case 'product_approval_needed':
      case 'product_status_changed':
        return Icons.inventory_2_outlined;
      case 'new_deal_order':
      case 'deal_status_changed':
      case 'deal_ending_24h':
      case 'deal_ending_7d':
        return Icons.local_offer_outlined;
      case 'order_status_changed':
        return Icons.shopping_cart_outlined;
      case 'daily_engagement':
        return Icons.campaign_outlined;
      case 'bulk_products_imported':
        return Icons.upload_file_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getColorForType(String type, BuildContext context) {
    switch (type) {
      case 'product_approval_needed':
        return Colors.orange;
      case 'product_status_changed':
        return Colors.blue;
      case 'new_deal_order':
      case 'deal_ending_24h':
      case 'deal_ending_7d':
        return Colors.green;
      case 'order_status_changed':
        return Colors.purple;
      case 'daily_engagement':
        return Colors.blue;
      case 'bulk_products_imported':
        return Colors.teal;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }

  String _renderText(AppLocalizations? l10n, String? key, List<String>? args, String fallback) {
    if (l10n == null || key == null || key.isEmpty) return fallback;
    return l10n.translateWithArgs(key, args ?? const []);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isUnread = notification.isUnread;
    final icon = _getIconForType(notification.type);
    final iconColor = _getColorForType(notification.type, context);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        color: isUnread
            ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : null,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _renderText(
                                l10n,
                                notification.titleKey,
                                notification.titleArgs,
                                notification.title,
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: isUnread
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _renderText(
                          l10n,
                          notification.bodyKey,
                          notification.bodyArgs,
                          notification.body,
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(notification.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 12,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
