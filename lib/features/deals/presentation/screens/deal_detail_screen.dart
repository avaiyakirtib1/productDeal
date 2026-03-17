import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/currency_controller.dart';
import '../../../../core/services/currency_service.dart';
import '../../data/deal_live_data_service.dart';
import '../../data/deal_providers.dart';
import '../screens/deal_list_screen.dart';
import '../../../manager/presentation/screens/manager_deals_screen.dart';
import '../../data/models/deal_models.dart';
import '../../data/repositories/deal_repository.dart';
import '../widgets/deal_timer.dart';
import '../widgets/deal_order_form.dart';
import '../widgets/deal_progress_and_orders.dart';
import '../widgets/deal_order_management.dart';
import '../widgets/deal_final_payment_card.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../../shared/utils/snackbar_utils.dart';
import '../../../wholesaler/presentation/widgets/edit_deal_modal.dart';
import '../../../manager/data/repositories/manager_repository.dart';
import '../../../payments/data/repositories/payment_repository.dart';
import '../../../orders/presentation/widgets/cart_icon_button.dart';

/// Final payment summary for a succeeded deal (invoice vs card at close)
final dealFinalPaymentSummaryProvider = FutureProvider.autoDispose
    .family<DealFinalPaymentSummary?, String>((ref, dealId) async {
  try {
    final repo = ref.watch(paymentRepositoryProvider);
    return repo.getDealFinalPaymentSummary(dealId);
  } catch (_) {
    return null;
  }
});

/// Orders for a specific deal (used for order history section)
final dealOrdersForDealProvider =
    FutureProvider.autoDispose.family<List<DealOrder>, String>((ref, id) async {
  final repo = ref.watch(dealRepositoryProvider);
  return repo.fetchOrdersForDeal(id);
});

class DealDetailScreen extends ConsumerStatefulWidget {
  const DealDetailScreen({super.key, required this.dealId});

  static const routePath = '/deals/:id';
  static const routeName = 'dealDetail';

  final String dealId;

  @override
  ConsumerState<DealDetailScreen> createState() => _DealDetailScreenState();
}

class _DealDetailScreenState extends ConsumerState<DealDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dealLiveDataProvider).registerDetail(widget.dealId);
    });
  }

  @override
  void dispose() {
    ref.read(dealLiveDataProvider).unregisterDetail(widget.dealId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(
        currencyControllerProvider); // Rebuild when display currency changes
    final dealId = widget.dealId;
    final detailAsync = ref.watch(dealDetailProvider(dealId));
    final authState = ref.watch(authControllerProvider);

    return detailAsync.when(
      data: (detail) {
        final session = authState.valueOrNull;
        final user = session?.user;
        final userRole = user?.role ?? UserRole.kiosk;

        // Check if user can manage this deal (admin or deal owner)
        final canManageDeal = Permissions.isAdminOrSubAdmin(userRole) ||
            (userRole == UserRole.wholesaler &&
                user?.id == detail.wholesaler?.id);

        // Check if user can place orders (add bid). Config via Permissions.canPlaceOrderOnDeal
        final canPlaceOrder = Permissions.canPlaceOrderOnDeal(userRole);

        return _DealDetailView(
          deal: detail,
          canManageDeal: canManageDeal,
          canPlaceOrder: canPlaceOrder,
          currentUserId: user?.id,
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(
          actions: const [CartIconButton()],
        ),
        body: Center(
          child: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('${l10n?.unableToLoadDeal ?? 'Unable to load deal'}: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(dealDetailProvider(dealId)),
                    child: Text(l10n?.retry ?? 'Retry'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DealFinalPaymentSection extends ConsumerWidget {
  const _DealFinalPaymentSection({
    required this.dealId,
    required this.onPaymentComplete,
  });

  final String dealId;
  final VoidCallback onPaymentComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dealFinalPaymentSummaryProvider(dealId));
    return summaryAsync.when(
      data: (summary) {
        if (summary == null || !summary.hasUnpaidOrders) {
          return const SizedBox.shrink();
        }
        return DealFinalPaymentCard(
          dealId: dealId,
          orderIds: summary.orderIds,
          totalAmountEur: summary.totalAmountEur,
          onPaymentComplete: onPaymentComplete,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _DealDetailView extends StatelessWidget {
  const _DealDetailView({
    required this.deal,
    required this.canManageDeal,
    required this.canPlaceOrder,
    this.currentUserId,
  });

  final DealDetail deal;
  final bool canManageDeal;
  final bool canPlaceOrder;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    return _DealDetailContent(
      deal: deal,
      canManageDeal: canManageDeal,
      canPlaceOrder: canPlaceOrder,
      currentUserId: currentUserId,
    );
  }
}

class _DealDetailContent extends ConsumerWidget {
  _DealDetailContent({
    required this.deal,
    required this.canManageDeal,
    required this.canPlaceOrder,
    this.currentUserId,
  });

  final DealDetail deal;
  final bool canManageDeal;
  final bool canPlaceOrder;
  final String? currentUserId;
  final ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
        appBar: AppBar(
          title: Text(deal.title),
          actions: [
            const CartIconButton(),
            if (deal.wholesaler != null)
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return IconButton(
                    icon: const Icon(Icons.person_outline),
                    tooltip: l10n?.viewWholesaler ?? 'View wholesaler',
                    onPressed: () =>
                        context.push('/wholesalers/${deal.wholesaler!.id}'),
                  );
                },
              ),
            if (canManageDeal)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) => _handleMenuAction(context, ref, value),
                itemBuilder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n?.editDeal ?? 'Edit Deal'),
                        ],
                      ),
                    ),
                    if (deal.isActive && !deal.isEnded)
                      PopupMenuItem(
                        value: 'close',
                        child: Row(
                          children: [
                            const Icon(Icons.close, size: 20),
                            const SizedBox(width: 8),
                            Text(l10n?.closeDeal ?? 'Close Deal'),
                          ],
                        ),
                      ),
                  ];
                },
              ),
          ],
        ),
        body: SingleChildScrollView(
          controller: _controller,
          child: Column(
            children: [
              // Hero Image
              // SliverToBoxAdapter(
              //   child: _buildHeroImage(context, deal, theme),
              // ),
              _buildHeroImage(context, deal, theme),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildHeader(context, deal, theme),
                    const SizedBox(height: 24),

                    // Timer
                    DealTimer(deal: deal),
                    const SizedBox(height: 24),

                    // Price & Quantity Info
                    _buildPriceCard(context, deal, theme),
                    const SizedBox(height: 24),

                    // Combined Progress + Orders (auto-refreshes every 5 seconds)
                    DealProgressAndOrdersCard(
                      dealId: deal.id,
                      autoRefresh: deal.isActive && !deal.isEnded,
                    ),
                    const SizedBox(height: 24),

                    // Final payment (invoice vs card) when deal succeeded and user has unpaid orders
                    if (deal.hasSucceeded && canPlaceOrder)
                      _DealFinalPaymentSection(
                        dealId: deal.id,
                        onPaymentComplete: () {
                          ref.invalidate(dealFinalPaymentSummaryProvider(deal.id));
                          ref.invalidate(dealOrdersForDealProvider(deal.id));
                          ref.invalidate(dealDetailProvider(deal.id));
                        },
                      ),
                    if (deal.hasSucceeded && canPlaceOrder)
                      const SizedBox(height: 24),

                    // Order Management (for Admin/Wholesaler)
                    if (canManageDeal) ...[
                      DealOrderManagementWidget(
                        dealId: deal.id,
                        canManage: canManageDeal,
                        onPaymentStatusChange: () {
                          ref.invalidate(dealFinalPaymentSummaryProvider(deal.id));
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Product Info
                    if (deal.product != null) ...[
                      _buildProductCard(context, deal, theme),
                      const SizedBox(height: 16),
                    ],

                    // Wholesaler Info
                    if (deal.wholesaler != null) ...[
                      _buildWholesalerCard(context, deal, theme),
                      const SizedBox(height: 24),
                    ],

                    // Order Form (only for kiosk users)
                    if (deal.isActive && !deal.isEnded && canPlaceOrder)
                      DealOrderForm(
                        deal: deal,
                        onOrderPlaced: () {
                          debugPrint('Order placed - form will reset itself');
                        },
                      )
                    else if (deal.isActive && !deal.isEnded && !canPlaceOrder)
                      _buildManagementCard(context, deal, theme, canManageDeal)
                    else
                      _buildInactiveCard(context, deal, theme),
                  ],
                ),
              )
            ],
          ),
        ));
  }

  Widget _buildHeroImage(
      BuildContext context, DealDetail deal, ThemeData theme) {
    // Prioritize deal images over product images
    final String? heroImageUrl = deal.imageUrl ??
        (deal.images?.isNotEmpty == true ? deal.images!.first : null) ??
        (deal.product?.displayImages?.isNotEmpty == true
            ? deal.product!.displayImages!.first
            : null);

    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          child: heroImageUrl != null && heroImageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: heroImageUrl,
                  height: 320,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 320,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 320,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.secondaryContainer,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.local_offer,
                        size: 80,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                )
              : Container(
                  height: 320,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.secondaryContainer,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.local_offer,
                      size: 80,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
        ),
        if (deal.highlighted)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department,
                      size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  const Text(
                    'HOT DEAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, DealDetail deal, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deal.title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (deal.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  deal.description!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Chip(
          label: Text(deal.type.name.toUpperCase()),
          avatar: Icon(_iconForDealType(deal.type), size: 18),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ],
    );
  }

  Widget _buildPriceCard(
      BuildContext context, DealDetail deal, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.dealPrice ?? 'Deal Price',
                      style: theme.textTheme.bodySmall,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${context.formatPriceEurOnly(deal.dealPrice)}/unit',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '(${context.formatPriceUsdFromEur(deal.dealPrice)})',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (deal.product != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.regularPrice ??
                            'Regular Price',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        context.formatPriceEurOnly(deal.product!.price),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return _InfoItem(
                      label: l10n?.minOrder ?? 'Min Order',
                      value: '${deal.minOrderQuantity}',
                      icon: Icons.arrow_downward,
                    );
                  },
                ),
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return _InfoItem(
                      label: l10n?.target ?? 'Target',
                      value: '${deal.targetQuantity}',
                      icon: Icons.flag,
                    );
                  },
                ),
              ],
            ),
            // Shipping Info
            if (deal.shippingDisplay != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return Row(
                    children: [
                      Icon(
                        Icons.local_shipping,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          deal.shippingDisplay!.format(
                            shippingWithFreeThreshold:
                                l10n?.shippingWithFreeThreshold ??
                                    'Shipping: {amount} (Free for {threshold}+ units)',
                            freeShippingForThreshold:
                                l10n?.freeShippingForThreshold ??
                                    'Free shipping for {threshold}+ units',
                            shippingBaseOnly:
                                l10n?.shippingBaseOnly ?? 'Shipping: {amount}',
                            shippingWithPerUnit:
                                l10n?.shippingWithPerUnit ??
                                    'Shipping: {base} + {perUnit} per unit',
                            formatPrice: (v) => context.formatPriceEurOnly(v),
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(
      BuildContext context, DealDetail deal, ThemeData theme) {
    final product = deal.product!;
    final hasVariant = product.hasVariant;

    return Card(
      child: InkWell(
        onTap: () => context.push('/products/${product.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.inventory_2_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (hasVariant &&
                            product.variantAttributesString != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.style,
                                  size: 14,
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  product.variantAttributesString!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        theme.colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Regular Price',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.formatPriceEurOnly(product.price),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '(${context.formatPriceUsdFromEur(product.price)})',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (hasVariant && product.variantSku != null) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'SKU',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          product.variantSku!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              if (hasVariant && product.variantAvailableStock != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.inventory,
                      size: 16,
                      color: product.variantAvailableStock! > 0
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Stock: ${product.variantAvailableStock}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: product.variantAvailableStock! > 0
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWholesalerCard(
      BuildContext context, DealDetail deal, ThemeData theme) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: deal.wholesaler?.avatarUrl != null
              ? CachedNetworkImageProvider(deal.wholesaler?.avatarUrl ??
                  'https://placehold.co/100x100/png')
              : null,
          child: deal.wholesaler?.avatarUrl == null
              ? Text((deal.wholesaler?.fullName ?? 'W')
                  .substring(0, 1)
                  .toUpperCase())
              : null,
        ),
        title: Text(
          deal.wholesaler!.businessName ?? deal.wholesaler!.fullName,
        ),
        subtitle: Builder(
          builder: (context) => Text(
            AppLocalizations.of(context)?.wholesaler ?? 'Wholesaler',
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/wholesalers/${deal.wholesaler!.id}'),
      ),
    );
  }

  Widget _buildInactiveCard(
      BuildContext context, DealDetail deal, ThemeData theme) {
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              deal.isEnded
                  ? Icons.event_busy_outlined
                  : Icons.schedule_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return Text(
                    deal.isEnded
                        ? (l10n?.dealEnded ?? 'This deal has ended')
                        : (l10n?.dealNotStarted ?? 'This deal has not started yet'),
                    style: theme.textTheme.bodyLarge,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard(
      BuildContext context, DealDetail deal, ThemeData theme, bool canManageDeal) {
    final l10n = AppLocalizations.of(context);
    final isAdminOwnDeal = deal.wholesaler?.isAdminOwnDeal ?? false;
    final String message = canManageDeal
        ? (l10n?.adminWholesalerManageHint ??
            'As an Admin or Wholesaler, you can manage this deal but cannot place orders. Use the menu button (⋮) in the app bar to edit or close this deal.')
        : isAdminOwnDeal
            ? (l10n?.adminDealOnlyOwnerCanBid ??
                'Only the admin (deal owner) can add bids on admin deals. Kiosk users cannot place orders on this deal.')
            : (l10n?.kioskOnlyPlaceOrders ??
                'Only Kiosk/Shop accounts can place orders on this deal.');
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  canManageDeal ? Icons.admin_panel_settings : Icons.info_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    canManageDeal
                        ? (l10n?.managementView ?? 'Management View')
                        : (l10n?.ordering ?? 'Ordering'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMenuAction(
      BuildContext context, WidgetRef ref, String action) async {
    final repo = ref.read(dealRepositoryProvider);

    switch (action) {
      case 'edit':
        // Fetch full deal detail with multilingual data from admin API
        if (context.mounted) {
          try {
            final managerRepo = ref.read(managerRepositoryProvider);
            final dealData = await managerRepo.fetchDealDetail(deal.id);

            if (context.mounted) {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => SizedBox(
                  height: MediaQuery.of(context).size.height * 0.9,
                  child: EditDealModal(
                    deal: dealData,
                    onSave: (data) async {
                      await managerRepo.updateDeal(deal.id, data.toJson());
                      if (context.mounted) {
                        ref.invalidate(dealDetailProvider(deal.id));
                        ref.invalidate(dealListControllerProvider);
                        ref.invalidate(managerDealsProvider);
                      }
                    },
                  ),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              SnackbarUtils.showError(
                context,
                '${AppLocalizations.of(context)?.failedToLoadDealData ?? 'Failed to load deal data'}: $e',
              );
            }
          }
        }
        break;

      case 'close':
        final l10n = AppLocalizations.of(context);
        final result = await showDialog<({bool confirmed, bool goalReached})>(
          context: context,
          builder: (dialogContext) {
            bool goalReached = false; // keep in outer closure so it persists across setState
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.close, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(l10n?.closeDeal ?? 'Close Deal'),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.closeDealConfirmMessage ??
                              'Are you sure you want to close this deal? This action cannot be undone.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        CheckboxListTile(
                          value: goalReached,
                          onChanged: (v) => setState(() => goalReached = v ?? false),
                          title: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 22,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n?.closeDealGoalReached ?? 'Goal reached',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 12, top: 4),
                          child: Text(
                            l10n?.closeDealGoalReachedHint ??
                                'If checked: all pending orders will be auto-confirmed (deal successfully filled). '
                                'If unchecked: the deal will close but you can confirm orders manually later.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(null),
                      child: Text(l10n?.cancel ?? 'Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop((confirmed: true, goalReached: goalReached)),
                      child: Text(l10n?.closeDeal ?? 'Close Deal'),
                    ),
                  ],
                );
              },
            );
          },
        );

        if (result != null && result.confirmed && context.mounted) {
          try {
            final success = await repo.closeDeal(deal.id, goalReached: result.goalReached);
            if (success) {
              if (context.mounted) {
                SnackbarUtils.showSuccess(
                  context,
                  AppLocalizations.of(context)?.dealClosedSuccess ??
                      'Deal closed successfully',
                );
                ref.invalidate(dealDetailProvider(deal.id));
                ref.invalidate(dealListControllerProvider);
                ref.invalidate(managerDealsProvider);
              }
            } else {
              if (context.mounted) {
                SnackbarUtils.showError(
                  context,
                  AppLocalizations.of(context)?.failedToCloseDeal ??
                      'Failed to close deal',
                );
              }
            }
          } catch (e) {
            if (context.mounted) {
              SnackbarUtils.showError(
                context,
                '${AppLocalizations.of(context)?.failedToCloseDeal ?? 'Failed to close deal'}: $e',
              );
            }
          }
        }
        break;
    }
  }

  IconData _iconForDealType(DealType type) {
    switch (type) {
      case DealType.auction:
        return Icons.gavel;
      case DealType.priceDrop:
        return Icons.trending_down;
      case DealType.limitedStock:
        return Icons.inventory;
    }
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
