import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/order_models.dart';

class OrderStatusTimeline extends StatelessWidget {
  const OrderStatusTimeline({
    super.key,
    required this.history,
  });

  final List<OrderStatusHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final dateFormat = DateFormat('d MMM yyyy, HH:mm');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status History',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...history.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == history.length - 1;

              return _TimelineItem(
                entry: item,
                isLast: isLast,
                dateFormat: dateFormat,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.entry,
    required this.isLast,
    required this.dateFormat,
  });

  final OrderStatusHistoryEntry entry;
  final bool isLast;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary,
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: 2,
                ),
              ),
              child: Icon(
                _getStatusIcon(entry.status),
                size: 14,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizedOrderStatus(
                    entry.status,
                    AppLocalizations.of(context)!,
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'By ${entry.changedBy.fullName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  dateFormat.format(entry.createdAt.toLocal()),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (entry.reason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Reason: ${entry.reason}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (entry.notes != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      entry.notes!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    if (status.contains('delivered')) {
      return Icons.check_circle;
    } else if (status.contains('shipped') || status.contains('transit')) {
      return Icons.local_shipping;
    } else if (status.contains('packed') || status.contains('packing')) {
      return Icons.inventory;
    } else if (status.contains('confirmed')) {
      return Icons.check;
    } else if (status.contains('cancelled')) {
      return Icons.cancel;
    } else if (status.contains('returned')) {
      return Icons.undo;
    }
    return Icons.info;
  }

}
