import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/manager_models.dart';
import '../../data/repositories/manager_repository.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/currency_controller.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../shared/utils/snackbar_utils.dart';
import '../../../orders/data/models/order_models.dart';

final managerOrdersProvider = StateNotifierProvider.autoDispose<
    ManagerOrdersController, AsyncValue<ManagerOrdersPage>>(
  (ref) => ManagerOrdersController(ref.watch(managerRepositoryProvider)),
);

class ManagerOrdersController
    extends StateNotifier<AsyncValue<ManagerOrdersPage>> {
  ManagerOrdersController(this._repo) : super(const AsyncValue.loading()) {
    loadOrders();
  }

  final ManagerRepository _repo;
  int _currentPage = 1;
  String? _statusFilter;

  Future<void> loadOrders({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      state = const AsyncValue.loading();
    }

    try {
      final page = await _repo.fetchOrders(
        page: _currentPage,
        status: _statusFilter,
      );

      if (refresh) {
        state = AsyncValue.data(page);
      } else {
        final current = state.value;
        if (current != null) {
          state = AsyncValue.data(
            ManagerOrdersPage(
              items: [...current.items, ...page.items],
              page: page.page,
              limit: page.limit,
              totalRows: page.totalRows,
            ),
          );
        } else {
          state = AsyncValue.data(page);
        }
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    loadOrders(refresh: true);
  }
}

class ManagerOrdersScreen extends ConsumerWidget {
  const ManagerOrdersScreen({super.key});

  static const routePath = '/manager/orders';
  static const routeName = 'managerOrders';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
        currencyControllerProvider); // Rebuild when display currency changes
    final authState = ref.watch(authControllerProvider);
    final ordersAsync = ref.watch(managerOrdersProvider);
    final l10n = AppLocalizations.of(context)!;

    return authState.when(
      data: (session) {
        final user = session?.user;
        final isAdmin =
            Permissions.isAdminOrSubAdmin(user?.role ?? UserRole.kiosk);

        return Scaffold(
          appBar: AppBar(
            title: Text(isAdmin ? l10n.allOrders : l10n.myOrders),
            actions: [
              PopupMenuButton<String>(
                onSelected: (status) {
                  ref.read(managerOrdersProvider.notifier).setStatusFilter(
                        status == 'all' ? null : status,
                      );
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'all', child: Text(l10n.allOrders)),
                  PopupMenuItem(
                    value: 'pending_confirmation',
                    child: Text(l10n.pendingConfirmation),
                  ),
                  PopupMenuItem(
                    value: 'confirmed',
                    child: Text(l10n.confirmed),
                  ),
                  PopupMenuItem(
                    value: 'dispatched',
                    child: Text(l10n.dispatched),
                  ),
                  PopupMenuItem(
                    value: 'delivered',
                    child: Text(l10n.delivered),
                  ),
                ],
              ),
            ],
          ),
          body: ordersAsync.when(
            data: (page) {
              if (page.items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noOrdersYet,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref
                      .read(managerOrdersProvider.notifier)
                      .loadOrders(refresh: true);
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final padding = EdgeInsets.only(
                      left: 16 + MediaQuery.paddingOf(context).left,
                      right: 16 + MediaQuery.paddingOf(context).right,
                      top: 16,
                      bottom: 16,
                    );
                    return ListView.builder(
                      padding: padding,
                      itemCount: page.items.length,
                      itemBuilder: (context, index) {
                        final order = page.items[index];
                        return _ManagerOrderCard(
                          order: order,
                          l10n: l10n,
                          onTap: () => context.push('/orders/my/${order.id}'),
                          onMenuSelected: (value) async {
                            if (value == 'view') {
                              context.push('/orders/my/${order.id}');
                            } else if (value == 'status') {
                              _showStatusDialog(context, ref, order);
                            } else if (value == 'send_payment') {
                              await _sendPaymentInstructions(
                                  context, ref, order);
                            } else if (value == 'mark_paid') {
                              await _markOrderPaid(context, ref, order);
                            }
                          },
                          paymentMethod: order.paymentMethod,
                        );
                      },
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('${l10n.error}: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref
                        .read(managerOrdersProvider.notifier)
                        .loadOrders(refresh: true),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            '${AppLocalizations.of(context)?.error ?? 'Error'}: $error',
          ),
        ),
      ),
    );
  }
}

class _ManagerOrderCard extends StatelessWidget {
  const _ManagerOrderCard({
    required this.order,
    required this.l10n,
    required this.onTap,
    required this.onMenuSelected,
    this.paymentMethod,
  });

  final ManagerOrder order;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final void Function(String?) onMenuSelected;
  final String? paymentMethod;

  @override
  Widget build(BuildContext context) {
    final created =
        DateFormat('d MMM, HH:mm').format(order.createdAt.toLocal());
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    radius: 24,
                    child: Icon(
                      Icons.shopping_cart_outlined,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.order} #${order.id.substring(order.id.length - 8)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          created,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    padding: EdgeInsets.zero,
                    onSelected: onMenuSelected,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            const Icon(Icons.visibility),
                            const SizedBox(width: 8),
                            Text(l10n.viewDetails),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'status',
                        child: Row(
                          children: [
                            const Icon(Icons.swap_vert),
                            const SizedBox(width: 8),
                            Text(l10n.changeOrderStatus),
                          ],
                        ),
                      ),
                      if (paymentMethod == 'invoice' ||
                          paymentMethod == 'bank_transfer')
                        PopupMenuItem(
                          value: 'send_payment',
                          child: Row(
                            children: [
                              const Icon(Icons.email_outlined),
                              const SizedBox(width: 8),
                              Text(l10n.sendPaymentInstructions),
                            ],
                          ),
                        ),
                      if (paymentMethod == 'invoice' ||
                          paymentMethod == 'bank_transfer')
                        PopupMenuItem(
                          value: 'mark_paid',
                          child: Row(
                            children: [
                              const Icon(Icons.payment),
                              const SizedBox(width: 8),
                              Text(l10n.markAsPaid),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (order.buyerName != null) ...[
                Text('${l10n.buyer}: ${order.buyerName}'),
                const SizedBox(height: 4),
              ],
              Text(
                '${order.itemCount} ${l10n.items} • '
                '${context.formatPriceEurOnly(order.totalAmount, decimalDigits: 0)} '
                '(${context.formatPriceUsdFromEur(order.totalAmount, decimalDigits: 0)})',
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      '${l10n.order} ${l10n.status}:'.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildOrderStatusBadge(context, order.status),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      '${l10n.paymentStatus}:'.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildPaymentStatusBadge(
                    order.paymentStatus ?? 'pending',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderStatusBadge(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _getOrderStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        localizedOrderStatus(status, l10n),
        style: TextStyle(
          color: statusColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildPaymentStatusBadge(String status) {
    final statusColor = _getPaymentStatusColorSolid(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: statusColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  static Color _getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'pending_confirmation':
        return Colors.amber;
      case 'confirmed':
        return Colors.blue;
      case 'packing':
        return Colors.purple;
      case 'dispatched':
      case 'out_for_delivery':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static Color _getPaymentStatusColorSolid(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
      case 'processing':
        return Colors.amber;
      case 'failed':
      case 'refunded':
      case 'partially_refunded':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

void _showStatusDialog(
    BuildContext context, WidgetRef ref, ManagerOrder order) {
  String? selectedStatus = order.status;
  bool isUpdating = false;
  final l10n = AppLocalizations.of(context)!;

  showDialog(
    context: context,
    barrierDismissible: false, // Prevent dismissing during update
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l10n.changeOrderStatus),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isUpdating)
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text(l10n.updatingStatus),
                  ],
                ),
              ),
            DropdownButtonFormField<String>(
              initialValue: selectedStatus,
              decoration: InputDecoration(
                labelText: l10n.status,
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: 'pending_confirmation',
                  child: Text(l10n.pendingConfirmation),
                ),
                DropdownMenuItem(
                    value: 'confirmed', child: Text(l10n.confirmed)),
                DropdownMenuItem(value: 'packing', child: Text(l10n.packing)),
                DropdownMenuItem(
                    value: 'dispatched', child: Text(l10n.dispatched)),
                DropdownMenuItem(
                  value: 'out_for_delivery',
                  child: Text(l10n.outForDelivery),
                ),
                DropdownMenuItem(
                    value: 'delivered', child: Text(l10n.delivered)),
                DropdownMenuItem(
                    value: 'cancelled', child: Text(l10n.cancelled)),
              ],
              onChanged: isUpdating
                  ? null
                  : (value) {
                      setState(() => selectedStatus = value);
                    },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: isUpdating ? null : () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: isUpdating
                ? null
                : () async {
                    if (selectedStatus != null &&
                        selectedStatus != order.status) {
                      // Show loading immediately
                      setState(() => isUpdating = true);

                      try {
                        await ref
                            .read(managerRepositoryProvider)
                            .updateOrderStatus(order.id, selectedStatus!);

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                          // Refresh orders list asynchronously
                          ref
                              .read(managerOrdersProvider.notifier)
                              .loadOrders(refresh: true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.orderStatusUpdatedSuccessfully,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (dialogContext.mounted) {
                          setState(() => isUpdating = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${l10n.error}: $e',
                              ),
                            ),
                          );
                        }
                      }
                    } else {
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    }
                  },
            child: isUpdating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.update),
          ),
        ],
      ),
    ),
  );
}

Future<void> _sendPaymentInstructions(
    BuildContext context, WidgetRef ref, ManagerOrder order) async {
  final l10n = AppLocalizations.of(context)!;
  try {
    await ref
        .read(managerRepositoryProvider)
        .sendProductOrderPaymentInstructions(order.id);
    if (context.mounted) {
      SnackbarUtils.showSuccess(
        context,
        l10n.invoiceInstructionsSent,
      );
      ref.read(managerOrdersProvider.notifier).loadOrders(refresh: true);
    }
  } catch (e) {
    if (context.mounted) {
      SnackbarUtils.showError(context, '${l10n.error}: $e');
    }
  }
}

Future<void> _markOrderPaid(
    BuildContext context, WidgetRef ref, ManagerOrder order) async {
  final l10n = AppLocalizations.of(context)!;
  try {
    await ref
        .read(managerRepositoryProvider)
        .updateOrderPaymentStatus(order.id, 'completed');
    if (context.mounted) {
      SnackbarUtils.showSuccess(
        context,
        l10n.orderStatusUpdatedSuccessfully,
      );
      ref.read(managerOrdersProvider.notifier).loadOrders(refresh: true);
    }
  } catch (e) {
    if (context.mounted) {
      SnackbarUtils.showError(context, '${l10n.error}: $e');
    }
  }
}
