import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/location/location_service.dart';
import '../../data/models/dashboard_models.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../deals/data/models/deal_models.dart';
import '../../../deals/data/repositories/deal_repository.dart';
// import '../../../deals/presentation/screens/deal_list_screen.dart';
import '../../../orders/presentation/controllers/cart_controller.dart';
import '../../../orders/presentation/screens/cart_screen.dart';
import '../../../orders/presentation/widgets/cart_icon_button.dart';
import '../widgets/product_list_item.dart';
import '../widgets/product_image_gallery.dart';
import '../widgets/variant_selector.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/currency_controller.dart';
import '../../../../core/services/currency_service.dart';
import 'category_detail_screen.dart';
import 'wholesaler_profile_screen.dart';
import '../../../reviews/presentation/widgets/reviews_section.dart';
import '../../../reviews/presentation/widgets/review_form_modal.dart';
import '../../../reviews/data/repositories/review_repository.dart';
import '../../../reviews/data/models/review_models.dart';

// Import provider from reviews_section
import '../../../reviews/presentation/widgets/reviews_section.dart' as reviews;

final productDetailProvider =
    FutureProvider.autoDispose.family<ProductDetail, String>((ref, id) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.fetchProductDetail(id);
});

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});

  static const routePath = '/products/:id';
  static const routeName = 'productDetail';

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('ProductDetailScreen build');
    final detailAsync = ref.watch(productDetailProvider(productId));

    return detailAsync.when(
      data: (detail) => _ProductDetailView(detail: detail),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(
          actions: [
            const CartIconButton(),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)?.unableToLoadProduct ??
                    'Unable to load product',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return ElevatedButton(
                    onPressed: () =>
                        ref.invalidate(productDetailProvider(productId)),
                    child: Text(l10n?.retry ?? 'Retry'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductDetailView extends ConsumerStatefulWidget {
  const _ProductDetailView({required this.detail});

  final ProductDetail detail;

  @override
  ConsumerState<_ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends ConsumerState<_ProductDetailView> {
  String? _selectedVariantId;

  @override
  void initState() {
    super.initState();
    _selectedVariantId = widget.detail.defaultVariant?.id;
  }

  ProductVariant? get _selectedVariant {
    if (widget.detail.variants == null || widget.detail.variants!.isEmpty) {
      return null;
    }
    if (_selectedVariantId == null) {
      return widget.detail.defaultVariant;
    }
    return widget.detail.variants!.firstWhere(
      (v) => v.id == _selectedVariantId,
      orElse: () =>
          widget.detail.defaultVariant ?? widget.detail.variants!.first,
    );
  }

  double get _displayPrice {
    final variant = _selectedVariant;
    if (variant != null) return variant.price;
    return widget.detail.displayPrice;
  }

  int? get _displayStock {
    final variant = _selectedVariant;
    if (variant != null) return variant.availableStock;
    return widget.detail.displayStock;
  }

  List<String> get _allImageUrls {
    final d = widget.detail;
    if (d.images != null && d.images!.isNotEmpty) return d.images!;
    if (d.imageUrl.isNotEmpty) return [d.imageUrl];
    return [];
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(
        currencyControllerProvider); // Rebuild when display currency changes
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.detail.title),
        actions: const [CartIconButton()],
      ),
      body: CustomScrollView(
        slivers: [
          // Hero Image + Gallery (Amazon/Flipkart style)
          SliverToBoxAdapter(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              child: ProductImageGallery(
                imageUrls: _allImageUrls,
                height: 320,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Price Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Price',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.formatPriceEurOnly(_displayPrice),
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '(${context.formatPriceUsdFromEur(_displayPrice)})',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer
                                      .withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (l10n?.perUnitLabel
                                    .replaceAll('{unit}', widget.detail.unit) ??
                                'Per ${widget.detail.unit}'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                      if (_displayStock != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inventory_2,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_displayStock',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                (l10n?.inStock ?? 'in stock'),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Variant Selector
                if (widget.detail.variants != null &&
                    widget.detail.variants!.isNotEmpty) ...[
                  VariantSelector(
                    variants: widget.detail.variants!,
                    selectedVariantId: _selectedVariantId,
                    onVariantSelected: (variantId) {
                      setState(() {
                        _selectedVariantId = variantId;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                ],
                // Description
                if (widget.detail.description != null) ...[
                  Text(
                    l10n?.description ?? 'Description',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.detail.description!,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                ],
                // Category
                if (widget.detail.category != null) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.category_outlined),
                      title: Text(widget.detail.category!.name),
                      subtitle: Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return Text(l10n?.category ?? 'Category');
                        },
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context
                          .push('/categories/${widget.detail.category!.slug}'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Wholesaler
                if (widget.detail.wholesaler != null) ...[
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            widget.detail.wholesaler?.avatarUrl != null
                                ? CachedNetworkImageProvider(
                                    widget.detail.wholesaler!.avatarUrl)
                                : null,
                        child: widget.detail.wholesaler?.avatarUrl == null
                            ? Text((widget.detail.wholesaler?.businessName ??
                                    'W')[0]
                                .toUpperCase())
                            : null,
                      ),
                      title: Text(widget.detail.wholesaler!.businessName),
                      subtitle: Row(
                        children: [
                          if (widget.detail.wholesaler!.city != null) ...[
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(widget.detail.wholesaler!.city!),
                            const SizedBox(width: 12),
                          ],
                          if (widget.detail.wholesaler!.distanceKm != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${widget.detail.wholesaler!.distanceKm!.toStringAsFixed(1)} km away',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        debugPrint(
                            'onTap: Wholesaler Profile, Navigating to WholesalerProfileScreen Id : ${widget.detail.wholesaler!.id}');
                        context.push(
                            '/wholesalers/${widget.detail.wholesaler!.id}');
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Active deals for this product
                _ActiveDealsForProduct(productId: widget.detail.id),
                const SizedBox(height: 24),
                // Action Buttons Row - Only for Kiosk/Shop owners
                Consumer(
                  builder: (context, ref, child) {
                    final authState = ref.watch(authControllerProvider);
                    final userRole = authState.valueOrNull?.user.role;
                    final isKiosk = userRole == UserRole.kiosk;

                    if (!isKiosk) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                (l10n?.onlyKioskCanPurchase ??
                                    'Only Kiosk/Shop accounts can purchase products'),
                                style: TextStyle(color: Colors.amber[900]),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final effectiveStock = _displayStock ?? 0;
                    final isOutOfStock = effectiveStock <= 0;

                    if (isOutOfStock) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .errorContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Theme.of(context).colorScheme.error),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                color: Theme.of(context).colorScheme.error),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n?.outOfStock ?? 'Out of stock',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              ref
                                  .read(cartControllerProvider.notifier)
                                  .addProduct(widget.detail,
                                      quantity: 1,
                                      variantId: _selectedVariantId);

                              // Clear any existing snackbar before showing new one
                              ScaffoldMessenger.of(context).clearSnackBars();
                              final l10n = AppLocalizations.of(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      l10n?.addedToCart ?? '✅ Added to cart'),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.add_shopping_cart),
                            label: Builder(
                              builder: (context) {
                                final l10n = AppLocalizations.of(context);
                                return Text(l10n?.addToCart ?? 'Add to Cart');
                              },
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ref
                                  .read(cartControllerProvider.notifier)
                                  .addProduct(widget.detail,
                                      quantity: 1,
                                      variantId: _selectedVariantId);
                              context.push(CartScreen.routePath);
                            },
                            icon: const Icon(Icons.shopping_bag_outlined),
                            label: Builder(
                              builder: (context) {
                                final l10n = AppLocalizations.of(context);
                                return Text(l10n?.buyNow ?? 'Buy Now');
                              },
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Reviews Section - moved up before similar products
                _ProductReviewsSection(productId: widget.detail.id),
                const SizedBox(height: 24),
                // Similar Products from Same Category
                if (widget.detail.category != null)
                  _SimilarProductsSection(
                    categorySlug: widget.detail.category!.slug,
                    excludeProductId: widget.detail.id,
                    wholesalerId: widget.detail.wholesaler?.id,
                  ),
                const SizedBox(height: 24),
                // More Products from Same Wholesaler
                if (widget.detail.wholesaler != null)
                  _MoreFromWholesalerSection(
                    wholesalerId: widget.detail.wholesaler!.id,
                    excludeProductId: widget.detail.id,
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveDealsForProduct extends ConsumerWidget {
  const _ActiveDealsForProduct({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final repo = ref.watch(dealRepositoryProvider);

    return FutureBuilder<DealListPage>(
      future: repo.fetchDeals(
        productId: productId,
        status: DealStatus.live,
        limit: 5,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.items.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      (l10n?.noActiveDealsForProduct ??
                          'No active deals for this product'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final deals = snapshot.data!.items;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (l10n?.activeDealsForProduct ??
                  'Active deals for this product'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: deals.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final deal = deals[index];
                  return GestureDetector(
                    onTap: () => context.push('/deals/${deal.id}'),
                    child: Container(
                      width: 220,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            deal.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${context.formatPriceEurOnly(deal.dealPrice)} / unit',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '(${context.formatPriceUsdFromEur(deal.dealPrice)})',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: ((deal.isEnded ? 100.0 : deal.progressPercent) / 100).clamp(0.0, 1.0),
                            minHeight: 4,
                            color: const Color(0xFF0C9FD0),
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            deal.isEnded
                                ? (l10n?.dealClosed ?? 'Deal Closed')
                                : '${deal.receivedQuantity}/${deal.targetQuantity} ordered',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.blueGrey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SimilarProductsSection extends ConsumerWidget {
  const _SimilarProductsSection({
    required this.categorySlug,
    required this.excludeProductId,
    this.wholesalerId,
  });

  final String categorySlug;
  final String excludeProductId;
  final String? wholesalerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final location = ref.watch(locationControllerProvider).valueOrNull;
    final state = ref.watch(categoryDetailProvider((
      slug: categorySlug,
      wholesalerId: wholesalerId,
      lat: location?.latitude,
      lng: location?.longitude,
    )));

    if (state.isLoading || state.products.isEmpty) {
      return const SizedBox.shrink();
    }

    final similarProducts =
        state.products.where((p) => p.id != excludeProductId).take(5).toList();

    if (similarProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              (l10n?.similarProducts ?? 'Similar Products'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.push('/categories/$categorySlug'),
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return Text(l10n?.viewAll ?? 'View All');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: similarProducts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final product = similarProducts[index];
            return ProductListItem(
              product: product,
              onTap: () => context.push('/products/${product.id}'),
            );
          },
        ),
      ],
    );
  }
}

class _MoreFromWholesalerSection extends ConsumerWidget {
  const _MoreFromWholesalerSection({
    required this.wholesalerId,
    required this.excludeProductId,
  });

  final String wholesalerId;
  final String excludeProductId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(wholesalerProfileProvider(wholesalerId));

    return profileAsync.when(
      data: (profile) {
        final moreProducts = profile.featuredProducts
            .where((p) => p.id != excludeProductId)
            .take(5)
            .toList();

        if (moreProducts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    (l10n?.moreFromWholesaler
                            .replaceAll(
                                '{name}', profile.wholesaler.businessName) ??
                        'More from ${profile.wholesaler.businessName}'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/wholesalers/$wholesalerId'),
                  child: Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Text(l10n?.viewAll ?? 'View All');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: moreProducts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final product = moreProducts[index];
                return ProductListItem(
                  product: product,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  padding: const EdgeInsets.all(5),
                  onTap: () => context.push('/products/${product.id}'),
                );
              },
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ProductReviewsSection extends ConsumerStatefulWidget {
  const _ProductReviewsSection({required this.productId});

  final String productId;

  @override
  ConsumerState<_ProductReviewsSection> createState() =>
      _ProductReviewsSectionState();
}

class _ProductReviewsSectionState
    extends ConsumerState<_ProductReviewsSection> {
  bool _isLoadingEligibleOrders = false;

  @override
  Widget build(BuildContext context) {
    return ReviewsSection(
      productId: widget.productId,
      onWriteReview: () async {
        // Show loading indicator
        if (mounted) {
          setState(() {
            _isLoadingEligibleOrders = true;
          });
        }

        // Get eligible orders for this product
        final repo = ref.read(reviewRepositoryProvider);
        try {
          final eligibleOrders =
              await repo.getEligibleOrders(productId: widget.productId);

          if (eligibleOrders.isEmpty) {
            if (context.mounted) {
              final l10n = AppLocalizations.of(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n?.youCanOnlyReviewFromDeliveredOrders ??
                        (l10n?.canOnlyReviewFromDelivered ??
                            'You can only review products from delivered orders'),
                  ),
                ),
              );
            }
            return;
          }

          // Show order selection if multiple orders
          EligibleOrder? selectedOrder;
          if (eligibleOrders.length > 1) {
            selectedOrder = await showDialog<EligibleOrder>(
              context: context, // ignore: use_build_context_synchronously
              builder: (context) =>
                  _OrderSelectionDialog(orders: eligibleOrders),
            );
          } else {
            selectedOrder = eligibleOrders.first;
          }

          if (!context.mounted) return;
          if (selectedOrder != null) {
            // Check if review already exists
            if (selectedOrder.hasReview) {
              final l10n = AppLocalizations.of(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n?.youHaveAlreadyReviewed ??
                        (l10n?.alreadyReviewedThisProduct ??
                            'You have already reviewed this product from this order')),
                  ),
                );
              return;
            }

            // Show review form
            final result = await showDialog<bool>(
              context: context,
              builder: (context) => ReviewFormModal(
                productId: widget.productId,
                orderId: selectedOrder!.orderId,
                orderItemId: selectedOrder.orderItemId,
              ),
            );

            if (result == true && context.mounted) {
              // Refresh reviews - invalidate all product reviews for this product
              ref.invalidate(
                reviews.productReviewsProvider(
                  reviews.ProductReviewsParams(productId: widget.productId),
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isLoadingEligibleOrders = false;
            });
          }
          if (context.mounted) {
            final l10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${l10n?.error ?? 'Error'}: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      isLoading: _isLoadingEligibleOrders,
    );
  }
}

class _OrderSelectionDialog extends StatelessWidget {
  const _OrderSelectionDialog({required this.orders});

  final List<EligibleOrder> orders;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                (l10n?.selectOrderToReview ?? 'Select Order to Review'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return ListTile(
                    leading: order.productImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              order.productImageUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image),
                            ),
                          )
                        : const Icon(Icons.shopping_bag),
                    title: Text(order.productTitle),
                    subtitle: Text(
                      order.orderNumber ??
                          (l10n?.orderN
                                  .replaceAll(
                                      '{id}', order.orderId.substring(0, 8)) ??
                              'Order #${order.orderId.substring(0, 8)}'),
                    ),
                    trailing: order.hasReview
                        ? Builder(
                            builder: (context) {
                              final l10n = AppLocalizations.of(context);
                              return Chip(
                                label: Text(l10n?.reviewed ?? 'Reviewed'),
                                backgroundColor: Colors.green.withValues(alpha: 0.1),
                              );
                            },
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: order.hasReview
                        ? null
                        : () => Navigator.of(context).pop(order),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n?.cancel ?? 'Cancel'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
