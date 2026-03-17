import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/currency_service.dart';
import '../../data/models/deal_models.dart';
import '../../data/repositories/deal_repository.dart';

/// Combined provider for deal progress and orders
/// This allows independent refresh without rebuilding the entire screen
final dealProgressAndOrdersProvider = FutureProvider.autoDispose
    .family<DealProgressAndOrders, String>((ref, dealId) async {
  final repo = ref.watch(dealRepositoryProvider);

  // Fetch both in parallel
  final results = await Future.wait([
    repo.fetchDealDetail(dealId),
    repo.fetchOrdersForDeal(dealId),
  ]);

  final detail = results[0] as DealDetail;
  final orders = results[1] as List<DealOrder>;

  final isEnded = detail.isEnded;
  final progressPercent = isEnded
      ? 100.0
      : (detail.progress?.percent ?? detail.progressPercent);
  final progress = DealProgress(
    received: detail.progress?.received ?? detail.receivedQuantity,
    target: detail.progress?.target ?? detail.targetQuantity,
    percent: progressPercent,
    orderCount: detail.progress?.orderCount ?? detail.orderCount,
  );

  return DealProgressAndOrders(
    isEnded: isEnded,
    progress: progress,
    orders: orders,
  );
});

class DealProgressAndOrders {
  final DealProgress progress;
  final List<DealOrder> orders;
  final bool isEnded;

  DealProgressAndOrders({
    required this.progress,
    required this.orders,
    this.isEnded = false,
  });
}

/// Combined widget for Progress Card + Order List
/// Auto-refreshes every 5 seconds without rebuilding parent
class DealProgressAndOrdersCard extends ConsumerStatefulWidget {
  const DealProgressAndOrdersCard({
    super.key,
    required this.dealId,
    this.autoRefresh = true,
  });

  final String dealId;
  final bool autoRefresh;

  @override
  ConsumerState<DealProgressAndOrdersCard> createState() =>
      _DealProgressAndOrdersCardState();
}

class _DealProgressAndOrdersCardState
    extends ConsumerState<DealProgressAndOrdersCard> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    if (widget.autoRefresh) {
      _startAutoRefresh();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Refresh every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        debugPrint('Auto-refreshing deal progress and orders');
        ref.invalidate(dealProgressAndOrdersProvider(widget.dealId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataAsync = ref.watch(dealProgressAndOrdersProvider(widget.dealId));

    return dataAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  (AppLocalizations.of(context)?.unableToLoadProgress
                          .replaceAll('{detail}', error.toString()) ??
                      'Unable to load progress: $error'),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
      data: (data) => _buildContent(context, theme, data),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    DealProgressAndOrders data,
  ) {
    return Column(
      children: [
        // Progress Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.dealProgress ?? 'Deal Progress',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${data.progress.percent.toStringAsFixed(1)}%',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.refresh,
                          size: 16,
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (data.progress.percent / 100).clamp(0.0, 1.0),
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 12),
                if (data.isEnded)
                  Text(
                    AppLocalizations.of(context)?.dealClosed ?? 'Deal Closed',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${data.progress.received} ${AppLocalizations.of(context)?.ordered ?? 'ordered'}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '${data.progress.target} ${AppLocalizations.of(context)?.target ?? 'target'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                if (!data.isEnded) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${data.progress.orderCount} ${data.progress.orderCount == 1 ? (AppLocalizations.of(context)?.orderPlacedSuffix ?? 'order placed') : (AppLocalizations.of(context)?.ordersPlacedSuffix ?? 'orders placed')}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.recentOrders ?? 'Recent Orders',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (data.orders.isNotEmpty)
                      Text(
                        '${data.orders.length} ${data.orders.length == 1 ? (AppLocalizations.of(context)?.order ?? 'order') : (AppLocalizations.of(context)?.orders ?? 'orders')}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (data.orders.isEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)?.noOrdersPlacedYet ??
                              'No orders have been placed on this deal yet.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  ...data.orders.take(5).map((order) {
                    final createdAt = order.createdAt;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: Text(
                        '${order.quantity} units · '
                        '${context.formatPriceEurOnly(order.totalAmount)} '
                        '(${context.formatPriceUsdFromEur(order.totalAmount)})',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '${order.status.name.toUpperCase()} · ${_formatDate(createdAt)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (order.orderType == 'reservation')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.tertiaryContainer
                                    .withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Reservation',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onTertiaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: Icon(
                        _iconForOrderStatus(order.status),
                        size: 16,
                        color: _colorForOrderStatus(theme, order.status),
                      ),
                    );
                  }),
                if (data.orders.length > 5) ...[
                  const Divider(),
                  Center(
                    child: Text(
                      '+${data.orders.length - 5} more orders',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _iconForOrderStatus(DealOrderStatus status) {
    switch (status) {
      case DealOrderStatus.pending:
        return Icons.schedule;
      case DealOrderStatus.confirmed:
        return Icons.check_circle_outline;
      case DealOrderStatus.shipped:
        return Icons.local_shipping;
      case DealOrderStatus.delivered:
        return Icons.check_circle;
      case DealOrderStatus.cancelled:
        return Icons.cancel_outlined;
      case DealOrderStatus.refunded:
        return Icons.money_off;
    }
  }

  Color _colorForOrderStatus(ThemeData theme, DealOrderStatus status) {
    switch (status) {
      case DealOrderStatus.pending:
        return Colors.orange;
      case DealOrderStatus.confirmed:
        return Colors.blue;
      case DealOrderStatus.shipped:
        return Colors.purple;
      case DealOrderStatus.delivered:
        return Colors.green;
      case DealOrderStatus.cancelled:
        return Colors.red;
      case DealOrderStatus.refunded:
        return Colors.grey;
    }
  }
}
