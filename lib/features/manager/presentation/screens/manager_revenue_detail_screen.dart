import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/currency_controller.dart';
import '../../../../core/services/currency_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/permissions/permissions.dart';
import '../../data/models/manager_models.dart';
import '../../data/repositories/manager_repository.dart';
import 'manager_dashboard_screen.dart';
import 'manager_orders_screen.dart';

final revenueOrdersProvider =
    FutureProvider.autoDispose<RevenueOrdersPage>((ref) async {
  final repo = ref.watch(managerRepositoryProvider);
  return repo.fetchRevenueOrders(page: 1, limit: 200);
});

/// Revenue Detail screen: shows how revenue is calculated.
/// Admin: platform cut (1%). Wholesaler: full amount from product + deal orders.
class ManagerRevenueDetailScreen extends ConsumerWidget {
  const ManagerRevenueDetailScreen({super.key});

  static const routePath = '/manager/revenue-detail';
  static const routeName = 'managerRevenueDetail';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(currencyControllerProvider);
    final statsAsync = ref.watch(managerStatsProvider);
    final authState = ref.watch(authControllerProvider);

    return authState.when(
      data: (session) {
        final user = session?.user;
        if (user == null ||
            (!Permissions.isAdminOrSubAdmin(user.role) &&
                !Permissions.isWholesaler(user.role))) {
          final l10n = AppLocalizations.of(context)!;
          return Scaffold(
            appBar: AppBar(title: Text(l10n.accessDenied)),
            body: Center(child: Text(l10n.managersSectionOnly)),
          );
        }

        final l10n = AppLocalizations.of(context)!;
        final isAdmin = Permissions.isAdminOrSubAdmin(user.role);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              isAdmin ? l10n.revenueDetail : l10n.myRevenueDetail,
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: statsAsync.when(
            data: (stats) {
              final detail = stats.revenueDetail;
              if (detail == null) {
                return _buildSimpleRevenue(
                    context, ref, stats, isAdmin, l10n);
              }
              return _buildRevenueDetail(
                  context, ref, detail, isAdmin, l10n);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    '${l10n.errorLoading}: $error',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(managerStatsProvider),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(child: Text('${AppLocalizations.of(context)?.error ?? 'Error'}: $e')),
      ),
    );
  }

  Widget _buildSimpleRevenue(
    BuildContext context,
    WidgetRef ref,
    ManagerStats stats,
    bool isAdmin,
    AppLocalizations l10n,
  ) {
    final ordersAsync = ref.watch(revenueOrdersProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(managerStatsProvider);
        ref.invalidate(revenueOrdersProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAdmin ? l10n.totalRevenue : l10n.myRevenue,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${context.formatPriceEurOnly(stats.totalRevenue, decimalDigits: 2)} '
                      '(${context.formatPriceUsdFromEur(stats.totalRevenue, decimalDigits: 2)})',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.revenueFromDeliveredOrders,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.revenueOrdersList,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ordersAsync.when(
              data: (page) {
                if (page.items.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          l10n.noRevenueOrdersYet,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: page.items.map((order) {
                    return _buildRevenueOrderCard(
                      order: order,
                      isAdmin: isAdmin,
                      onTap: () {
                        if (order.type == 'deal' &&
                            order.dealId != null &&
                            order.dealId!.isNotEmpty) {
                          context.push('/deals/${order.dealId}');
                        } else {
                          context.push('/orders/my/${order.orderId}');
                        }
                      },
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                  child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator())),
              error: (e, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(height: 8),
                      Text('${l10n.errorLoading}: $e'),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(revenueOrdersProvider),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.push(ManagerOrdersScreen.routePath),
              icon: const Icon(Icons.receipt_long),
              label: Text(l10n.viewOrders),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueDetail(
    BuildContext context,
    WidgetRef ref,
    RevenueDetail detail,
    bool isAdmin,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final ordersAsync = ref.watch(revenueOrdersProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(managerStatsProvider);
        ref.invalidate(revenueOrdersProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary card
            Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAdmin ? l10n.totalRevenue : l10n.myRevenue,
                    style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${context.formatPriceEurOnly(detail.displayAmount, decimalDigits: 2)} '
                    '(${context.formatPriceUsdFromEur(detail.displayAmount, decimalDigits: 2)})',
                    style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.platformCutDescription,
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Calculation breakdown
          Text(
            l10n.howCalculated,
            style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildBreakdownRow(
                    context,
                    l10n.productOrdersRevenue,
                    detail.productOrdersRevenue,
                  ),
                  const Divider(height: 24),
                  _buildBreakdownRow(
                    context,
                    l10n.dealOrdersRevenue,
                    detail.dealOrdersRevenue,
                  ),
                  const Divider(height: 24),
                  _buildBreakdownRow(
                    context,
                    l10n.totalGrossRevenue,
                    detail.totalGross,
                    isTotal: true,
                  ),
                  if (isAdmin) ...[
                    const Divider(height: 24),
                    _buildBreakdownRow(
                      context,
                      l10n.platformCut(
                          (detail.commissionRate * 100).toStringAsFixed(0)),
                      detail.platformCut,
                      valueColor: Colors.teal,
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Info text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isAdmin
                        ? l10n.revenueDetailAdminInfo
                        : l10n.revenueDetailOwnerInfo,
                    style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.blue.shade900,
                        ),
                  ),
                ),
              ],
            ),
          ),

            const SizedBox(height: 24),

            // Orders list
            Text(
              l10n.revenueOrdersList,
              style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ordersAsync.when(
              data: (page) {
                if (page.items.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.noRevenueOrdersYet,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: page.items.map((order) {
                    return _buildRevenueOrderCard(
                      order: order,
                      isAdmin: isAdmin,
                      onTap: () {
                        if (order.type == 'deal' &&
                            order.dealId != null &&
                            order.dealId!.isNotEmpty) {
                          context.push('/deals/${order.dealId}');
                        } else {
                          context.push('/orders/my/${order.orderId}');
                        }
                      },
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                  child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator())),
              error: (e, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(height: 8),
                      Text('${l10n.errorLoading}: $e'),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(revenueOrdersProvider),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: () => context.push(ManagerOrdersScreen.routePath),
              icon: const Icon(Icons.receipt_long),
              label: Text(l10n.viewOrders),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueOrderCard({
    required RevenueOrderItem order,
    required bool isAdmin,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: order.type == 'deal'
              ? Colors.orange.shade100
              : Colors.blue.shade100,
          child: Icon(
            order.type == 'deal'
                ? Icons.local_offer_outlined
                : Icons.shopping_cart_outlined,
            color: order.type == 'deal'
                ? Colors.orange.shade700
                : Colors.blue.shade700,
          ),
        ),
        title: Text(
          order.type == 'deal'
              ? (order.dealTitle ?? 'Deal order')
              : 'Order #${order.orderId.length > 8 ? order.orderId.substring(order.orderId.length - 8) : order.orderId}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(order.buyerName),
            Text(
              DateFormat('d MMM yyyy').format(order.deliveredAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Builder(
              builder: (context) => Text(
                context.formatPriceEurOnly(order.yourAmount, decimalDigits: 2),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ),
            if (isAdmin && order.totalAmount != order.yourAmount)
              Builder(
                builder: (context) => Text(
                  '${context.formatPriceEurOnly(order.totalAmount, decimalDigits: 0)} total',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(
    BuildContext context,
    String label,
    double amount, {
    bool isTotal = false,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
        ),
        Text(
          context.formatPriceEurOnly(amount, decimalDigits: 2),
          style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: valueColor ?? (isTotal ? Colors.green.shade700 : null),
              ),
        ),
      ],
    );
  }
}
