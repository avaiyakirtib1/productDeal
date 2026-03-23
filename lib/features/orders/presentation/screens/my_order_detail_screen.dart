import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/currency_controller.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../features/auth/data/models/auth_models.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../data/models/order_models.dart';
import '../../data/repositories/order_repository.dart';
import '../../../../shared/utils/snackbar_utils.dart';
import '../widgets/shipment_timeline.dart';
import '../widgets/order_status_timeline.dart';
import '../widgets/create_shipment_modal.dart';

final myOrderDetailProvider =
    FutureProvider.autoDispose.family<OrderSummary, String>((ref, id) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.fetchOrderDetail(id);
});

/// Show Send Payment Instructions when: order has invoice/bank_transfer, OR
/// user (wholesaler) has payment config, OR user is admin (can send for any order).
bool _shouldShowSendPaymentInstructions(
  OrderSummary order,
  bool canManageOrder,
  UserModel? currentUser,
) {
  if (!canManageOrder || currentUser == null) return false;
  if (order.paymentMethod == 'invoice' || order.paymentMethod == 'bank_transfer') {
    return true;
  }
  // Even for cash_on_delivery: show if wholesaler has payment config or user is admin
  final isAdmin = currentUser.role == UserRole.admin || currentUser.role == UserRole.subAdmin;
  if (isAdmin) return true;
  final hasPaymentConfig = (currentUser.effectiveIban ?? '').trim().isNotEmpty;
  return hasPaymentConfig;
}

/// Show Report Payment when: order has invoice/bank_transfer, OR
/// buyer's defaultPaymentMode is bank_transfer/invoice (they prefer to pay that way).
bool _shouldShowReportPayment(
  OrderSummary order,
  bool canManageOrder,
  UserModel? currentUser,
) {
  if (canManageOrder || currentUser == null) return false;
  if (order.paymentStatus == 'completed') return false;
  if (order.paymentMethod == 'invoice' || order.paymentMethod == 'bank_transfer') {
    return true;
  }
  // Even for cash_on_delivery: show if buyer has payment preference set
  final mode = currentUser.defaultPaymentMode;
  return mode == 'bank_transfer' || mode == 'invoice';
}

String _paymentMethodLabel(String method, AppLocalizations? l10n) {
  switch (method) {
    case 'cash_on_delivery':
      return l10n?.paymentMethodCash ?? l10n?.cashOnDelivery ?? 'Cash on Delivery';
    case 'invoice':
      return l10n?.paymentMethodInvoice ?? 'Invoice';
    case 'bank_transfer':
      return l10n?.paymentMethodBankTransfer ?? 'Bank Transfer';
    case 'online':
    case 'card':
      return l10n?.payWithCard ?? 'Pay with Card';
    default:
      // Fallback: prettified enum string
      return method
          .replaceAll('_', ' ')
          .split(' ')
          .map((w) => w.isEmpty ? w : (w[0].toUpperCase() + w.substring(1)))
          .join(' ');
  }
}

class MyOrderDetailScreen extends ConsumerStatefulWidget {
  const MyOrderDetailScreen({super.key, required this.orderId});

  static const routePath = '/orders/my/:id';
  static const routeName = 'myOrderDetail';

  final String orderId;

  @override
  ConsumerState<MyOrderDetailScreen> createState() =>
      _MyOrderDetailScreenState();
}

class _MyOrderDetailScreenState extends ConsumerState<MyOrderDetailScreen> {
  @override
  Widget build(BuildContext context) {
    ref.watch(
        currencyControllerProvider); // Rebuild when display currency changes
    final orderAsync = ref.watch(myOrderDetailProvider(widget.orderId));
    final currentUser = ref.watch(authControllerProvider).valueOrNull?.user;
    final isAdmin = currentUser?.role == UserRole.admin ||
        currentUser?.role == UserRole.subAdmin;
    final isWholesaler = currentUser?.role == UserRole.wholesaler;

    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.orderDetails ?? 'Order Details'),
        elevation: 0,
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                  '${l10n?.unableToLoadOrder ?? 'Unable to load order'}: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(myOrderDetailProvider(widget.orderId)),
                child: Text(l10n?.retry ?? 'Retry'),
              ),
            ],
          ),
        ),
        data: (order) {
          // Admin can manage any order; wholesaler only if they own items (product owner)
          final isOrderOwner = currentUser != null &&
              order.items.any((item) => item.wholesalerId == currentUser.id);
          final canManageOrder =
              isAdmin || (isWholesaler && isOrderOwner);
          debugPrint('canManageOrder: $canManageOrder');
          debugPrint('isOrderOwner: $isOrderOwner');
          debugPrint('isAdmin: $isAdmin');
          debugPrint('isWholesaler: $isWholesaler');
          debugPrint('currentUser: ${currentUser?.id}');
          debugPrint('order.items: ${order.items.map((item) => item.wholesalerId)}');

          final created =
              DateFormat('d MMM yyyy, HH:mm').format(order.createdAt.toLocal());

          // Group items by wholesalerId
          final Map<String, List<OrderItemSummary>> byWholesaler = {};
          for (final item in order.items) {
            byWholesaler.putIfAbsent(item.wholesalerId, () => []).add(item);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myOrderDetailProvider(widget.orderId));
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
              children: [
                // Order Header Card
                _OrderHeaderCard(
                  order: order,
                  created: created,
                  canManageOrder: canManageOrder,
                  currentUser: currentUser,
                  onStatusUpdate: () {
                    ref.invalidate(myOrderDetailProvider(widget.orderId));
                  },
                  onMarkAsPaid: canManageOrder &&
                        order.paymentStatus != 'completed'
                    ? () async {
                        try {
                          await ref
                              .read(orderRepositoryProvider)
                              .updateOrderPaymentStatus(
                                  widget.orderId, 'completed');
                          if (!context.mounted) return;
                          ref.invalidate(myOrderDetailProvider(widget.orderId));
                          SnackbarUtils.showSuccess(
                            context,
                            l10n?.orderMarkedPaid ?? 'Order marked as paid',
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          SnackbarUtils.showError(
                            context,
                            '${l10n?.failedToMarkOrderPaid ?? 'Failed'}: $e',
                          );
                        }
                      }
                    : null,
                onSendPaymentInstructions: _shouldShowSendPaymentInstructions(
                          order, canManageOrder, currentUser)
                      ? () async {
                          try {
                            await ref
                                .read(orderRepositoryProvider)
                                .sendPaymentInstructions(widget.orderId);
                            if (!context.mounted) return;
                            SnackbarUtils.showSuccess(
                              context,
                              l10n?.invoiceInstructionsSent ??
                                  'Payment instructions were sent by email.',
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            SnackbarUtils.showError(
                              context,
                              '${l10n?.failedToPlaceOrder ?? 'Failed'}: $e',
                            );
                          }
                        }
                      : null,
                  onReportPayment: _shouldShowReportPayment(
                          order, canManageOrder, currentUser)
                      ? () => _showReportPaymentDialog(
                            context,
                            ref,
                            widget.orderId,
                            l10n,
                          )
                      : null,
                ),
                const SizedBox(height: 5),

                // Order Items
                ...byWholesaler.entries.map((entry) {
                  final items = entry.value;
                  return _OrderItemsCard(
                    items: items,
                    orderId: order.id,
                    canManageOrder: canManageOrder,
                    currentUserId: currentUser?.id,
                    onItemStatusUpdate: () {
                      ref.invalidate(myOrderDetailProvider(widget.orderId));
                    },
                  );
                }),

                // Shipping Address
                if (order.shippingAddress != null) ...[
                  const SizedBox(height: 5),
                  _ShippingAddressCard(address: order.shippingAddress!),
                ],

                // Shipments Timeline
                if (order.shipments != null && order.shipments!.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  ShipmentTimeline(shipments: order.shipments!),
                ],

                // Status History
                if (order.statusHistory != null &&
                    order.statusHistory!.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  OrderStatusTimeline(history: order.statusHistory!),
                ],

                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

void _showReportPaymentDialog(
  BuildContext context,
  WidgetRef ref,
  String orderId,
  AppLocalizations? l10n,
) {
  final refController = TextEditingController();
  final txController = TextEditingController();
  final bankController = TextEditingController();
  final notesController = TextEditingController();
  bool isSubmitting = false;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l10n?.reportPayment ?? "I've made the payment"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n?.reportPaymentSubtitle ??
                    'Share your payment details so we can verify',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: refController,
                decoration: InputDecoration(
                  labelText: l10n?.referenceNumber ?? 'Reference number',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: txController,
                decoration: InputDecoration(
                  labelText: l10n?.transactionId ?? 'Transaction ID',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bankController,
                decoration: InputDecoration(
                  labelText: l10n?.bankName ?? 'Bank name',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: l10n?.paymentDetailsNotes ?? 'Additional notes (optional)',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: isSubmitting
                ? null
                : () async {
                    setState(() => isSubmitting = true);
                    try {
                      await ref.read(orderRepositoryProvider).reportPayment(
                            orderId,
                            referenceNumber: refController.text.trim().isEmpty
                                ? null
                                : refController.text.trim(),
                            transactionId: txController.text.trim().isEmpty
                                ? null
                                : txController.text.trim(),
                            bankName: bankController.text.trim().isEmpty
                                ? null
                                : bankController.text.trim(),
                            notes: notesController.text.trim().isEmpty
                                ? null
                                : notesController.text.trim(),
                          );
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ref.invalidate(myOrderDetailProvider(orderId));
                        SnackbarUtils.showSuccess(
                          ctx,
                          l10n?.reportPaymentSuccess ??
                              'Payment details submitted. The seller will verify and update the order.',
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        setState(() => isSubmitting = false);
                        SnackbarUtils.showError(
                          ctx,
                          '${l10n?.failedToPlaceOrder ?? 'Failed'}: $e',
                        );
                      }
                    }
                  },
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n?.reportPayment ?? "I've made the payment"),
          ),
        ],
      ),
    ),
  );
}

// Order Header Card
class _OrderHeaderCard extends StatelessWidget {
  const _OrderHeaderCard({
    required this.order,
    required this.created,
    required this.canManageOrder,
    required this.onStatusUpdate,
    this.currentUser,
    this.onSendPaymentInstructions,
    this.onMarkAsPaid,
    this.onReportPayment,
  });

  final OrderSummary order;
  final String created;
  final bool canManageOrder;
  final VoidCallback onStatusUpdate;
  final UserModel? currentUser;
  final Future<void> Function()? onSendPaymentInstructions;
  final Future<void> Function()? onMarkAsPaid;
  final VoidCallback? onReportPayment;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return Text(
                            l10n?.orderId ?? 'Order ID',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: Colors.grey[600]),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.id,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (canManageOrder)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onSendPaymentInstructions != null)
                        Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            return IconButton(
                              icon: const Icon(Icons.email_outlined),
                              onPressed: () => onSendPaymentInstructions!(),
                              tooltip: l10n?.sendPaymentInstructions ?? 'Send Payment Instructions',
                            );
                          },
                        ),
                        (onMarkAsPaid != null) ? Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            return IconButton(
                              icon: const Icon(Icons.payment, color: Colors.teal),
                              onPressed: () => onMarkAsPaid!(),
                              tooltip: l10n?.markAsPaid ?? 'Mark as paid',
                            );
                          },
                        ): SizedBox.shrink(),
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showOrderStatusDialog(context),
                            tooltip:
                                l10n?.updateOrderStatus ?? 'Update Order Status',
                          );
                        },
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return _InfoItem(
                        label: l10n?.status ?? 'Status',
                        value: order.status.localizedLabel(l10n!),
                        valueColor: _getStatusColor(order.status),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return _InfoItem(
                        label: l10n?.payment ?? 'Payment',
                        value: _paymentMethodLabel(order.paymentMethod, l10n),
                      );
                    },
                  ),
                ),
              ],
            ),
            if (order.paymentStatus != null) ...[
              const SizedBox(height: 10),
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return _InfoItem(
                    label: l10n?.paymentStatus ?? 'Payment Status',
                    value: order.paymentStatus!
                        .replaceAll('_', ' ')
                        .split(' ')
                        .map((w) => w[0].toUpperCase() + w.substring(1))
                        .join(' '),
                    valueColor: _getPaymentStatusColor(order.paymentStatus!),
                  );
                },
              ),
            ],
            // Buyer payment info: show when customer has reported payment (for both buyer and owner)
            if (order.paymentReportedByBuyerAt != null ||
                (order.paymentReportedNotes != null &&
                    order.paymentReportedNotes!.isNotEmpty)) ...[
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.buyerReportedPayment ?? "Buyer's payment info",
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.w600),
                        ),
                        if (order.paymentReportedByBuyerAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${l10n?.reportedAt ?? 'Reported at'}: ${DateFormat('d MMM yyyy, HH:mm').format(order.paymentReportedByBuyerAt!)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        if (order.paymentReportedNotes != null &&
                            order.paymentReportedNotes!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            order.paymentReportedNotes!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
            // Report Payment button: only for buyer (not owner/admin)
            if (onReportPayment != null) ...[
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: order.paymentReportedByBuyerAt == null
                          ? onReportPayment
                          : null,
                      icon: const Icon(Icons.payment),
                      label: Text(
                        order.paymentReportedByBuyerAt != null
                            ? '${l10n?.reportPayment ?? "I\\'ve made the payment"} ✓'
                            : (l10n?.reportPayment ?? "I've made the payment"),
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 10),
            Divider(color: Colors.grey[300], height: 1),
            const SizedBox(height: 10),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return _InfoItem(
                    label: l10n?.placedOn ?? 'Placed on', value: created);
              },
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (order.shippingCost != null && order.shippingCost! > 0) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return Text(
                            l10n?.subtotal ?? 'Subtotal',
                            style: Theme.of(context).textTheme.bodyMedium,
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.formatPriceEurOnly(order.totalAmount),
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '(${context.formatPriceUsdFromEur(order.totalAmount)})',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return Text(
                            l10n?.shipping ?? 'Shipping',
                            style: Theme.of(context).textTheme.bodyMedium,
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            context.formatPriceEurOnly(order.shippingCost!),
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '(${context.formatPriceUsdFromEur(order.shippingCost!)})',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ] else
                  const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return Text(
                          l10n?.total ?? 'Total',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(color: Colors.grey[600]),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          context.formatPriceEurOnly(
                              order.totalAmountWithShipping ??
                                  order.totalAmount),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '(${context.formatPriceUsdFromEur(order.totalAmountWithShipping ?? order.totalAmount)})',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.note_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(
                            builder: (context) {
                              final l10n = AppLocalizations.of(context);
                              return Text(
                                l10n?.orderNotes ?? 'Order Notes',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          Text(
                            order.notes!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  height: 1.4,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showOrderStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _OrderStatusUpdateDialog(
        order: order,
        onUpdate: onStatusUpdate,
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pendingConfirmation:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.packing:
        return Colors.purple;
      case OrderStatus.dispatched:
        return Colors.indigo;
      case OrderStatus.outForDelivery:
        return Colors.cyan;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
      case 'refunded':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// Info Item Widget
class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
        ),
      ],
    );
  }
}

// Order Items Card
class _OrderItemsCard extends ConsumerWidget {
  const _OrderItemsCard({
    required this.items,
    required this.orderId,
    required this.canManageOrder,
    this.currentUserId,
    required this.onItemStatusUpdate,
  });

  final List<OrderItemSummary> items;
  final String orderId;
  final bool canManageOrder;
  final String? currentUserId;
  final VoidCallback onItemStatusUpdate;

  bool _hasShippableItems(List<OrderItemSummary> items) {
    return items.any((item) {
      if (item.itemId == null || item.shipmentId != null) return false;
      final status = item.status?.toLowerCase() ?? 'pending';
      final nonShippableStatuses = [
        'shipped',
        'out_for_delivery',
        'delivered',
        'cancelled',
        'returned',
        'refunded'
      ];
      return !nonShippableStatuses.contains(status);
    });
  }

  void _showCreateShipmentDialog(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.read(myOrderDetailProvider(orderId));

    orderAsync.whenData((order) {
      showDialog(
        context: context,
        builder: (context) => CreateShipmentModal(
          order: order,
          onSuccess: onItemStatusUpdate,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return Text(
                      l10n?.orderItems ?? 'Order Items',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    );
                  },
                ),
                if (canManageOrder && _hasShippableItems(items))
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return FilledButton.icon(
                        onPressed: () =>
                            _showCreateShipmentDialog(context, ref),
                        icon: const Icon(Icons.local_shipping, size: 18),
                        label: Text(l10n?.createShipment ?? 'Create Shipment'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  _OrderItemTile(
                    item: item,
                    orderId: orderId,
                    canManageOrder: canManageOrder,
                    currentUserId: currentUserId,
                    onStatusUpdate: onItemStatusUpdate,
                  ),
                  if (!isLast) ...[
                    const SizedBox(height: 10),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey[200],
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

// Order Item Tile (UPDATED: responsive price placement)
class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({
    required this.item,
    required this.orderId,
    required this.canManageOrder,
    this.currentUserId,
    required this.onStatusUpdate,
  });

  final OrderItemSummary item;
  final String orderId;
  final bool canManageOrder;
  final String? currentUserId;
  final VoidCallback onStatusUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => context.push('/products/${item.productId}'),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
          ),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- IMAGE SECTION ---
                _buildProductImage(context),
                const SizedBox(width: 16),

                // --- INFO SECTION ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (canManageOrder && item.itemId != null)
                            IconButton(
                              icon: const Icon(Icons.edit_note, size: 22),
                              onPressed: () => _showItemStatusDialog(context),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              color: theme.colorScheme.primary,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${item.quantity} x ${item.unit}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          if (item.status != null) _buildStatusBadge(context),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildPriceRow(context, theme),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // --- BADGES SECTION ---
            Row(
              children: [
                if (item.shipmentId != null) ...[
                  _buildShipmentBadge(theme),
                ],
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Text(
                        '${l10n?.sku ?? 'SKU'}: ${item.variantSku ?? (l10n?.skuNA ?? 'N/A')}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: CachedNetworkImage(
              imageUrl: item.imageUrl ?? '',
              fit: BoxFit.cover, // E-commerce style usually shows full product
              errorWidget: (context, url, error) => Icon(
                Icons.inventory_2_outlined,
                color: Colors.grey[400],
              ),
            ),
          ),
        ),
        // Simple quantity indicator on image
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'x${item.quantity}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              context.formatPriceEurOnly(item.totalAmount),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '(${item.unitPrice.toStringAsFixed(2)}/unit)',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: Colors.grey[500]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '(${context.formatPriceUsdFromEur(item.totalAmount)})',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _getItemStatusColor(item.status!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        localizedOrderStatus(item.status, l10n),
        style: TextStyle(
          color: statusColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildShipmentBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_shipping_outlined,
              size: 12, color: Colors.blue[800]),
          const SizedBox(width: 4),
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Text(
                l10n?.trackingAvailable ?? 'TRACKING AVAILABLE',
                style: TextStyle(
                  color: Colors.blue[800],
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showItemStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _OrderItemStatusUpdateDialog(
        orderId: orderId,
        item: item,
        onUpdate: onStatusUpdate,
      ),
    );
  }

  Color _getItemStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'packed':
        return Colors.purple;
      case 'shipped':
        return Colors.indigo;
      case 'out_for_delivery':
        return Colors.cyan;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'returned':
        return Colors.orange;
      case 'refunded':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

// Shipping Address Card
class _ShippingAddressCard extends StatelessWidget {
  const _ShippingAddressCard({required this.address});

  final ShippingAddress address;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return Text(
                      l10n?.shippingAddress ?? 'Shipping Address',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              address.name,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  address.phone.isNotEmpty ? address.phone : 'N/A',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address.fullAddress,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Order Status Update Dialog
class _OrderStatusUpdateDialog extends ConsumerStatefulWidget {
  const _OrderStatusUpdateDialog({
    required this.order,
    required this.onUpdate,
  });

  final OrderSummary order;
  final VoidCallback onUpdate;

  @override
  ConsumerState<_OrderStatusUpdateDialog> createState() =>
      _OrderStatusUpdateDialogState();
}

class _OrderStatusUpdateDialogState
    extends ConsumerState<_OrderStatusUpdateDialog> {
  late String _selectedStatus;
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.order.status.apiName;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return Text(l10n?.updateOrderStatus ?? 'Update Order Status');
        },
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: l10n?.status ?? 'Status',
                    border: const OutlineInputBorder(),
                  ),
                  items: OrderStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status.apiName,
                      child: Text(status.localizedLabel(l10n!)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedStatus = value);
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return TextField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: l10n?.reasonOptional ?? 'Reason (Optional)',
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                );
              },
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: l10n?.notesOptional ?? 'Notes (Optional)',
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return TextButton(
              onPressed: _isUpdating ? null : () => Navigator.pop(context),
              child: Text(l10n?.cancel ?? 'Cancel'),
            );
          },
        ),
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return ElevatedButton(
              onPressed: _isUpdating ? null : _updateStatus,
              child: _isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n?.update ?? 'Update'),
            );
          },
        ),
      ],
    );
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == widget.order.status.apiName &&
        _reasonController.text.isEmpty &&
        _notesController.text.isEmpty) {
      Navigator.pop(context);
      return;
    }

    // If status is being changed to "dispatched" (shipped), show shipment modal
    if (_selectedStatus == 'dispatched' &&
        widget.order.status.apiName != 'dispatched') {
      Navigator.pop(context); // Close status dialog
      // Show shipment modal
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => CreateShipmentModal(
            order: widget.order,
            onSuccess: () {
              widget.onUpdate();
            },
          ),
        );
      });
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final repo = ref.read(orderRepositoryProvider);
      await repo.updateOrderStatus(
        widget.order.id,
        status: _selectedStatus,
        reason: _reasonController.text.isEmpty ? null : _reasonController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onUpdate();
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n?.orderStatusUpdated ??
                  'Order status updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${l10n?.failedToUpdateStatus ?? 'Failed to update status'}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }
}

// Order Item Status Update Dialog
class _OrderItemStatusUpdateDialog extends ConsumerStatefulWidget {
  const _OrderItemStatusUpdateDialog({
    required this.orderId,
    required this.item,
    required this.onUpdate,
  });

  final String orderId;
  final OrderItemSummary item;
  final VoidCallback onUpdate;

  @override
  ConsumerState<_OrderItemStatusUpdateDialog> createState() =>
      _OrderItemStatusUpdateDialogState();
}

class _OrderItemStatusUpdateDialogState
    extends ConsumerState<_OrderItemStatusUpdateDialog> {
  late String _selectedStatus;
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isUpdating = false;

  final List<String> _itemStatuses = [
    'pending',
    'confirmed',
    'packed',
    'shipped',
    'out_for_delivery',
    'delivered',
    'cancelled',
    'returned',
    'refunded',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.item.status ?? 'pending';
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return Text(l10n?.updateItemStatus ?? 'Update Item Status');
        },
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item.title,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: l10n?.status ?? 'Status',
                    border: const OutlineInputBorder(),
                  ),
                  items: _itemStatuses.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(
                        status
                            .replaceAll('_', ' ')
                            .split(' ')
                            .map((w) => w[0].toUpperCase() + w.substring(1))
                            .join(' '),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedStatus = value);
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return TextField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: l10n?.reasonOptional ?? 'Reason (Optional)',
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                );
              },
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: l10n?.notesOptional ?? 'Notes (Optional)',
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return TextButton(
              onPressed: _isUpdating ? null : () => Navigator.pop(context),
              child: Text(l10n?.cancel ?? 'Cancel'),
            );
          },
        ),
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return ElevatedButton(
              onPressed: _isUpdating ? null : _updateStatus,
              child: _isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n?.update ?? 'Update'),
            );
          },
        ),
      ],
    );
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == widget.item.status &&
        _reasonController.text.isEmpty &&
        _notesController.text.isEmpty) {
      Navigator.pop(context);
      return;
    }

    // If status is being changed to "shipped", show shipment modal instead
    if (_selectedStatus == 'shipped' &&
        widget.item.status != 'shipped' &&
        widget.item.shipmentId == null) {
      Navigator.pop(context); // Close status dialog
      // Get the full order to show shipment modal with pre-selected item
      final orderAsync = ref.read(myOrderDetailProvider(widget.orderId));
      orderAsync.whenData((order) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (context) => CreateShipmentModal(
              order: order,
              preSelectedItemId: widget.item.itemId,
              onSuccess: () {
                widget.onUpdate();
              },
            ),
          );
        });
      });
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final repo = ref.read(orderRepositoryProvider);
      await repo.updateOrderItemStatus(
        widget.orderId,
        widget.item.itemId!,
        status: _selectedStatus,
        reason: _reasonController.text.isEmpty ? null : _reasonController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onUpdate();
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n?.itemStatusUpdated ??
                  'Item status updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${l10n?.failedToUpdateStatus ?? 'Failed to update status'}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }
}
