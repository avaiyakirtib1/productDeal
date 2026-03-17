import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../../core/widgets/banner_carousel.dart';
import '../../data/models/manager_models.dart';
import '../../data/repositories/manager_repository.dart';
import '../../../wholesaler/presentation/widgets/stats_card.dart';
import '../../../notifications/presentation/controllers/notification_controller.dart';
import 'manager_products_screen.dart';
import 'manager_deals_screen.dart';
import 'manager_orders_screen.dart';
import 'manager_revenue_detail_screen.dart';
import 'manager_categories_screen.dart';
import 'manager_banners_screen.dart';
import 'inactive_members_screen.dart';
import '../../../admin/presentation/screens/admin_banner_manage_screen.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/currency_controller.dart';
import '../../../../core/services/currency_service.dart';
import '../../../orders/data/models/order_models.dart';

/// Provider for manager dashboard stats
final managerStatsProvider =
    FutureProvider.autoDispose<ManagerStats>((ref) async {
  final repo = ref.watch(managerRepositoryProvider);
  return repo.fetchStats();
});

class ManagerDashboardScreen extends ConsumerWidget {
  const ManagerDashboardScreen({super.key});

  static const routePath = '/manager/dashboard';
  static const routeName = 'managerDashboard';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
        currencyControllerProvider); // Rebuild when display currency changes
    final authState = ref.watch(authControllerProvider);
    final statsAsync = ref.watch(managerStatsProvider);

    return authState.when(
      data: (session) {
        final user = session?.user;
        // Allow admin, sub-admin, and wholesaler roles
        if (user == null ||
            (!Permissions.isAdminOrSubAdmin(user.role) &&
                !Permissions.isWholesaler(user.role))) {
          final l10n = AppLocalizations.of(context)!;
          return Scaffold(
            appBar: AppBar(title: Text(l10n.accessDenied)),
            body: Center(
              child: Text(l10n.managersSectionOnly),
            ),
          );
        }

        final l10n = AppLocalizations.of(context)!;
        final isAdmin = Permissions.isAdminOrSubAdmin(user.role);
        final roleTitle = isAdmin
            ? (user.role == UserRole.admin ? l10n.admin : l10n.subAdmin)
            : l10n.wholesaler;

        return Scaffold(
          appBar: AppBar(
            title: Text('$roleTitle ${l10n.dashboard}'),
            actions: [
              Consumer(
                builder: (context, ref, _) {
                  final unreadCount = ref.watch(
                    unreadCountProvider
                        .select((value) => value.valueOrNull ?? 0),
                  );

                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {
                          context.push('/notifications');
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
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
                  );
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(managerStatsProvider);
            },
            child: statsAsync.when(
              data: (stats) => _DashboardContent(
                stats: stats,
                userRole: user.role,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      (l10n.errorWithDetail.replaceAll(
                              '{detail}', error.toString())),
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
            AppLocalizations.of(context)?.errorWithDetail
                    .replaceAll('{detail}', error.toString()) ??
                'Error: $error',
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.stats,
    required this.userRole,
  });

  final ManagerStats stats;
  final UserRole userRole;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAdmin = Permissions.isAdminOrSubAdmin(userRole);
    final l10n = AppLocalizations.of(context)!;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BannerCarousel(),
                const SizedBox(height: 8),
                // Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: StatsCard(
                        title: isAdmin ? l10n.allProducts : l10n.myProducts,
                        value: '${stats.totalProducts}',
                        icon: Icons.inventory_2_outlined,
                        color: Colors.blue,
                        onTap: () =>
                            context.push(ManagerProductsScreen.routePath),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatsCard(
                        title: l10n.activeDeals,
                        value: '${stats.activeDeals}',
                        subtitle: stats.closedDeals > 0
                            ? '${stats.closedDeals} ${l10n.closed}'
                            : null,
                        icon: Icons.local_offer_outlined,
                        color: Colors.orange,
                        onTap: () => context.push(ManagerDealsScreen.routePath),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatsCard(
                        title: l10n.pendingOrders,
                        value: '${stats.pendingOrders}',
                        icon: Icons.pending_actions_outlined,
                        color: Colors.amber,
                        onTap: () =>
                            context.push(ManagerOrdersScreen.routePath),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatsCard(
                        title: isAdmin ? l10n.totalRevenue : l10n.myRevenue,
                        value:
                            '${context.formatPriceEurOnly(stats.totalRevenue, decimalDigits: 0)} (${context.formatPriceUsdFromEur(stats.totalRevenue, decimalDigits: 0)})',
                        icon: Icons.attach_money_outlined,
                        color: Colors.green,
                        onTap: () =>
                            context.push(ManagerRevenueDetailScreen.routePath),
                      ),
                    ),
                  ],
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StatsCard(
                          title: l10n.activeShops,
                          value: '${stats.activeShops}',
                          icon: Icons.store_outlined,
                          color: Colors.teal,
                          onTap: null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatsCard(
                          title: l10n.activeMembers,
                          value: '${stats.activeMembers}',
                          icon: Icons.people_outline,
                          color: Colors.indigo,
                          onTap: null,
                        ),
                      ),
                    ],
                  ),
                  if (stats.inactiveMembersCount > 0) ...[
                    const SizedBox(height: 12),
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Material(
                        color: Colors.orange.shade50,
                        child: InkWell(
                          onTap: () =>
                              context.push(InactiveMembersScreen.routePath),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange.shade700,
                                  size: 28,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${stats.inactiveMembersCount} ${l10n.inactiveMembers}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange.shade900,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        l10n.inactiveMembersSubtitle,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  l10n.viewAll,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade800,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.orange.shade700,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 24),

                // Quick Actions
                Text(
                  l10n.quickActions,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _QuickActionsGrid(userRole: userRole),
                const SizedBox(height: 12),
                // Recent Activity
                Text(
                  l10n.recentOrders,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (stats.recentOrders.isEmpty)
                  Card(
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
                            const SizedBox(height: 16),
                            Text(
                              l10n.noRecentOrders,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...stats.recentOrders.take(5).map((order) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(
                              Icons.shopping_cart_outlined,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: Text(
                              'Order #${order.id.substring(order.id.length - 8)}'),
                          subtitle: Text(
                            '${order.itemCount} ${l10n.items} • '
                            '${context.formatPriceEurOnly(order.totalAmount, decimalDigits: 0)} '
                            '(${context.formatPriceUsdFromEur(order.totalAmount, decimalDigits: 0)})',
                          ),
                          trailing: Chip(
                            label: Text(
                              localizedOrderStatus(order.status, l10n),
                            ),
                            backgroundColor:
                                _getStatusColor(order.status, theme),
                          ),
                          onTap: () {
                            // Navigate to order detail
                            context.push('/orders/my/${order.id}');
                          },
                        ),
                      )),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'pending_confirmation':
        return Colors.amber.withValues(alpha: 0.2);
      case 'confirmed':
        return Colors.blue.withValues(alpha: 0.2);
      case 'dispatched':
      case 'out_for_delivery':
        return Colors.orange.withValues(alpha: 0.2);
      case 'delivered':
        return Colors.green.withValues(alpha: 0.2);
      case 'cancelled':
        return Colors.red.withValues(alpha: 0.2);
      default:
        return theme.colorScheme.surfaceContainerHighest;
    }
  }
}

class _QuickActionItem {
  const _QuickActionItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _QuickActionsGrid extends ConsumerWidget {
  const _QuickActionsGrid({required this.userRole});

  final UserRole userRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = Permissions.isAdminOrSubAdmin(userRole);
    final canAddProducts = Permissions.canAddProducts(userRole);
    final canAddDeals = Permissions.canAddDeals(userRole);
    final l10n = AppLocalizations.of(context)!;

    final actions = <_QuickActionItem>[
      if (canAddProducts)
        _QuickActionItem(
          title: l10n.addProduct,
          icon: Icons.add_circle_outline,
          color: Colors.blue,
          onTap: () => context.push(ManagerProductsScreen.routePath),
        ),
      if (canAddDeals)
        _QuickActionItem(
          title: l10n.createDeal,
          icon: Icons.local_offer_outlined,
          color: Colors.orange,
          onTap: () => context.push(ManagerDealsScreen.routePath),
        ),
      _QuickActionItem(
        title: l10n.viewOrders,
        icon: Icons.receipt_long_outlined,
        color: Colors.green,
        onTap: () => context.push(ManagerOrdersScreen.routePath),
      ),
      if (isAdmin) ...[
        _QuickActionItem(
          title: l10n.manageCategories,
          icon: Icons.category_outlined,
          color: Colors.teal,
          onTap: () => context.push(ManagerCategoriesScreen.routePath),
        ),
        _QuickActionItem(
          title: l10n.manageUsers,
          icon: Icons.people_outlined,
          color: Colors.purple,
          onTap: () => context.push('/admin/users'),
        ),
        _QuickActionItem(
          title: l10n.manageBanners,
          icon: Icons.view_carousel_outlined,
          color: Colors.pink,
          onTap: () => context.push(AdminBannerManageScreen.routePath),
        ),
      ] else ...[
        _QuickActionItem(
          title: l10n.analytics,
          icon: Icons.analytics_outlined,
          color: Colors.purple,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.analyticsComingSoon)),
            );
          },
        ),
        _QuickActionItem(
          title: l10n.myBanners,
          icon: Icons.view_carousel_outlined,
          color: Colors.pink,
          onTap: () => context.push(ManagerBannersScreen.routePath),
        ),
      ],
    ];

    return Column(
      children: [
        for (int i = 0; i < actions.length; i += 2) ...[
          Row(
            children: [
              Expanded(child: _QuickActionStatsCard(item: actions[i])),
              const SizedBox(width: 12),
              Expanded(
                child: (i + 1 < actions.length)
                    ? _QuickActionStatsCard(item: actions[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          if (i + 2 < actions.length) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _QuickActionStatsCard extends StatelessWidget {
  const _QuickActionStatsCard({required this.item});

  final _QuickActionItem item;

  @override
  Widget build(BuildContext context) {
    return StatsCard(
      title: item.title,
      value: '', // show empty if StatsCard requires a value
      icon: item.icon,
      color: item.color,
      onTap: item.onTap,
    );
  }
}
