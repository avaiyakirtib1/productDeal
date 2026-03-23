import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/currency_controller.dart';
import '../../../../core/services/currency_service.dart';
import '../../data/models/deal_models.dart';
import '../../data/repositories/deal_repository.dart';
import '../../../../shared/utils/snackbar_utils.dart';
import 'create_deal_shipment_modal.dart';
import 'deal_progress_and_orders.dart';

/// Provider for deal orders with management capabilities
final dealOrdersManagementProvider = FutureProvider.autoDispose
    .family<List<DealOrder>, String>((ref, dealId) async {
  final repo = ref.watch(dealRepositoryProvider);
  return repo.fetchOrdersForDeal(dealId);
});

/// Order management widget for Admin/Wholesaler
class DealOrderManagementWidget extends ConsumerWidget {
  const DealOrderManagementWidget({
    super.key,
    required this.dealId,
    required this.canManage,
    this.onPaymentStatusChange,
  });

  final String dealId;
  final bool canManage;
  /// Called when an order is marked as paid so the final payment section can refresh.
  final VoidCallback? onPaymentStatusChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
        currencyControllerProvider); // Rebuild when display currency changes
    final ordersAsync = ref.watch(dealOrdersManagementProvider(dealId));
    final theme = Theme.of(context);

    return ordersAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(height: 8),
              Text(
                '${AppLocalizations.of(context)?.errorLoadingOrders ?? 'Error loading orders'}: $error',
              ),
            ],
          ),
        ),
      ),
      data: (orders) {
        if (!canManage) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.orderManagement ??
                          'Order Management',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${orders.length} ${orders.length == 1 ? (AppLocalizations.of(context)?.orderCountSuffix ?? 'order') : (AppLocalizations.of(context)?.orders ?? 'orders')}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (orders.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)?.noOrdersYet ??
                                'No orders yet',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...orders.map((order) => _OrderManagementTile(
                        order: order,
                        onStatusUpdate: () async {
                          ref.invalidate(dealOrdersManagementProvider(dealId));
                          ref.invalidate(dealProgressAndOrdersProvider(dealId));
                          onPaymentStatusChange?.call();
                          await ref.read(dealOrdersManagementProvider(dealId).future);
                        },
                      )),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrderManagementTile extends ConsumerStatefulWidget {
  const _OrderManagementTile({
    required this.order,
    required this.onStatusUpdate,
  });

  final DealOrder order;
  final Future<void> Function() onStatusUpdate;

  @override
  ConsumerState<_OrderManagementTile> createState() =>
      _OrderManagementTileState();
}

class _OrderManagementTileState extends ConsumerState<_OrderManagementTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = widget.order;
    final statusColor = _getStatusColor(theme, order.status);
    final statusIcon = _getStatusIcon(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (expanded) {
          setState(() => _isExpanded = expanded);
        },
        leading: Icon(statusIcon, color: statusColor),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${order.quantity} units · '
                    '${context.formatPriceEurOnly(order.totalAmount)} '
                    '(${context.formatPriceUsdFromEur(order.totalAmount)})',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (order.buyer != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      order.buyer!.businessName ??
                          order.buyer!.name ??
                          'Unknown buyer',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                order.status.name.toUpperCase(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          'Placed ${_formatDate(order.createdAt)}',
          style: theme.textTheme.bodySmall,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Details
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return _DetailRow(
                      label: l10n?.quantity ?? 'Quantity',
                      value: '${order.quantity} ${l10n?.units ?? 'units'}',
                    );
                  },
                ),
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return _DetailRow(
                      label: l10n?.unitPrice ?? 'Unit Price',
                      value: '${context.formatPriceEurOnly(order.unitPrice)} '
                          '(${context.formatPriceUsdFromEur(order.unitPrice)})',
                    );
                  },
                ),
                Builder(
                  builder: (context) {
                    final subtotal = order.quantity * order.unitPrice;
                    return _DetailRow(
                      label: 'Subtotal',
                      value: '${context.formatPriceEurOnly(subtotal)} '
                          '(${context.formatPriceUsdFromEur(subtotal)})',
                    );
                  },
                ),
                if (order.shippingCost > 0) ...[
                  Builder(
                    builder: (context) {
                      return _DetailRow(
                        label: 'Shipping',
                        value:
                            '${context.formatPriceEurOnly(order.shippingCost)} '
                            '(${context.formatPriceUsdFromEur(order.shippingCost)})',
                      );
                    },
                  ),
                ],
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return _DetailRow(
                      label: l10n?.totalAmount ?? 'Total Amount',
                      value: '${context.formatPriceEurOnly(order.totalAmount)} '
                          '(${context.formatPriceUsdFromEur(order.totalAmount)})',
                      isHighlight: true,
                    );
                  },
                ),
                _DetailRow(
                  label: 'Payment',
                  value: order.isPaid ? 'Paid' : 'Pending',
                ),
                if (order.paymentReportedByBuyerAt != null ||
                    (order.paymentReportedNotes != null &&
                        order.paymentReportedNotes!.isNotEmpty)) ...[
                  const Divider(),
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.buyerReportedPayment ?? "Buyer's payment info",
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (order.paymentReportedByBuyerAt != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '${l10n?.reportedAt ?? 'Reported at'}: ${DateFormat('d MMM yyyy, HH:mm').format(order.paymentReportedByBuyerAt!)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          if (order.paymentReportedNotes != null &&
                              order.paymentReportedNotes!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                order.paymentReportedNotes!,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
                if (order.buyer != null) ...[
                  const Divider(),
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return _DetailRow(
                        label: l10n?.buyer ?? 'Buyer',
                        value: order.buyer!.businessName ??
                            order.buyer!.name ??
                            (l10n?.unknown ?? 'Unknown'),
                      );
                    },
                  ),
                  if (order.buyer!.email != null)
                    Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return _DetailRow(
                          label: l10n?.email ?? 'Email',
                          value: order.buyer!.email!,
                        );
                      },
                    ),
                ],
                if (order.trackingNumber != null) ...[
                  const Divider(),
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return _DetailRow(
                        label: l10n?.trackingNumber ?? 'Tracking Number',
                        value: order.trackingNumber!,
                      );
                    },
                  ),
                  if (order.carrier != null)
                    Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return _DetailRow(
                          label: l10n?.carrier ?? 'Carrier',
                          value: order.carrier!,
                        );
                      },
                    ),
                  if (order.trackingUrl != null)
                    InkWell(
                      onTap: () async {
                        final uri = Uri.parse(order.trackingUrl!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return _DetailRow(
                            label: l10n?.trackingUrl ?? 'Tracking URL',
                            value:
                                l10n?.openTrackingLink ?? 'Open tracking link',
                            icon: Icons.open_in_new,
                          );
                        },
                      ),
                    ),
                ],
                if (order.notes != null && order.notes!.isNotEmpty) ...[
                  const Divider(),
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return _DetailRow(
                        label: l10n?.notes ?? 'Notes',
                        value: order.notes!,
                      );
                    },
                  ),
                ],
                // Status Timeline
                if (order.confirmedAt != null ||
                    order.shippedAt != null ||
                    order.deliveredAt != null) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Text(
                        l10n?.statusTimeline ?? 'Status Timeline',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  if (order.confirmedAt != null)
                    Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return _TimelineItem(
                          icon: Icons.check_circle_outline,
                          label: l10n?.confirmed ?? 'Confirmed',
                          date: order.confirmedAt!,
                          color: Colors.blue,
                        );
                      },
                    ),
                  if (order.shippedAt != null)
                    Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return _TimelineItem(
                          icon: Icons.local_shipping,
                          label: l10n?.shipped ?? 'Shipped',
                          date: order.shippedAt!,
                          color: Colors.purple,
                        );
                      },
                    ),
                  if (order.deliveredAt != null)
                    Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return _TimelineItem(
                          icon: Icons.check_circle,
                          label: l10n?.delivered ?? 'Delivered',
                          date: order.deliveredAt!,
                          color: Colors.green,
                        );
                      },
                    ),
                ],
                // Action Buttons
                const Divider(),
                const SizedBox(height: 8),
                _OrderActionButtons(
                  order: order,
                  onStatusUpdate: widget.onStatusUpdate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ThemeData theme, DealOrderStatus status) {
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

  IconData _getStatusIcon(DealOrderStatus status) {
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return DateFormat('d MMM yyyy, HH:mm').format(date);
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
    this.icon,
  });

  final String label;
  final String value;
  final bool isHighlight;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          isHighlight ? FontWeight.bold : FontWeight.normal,
                      color: isHighlight ? theme.colorScheme.primary : null,
                    ),
                  ),
                ),
                if (icon != null)
                  Icon(icon, size: 16, color: theme.colorScheme.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.icon,
    required this.label,
    required this.date,
    required this.color,
  });

  final IconData icon;
  final String label;
  final DateTime date;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            DateFormat('d MMM, HH:mm').format(date),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderActionButtons extends ConsumerStatefulWidget {
  const _OrderActionButtons({
    required this.order,
    required this.onStatusUpdate,
  });

  final DealOrder order;
  final Future<void> Function() onStatusUpdate;

  @override
  ConsumerState<_OrderActionButtons> createState() =>
      _OrderActionButtonsState();
}

class _OrderActionButtonsState extends ConsumerState<_OrderActionButtons> {
  bool _isProcessing = false;

  Future<void> _confirmOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n?.confirmOrder ?? 'Confirm Order'),
          content: Text(l10n?.confirmOrderMessage ??
              'Are you sure you want to confirm this order?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n?.cancel ?? 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n?.confirm ?? 'Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      final repo = ref.read(dealRepositoryProvider);
      await repo.confirmOrderAdmin(widget.order.id);
      if (!mounted) return;
      SnackbarUtils.showSuccess(
        context,
        AppLocalizations.of(context)?.orderConfirmedSuccess ??
            'Order confirmed successfully',
      );
      await widget.onStatusUpdate();
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(
          context,
          '${AppLocalizations.of(context)?.failedToConfirmOrder ?? 'Failed to confirm order'}: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _createShipment() async {
    await showDialog(
      context: context,
      builder: (context) => CreateDealShipmentModal(
        order: widget.order,
        onSuccess: widget.onStatusUpdate,
      ),
    );
  }

  Future<void> _deliverOrder() async {
    final notesController = TextEditingController();

    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n?.markAsDelivered ?? 'Mark as Delivered'),
          content: TextField(
            controller: notesController,
            decoration: InputDecoration(
              labelText: l10n?.deliveryNotesOptional ?? 'Delivery Notes (Optional)',
            ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              notesController.text.trim().isEmpty
                  ? null
                  : notesController.text.trim(),
            ),
            child: Text(l10n?.markDelivered ?? 'Mark Delivered'),
          ),
        ],
        );
      },
    );

    if (result == null) return;

    setState(() => _isProcessing = true);
    try {
      final repo = ref.read(dealRepositoryProvider);
      await repo.deliverOrderAdmin(orderId: widget.order.id, notes: result);
      if (!mounted) return;
      SnackbarUtils.showSuccess(
        context,
        AppLocalizations.of(context)?.orderMarkedDelivered ??
            'Order marked as delivered',
      );
      await widget.onStatusUpdate();
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(
          context,
          '${AppLocalizations.of(context)?.failedToMarkDelivered ?? 'Failed to mark order as delivered'}: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _cancelOrder() async {
    final reasonController = TextEditingController();

    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n?.cancelOrder ?? 'Cancel Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n?.cancelOrderConfirm ??
                  'Are you sure you want to cancel this order?'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: l10n?.reasonOptional ?? 'Reason (Optional)',
                ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n?.no ?? 'No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              reasonController.text.trim().isEmpty
                  ? null
                  : reasonController.text.trim(),
            ),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n?.cancelOrder ?? 'Cancel Order'),
          ),
        ],
        );
      },
    );

    if (result == null) return;

    setState(() => _isProcessing = true);
    try {
      final repo = ref.read(dealRepositoryProvider);
      await repo.cancelOrderAdmin(widget.order.id, reason: result);
      if (!mounted) return;
      SnackbarUtils.showSuccess(
        context,
        AppLocalizations.of(context)?.orderCancelled ?? 'Order cancelled',
      );
      await widget.onStatusUpdate();
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(
          context,
          '${AppLocalizations.of(context)?.failedToCancelOrder ?? 'Failed to cancel order'}: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _markAsPaid() async {
    final l10n = AppLocalizations.of(context);
    final notesController = TextEditingController();

    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.markAsPaid ?? 'Mark as paid'),
        content: TextField(
          controller: notesController,
          decoration: InputDecoration(
            labelText: l10n?.paymentNotesOptional ?? 'Payment notes (e.g. bank reference)',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(notesController.text.trim()),
            child: Text(l10n?.markAsPaid ?? 'Mark as paid'),
          ),
        ],
      ),
    );

    if (result == null) return;

    setState(() => _isProcessing = true);
    try {
      final repo = ref.read(dealRepositoryProvider);
      await repo.markDealOrderPaid(widget.order.id, notes: result.trim().isEmpty ? null : result.trim());
      if (!mounted) return;
      SnackbarUtils.showSuccess(
        context,
        AppLocalizations.of(context)?.orderMarkedPaid ?? 'Order marked as paid',
      );
      await widget.onStatusUpdate();
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(
          context,
          '${AppLocalizations.of(context)?.failedToMarkOrderPaid ?? 'Failed to mark order as paid'}: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _reduceQuantity() async {
    final order = widget.order;
    final quantityController = TextEditingController(text: '${order.quantity}');

    final result = await showDialog<int?>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n?.reduceQuantity ?? 'Reduce quantity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.reduceQuantityHint ??
                    'Enter the new quantity. Minimum is 1 (or the deal\'s min order quantity). Use 0 to cancel this order.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n?.newQuantity ?? 'New quantity',
                ),
              onSubmitted: (v) {
                final n = int.tryParse(v);
                if (n != null) Navigator.of(context).pop(n);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final n = int.tryParse(quantityController.text.trim());
              if (n != null && n >= 0) {
                Navigator.of(context).pop(n);
              }
            },
            child: Text(l10n?.update ?? 'Update'),
          ),
        ],
        );
      },
    );

    if (result == null) return;

    setState(() => _isProcessing = true);
    try {
      final repo = ref.read(dealRepositoryProvider);
      await repo.reduceOrderQuantityAdmin(widget.order.id, result);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      SnackbarUtils.showSuccess(
        context,
        result == 0
            ? (l10n?.orderCancelled ?? 'Order cancelled')
            : '${l10n?.quantityUpdatedTo ?? 'Quantity updated to'} $result',
      );
      await widget.onStatusUpdate();
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(
          context,
          '${AppLocalizations.of(context)?.failedToUpdateQuantity ?? 'Failed to update quantity'}: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final l10n = AppLocalizations.of(context);

    return Stack(
      children: [
        Opacity(
          opacity: _isProcessing ? 0.6 : 1,
          child: IgnorePointer(
            ignoring: _isProcessing,
            child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (!order.isPaid &&
            order.status != DealOrderStatus.cancelled &&
            order.status != DealOrderStatus.refunded) ...[
          OutlinedButton.icon(
            onPressed: () async {
              try {
                await ref.read(dealRepositoryProvider).sendDealOrderPaymentInstructions(order.id);
                if (!context.mounted) return;
                SnackbarUtils.showSuccess(
                  context,
                  l10n?.invoiceInstructionsSent ?? 'Payment instructions were sent by email.',
                );
              } catch (e) {
                if (!context.mounted) return;
                SnackbarUtils.showError(context, '${l10n?.failedToPlaceOrder ?? 'Failed'}: $e');
              }
            },
            icon: const Icon(Icons.email_outlined, size: 18),
            label: Text(l10n?.sendPaymentInstructions ?? 'Send Payment Instructions'),
          ),
          FilledButton.icon(
            onPressed: _markAsPaid,
            icon: const Icon(Icons.payment, size: 18),
            label: Text(l10n?.markAsPaid ?? 'Mark as paid'),
            style: FilledButton.styleFrom(backgroundColor: Colors.teal),
          ),
        ],
        if (order.status == DealOrderStatus.pending)
          FilledButton.icon(
            onPressed: _confirmOrder,
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: Text(l10n?.confirm ?? 'Confirm'),
            style: FilledButton.styleFrom(backgroundColor: Colors.blue),
          ),
        if (order.status == DealOrderStatus.confirmed)
          FilledButton.icon(
            onPressed: _createShipment,
            icon: const Icon(Icons.local_shipping, size: 18),
            label: Text(l10n?.createShipment ?? 'Create Shipment'),
            style: FilledButton.styleFrom(backgroundColor: Colors.purple),
          ),
        if (order.status == DealOrderStatus.shipped)
          FilledButton.icon(
            onPressed: _deliverOrder,
            icon: const Icon(Icons.check_circle, size: 18),
            label: Text(l10n?.markDelivered ?? 'Mark Delivered'),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
          ),
        if (order.status != DealOrderStatus.delivered &&
            order.status != DealOrderStatus.cancelled &&
            order.status != DealOrderStatus.refunded) ...[
          OutlinedButton.icon(
            onPressed: _reduceQuantity,
            icon: const Icon(Icons.edit, size: 18),
            label: Text(l10n?.reduceQuantity ?? 'Reduce quantity'),
          ),
          OutlinedButton.icon(
            onPressed: _cancelOrder,
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: Text(l10n?.cancel ?? 'Cancel'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ],
            ),
          ),
        ),
        if (_isProcessing)
          const Positioned.fill(
            child: Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      ],
    );
  }
}
