import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../../shared/widgets/network_avatar.dart';
import '../../../../shared/widgets/search_bar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/dashboard_models.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../../deals/presentation/screens/deal_list_screen.dart';
import '../../../orders/presentation/widgets/cart_icon_button.dart';
import '../widgets/product_list_item.dart';
import 'category_detail_screen.dart';
import 'products_list_screen.dart';

final wholesalerProfileProvider = FutureProvider.autoDispose
    .family<WholesalerProfile, String>((ref, id) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.fetchWholesalerProfile(id);
});

class WholesalerProfileScreen extends ConsumerWidget {
  const WholesalerProfileScreen({super.key, required this.wholesalerId});

  static const routePath = '/wholesalers/:id';
  static const routeName = 'wholesalerProfile';

  final String wholesalerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(wholesalerProfileProvider(wholesalerId));

    return profileAsync.when(
      data: (profile) => _WholesalerProfileView(profile: profile),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
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
                (AppLocalizations.of(context)?.unableToLoadWholesaler ??
                    'Unable to load wholesaler'),
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
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(wholesalerProfileProvider(wholesalerId)),
                child: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return Text(l10n?.retry ?? 'Retry');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WholesalerProfileView extends ConsumerStatefulWidget {
  const _WholesalerProfileView({required this.profile});

  final WholesalerProfile profile;

  @override
  ConsumerState<_WholesalerProfileView> createState() =>
      _WholesalerProfileViewState();
}

class _WholesalerProfileViewState
    extends ConsumerState<_WholesalerProfileView> {
  final TextEditingController _productSearchController =
      TextEditingController();
  String _productSearchQuery = '';
  Timer? _productSearchDebounceTimer;

  // Server-side search providers
  final _productSearchProvider = FutureProvider.autoDispose
      .family<List<DashboardProduct>, ({String query, String wholesalerId})>(
    (ref, params) async {
      if (params.query.trim().isEmpty) {
        return [];
      }
      final repo = ref.watch(dashboardRepositoryProvider);
      final location = ref.read(locationControllerProvider).valueOrNull;
      return repo.searchProducts(
        params.query,
        latitude: location?.latitude,
        longitude: location?.longitude,
        wholesalerId: params.wholesalerId,
      );
    },
  );

  @override
  void dispose() {
    _productSearchDebounceTimer?.cancel();
    _productSearchController.dispose();
    super.dispose();
  }

  void _onProductSearchChanged(String query) {
    // Cancel previous debounce timer
    _productSearchDebounceTimer?.cancel();

    // Debounce search to avoid too many API calls while typing
    _productSearchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _productSearchQuery = query.trim();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final wholesaler = widget.profile.wholesaler;

    // Use server-side search for products if query is provided
    final productSearchAsync = _productSearchQuery.isNotEmpty
        ? ref.watch(_productSearchProvider((
            query: _productSearchQuery,
            wholesalerId: wholesaler.id,
          )))
        : null;

    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final isAdminOrSubAdmin =
        user != null && Permissions.isAdminOrSubAdmin(user.role);

    return Scaffold(
      appBar: AppBar(
        title: Text(wholesaler.businessName),
        actions: [
          if (isAdminOrSubAdmin)
            IconButton(
              icon: const Icon(Icons.local_offer_outlined),
              tooltip: l10n?.viewDeals ?? 'View deals',
              onPressed: () {
                context.push(
                  DealListScreen.routePath,
                  extra: {
                    'title': l10n?.dealsFromWholesaler
                            .replaceAll('{name}', wholesaler.businessName) ??
                        'Deals from ${wholesaler.businessName}',
                    'wholesalerId': wholesaler.id,
                  },
                );
              },
            ),
          const CartIconButton(),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Contact & Info Card Section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar and Basic Info Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: cs.outlineVariant,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: NetworkAvatar(
                          imageUrl: wholesaler.avatarUrl,
                          size: 70,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Business Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              wholesaler.businessName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              wholesaler.tagline ??
                                  (l10n?.kfProductDealTagline ??
                                      'KF Product Deal, Helping you find the best deals'),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Divider
                  Divider(color: cs.outlineVariant, height: 1),
                  const SizedBox(height: 16),
                  // Contact & Location Details
                  if (wholesaler.locations.isNotEmpty ||
                      wholesaler.city != null ||
                      wholesaler.distanceKm != null)
                    Column(
                      children: [
                        // Location Details
                        if (wholesaler.locations.isNotEmpty)
                          ...wholesaler.locations.map((location) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          cs.primaryContainer.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.location_on,
                                      size: 20,
                                      color: cs.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (location.label.isNotEmpty)
                                          Text(
                                            location.label,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        if (location.address != null &&
                                            location.address!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            location.address!,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                        if (location.city != null ||
                                            location.country != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            [
                                              if (location.city != null)
                                                location.city!,
                                              if (location.country != null)
                                                location.country!,
                                            ].join(', '),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        // City (if no locations but city exists)
                        if (wholesaler.locations.isEmpty &&
                            wholesaler.city != null)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.location_city,
                                  size: 20,
                                  color: cs.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  wholesaler.city!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: cs.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        // Distance
                        if (wholesaler.distanceKm != null) ...[
                          if (wholesaler.locations.isNotEmpty ||
                              wholesaler.city != null)
                            const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: cs.secondaryContainer.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.navigation,
                                  size: 20,
                                  color: cs.secondary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                wholesaler.distanceKm! < 1
                                    ? '${(wholesaler.distanceKm! * 1000).toStringAsFixed(0)}m away'
                                    : '${wholesaler.distanceKm!.toStringAsFixed(1)}km away',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    )
                  else
                    // No location info available
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          (l10n?.locationInfoNotAvailable ??
                              'Location information not available'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Map and Info
          if (wholesaler.locations.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (l10n?.location ?? 'Location'),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: _WholesalerLocationsMap(
                          locations: wholesaler.locations),
                    ),
                  ],
                ),
              ),
            ),

          // Categories List — 2-column grid (same as View All Categories)
          if (widget.profile.topCategories.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n?.categories ?? 'Categories',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (widget.profile.topCategories.length > 2)
                      TextButton(
                        onPressed: () {
                          context.push(
                            CategoryDetailScreen.routePath
                                .replaceAll(':slug', 'all'),
                            extra: {'wholesalerId': wholesaler.id},
                          );
                        },
                        child: Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            return Text(l10n?.viewAll ?? 'View All');
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category = widget.profile.topCategories[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          if (category.slug != null) {
                            context.push(
                              CategoryDetailScreen.routePath
                                  .replaceAll(':slug', category.slug!),
                              extra: {'wholesalerId': wholesaler.id},
                            );
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Center-crop image for any size/aspect ratio
                            Expanded(
                              child: Stack(
                                clipBehavior: Clip.antiAlias,
                                fit: StackFit.expand,
                                children: [
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            cs.primaryContainer,
                                            cs.secondaryContainer,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (category.imageUrl.isNotEmpty)
                                    Positioned.fill(
                                      child: CachedNetworkImage(
                                        imageUrl: category.imageUrl,
                                        fit: BoxFit.cover,
                                        alignment: Alignment.center,
                                        placeholder: (_, __) => Center(
                                          child: Icon(
                                            Icons.category,
                                            size: 48,
                                            color: cs.onPrimaryContainer,
                                          ),
                                        ),
                                        errorWidget: (_, __, ___) => Center(
                                          child: Icon(
                                            Icons.category,
                                            size: 48,
                                            color: cs.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    Center(
                                      child: Icon(
                                        Icons.category,
                                        size: 48,
                                        color: cs.onPrimaryContainer,
                                      ),
                                    ),
                                  if (category.totalProducts > 0)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.5),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${category.totalProducts}',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                category.name,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: widget.profile.topCategories.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ],

          // Products Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                (l10n?.productsSection ?? 'Products'),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Product Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: AppSearchBar(
                controller: _productSearchController,
                hintText: l10n?.searchProductsFromWholesaler
                        .replaceAll('{name}', wholesaler.businessName) ??
                    'Search products from ${wholesaler.businessName}...',
                onChanged: _onProductSearchChanged,
              ),
            ),
          ),

          // Products List
          if (_productSearchQuery.isEmpty) ...[
            // Show featured products when no search
            if (widget.profile.featuredProducts.isNotEmpty) ...[
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = widget.profile.featuredProducts[index];
                    return ProductListItem(
                      product: product,
                      onTap: () => context.push('/products/${product.id}'),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                    );
                  },
                  childCount: widget.profile.featuredProducts.length,
                ),
              ),
              // View All button
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        context.push(
                          ProductsListScreen.routePath,
                          extra: {
                            'wholesalerId': wholesaler.id,
                            'title': l10n?.productsFromWholesaler
                                    .replaceAll('{name}', wholesaler.businessName) ??
                                'Products from ${wholesaler.businessName}',
                            'featuredOnly': false,
                            'showSearch': true,
                          },
                        );
                      },
                      child: Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return Text(
                              l10n?.viewAllProducts ?? 'View All Products');
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // No products available
              SliverToBoxAdapter(
                child: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(l10n?.noProductsAvailable ??
                            'No products available'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ] else ...[
            // Show server-side search results
            productSearchAsync?.when(
                  data: (products) {
                    if (products.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Builder(
                              builder: (context) {
                                final l10n = AppLocalizations.of(context);
                                return Text(
                                  l10n?.noProductsFound ??
                                      'No products found',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = products[index];
                          return ProductListItem(
                            product: product,
                            onTap: () =>
                                context.push('/products/${product.id}'),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                          );
                        },
                        childCount: products.length,
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (error, _) => SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: cs.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              (l10n?.errorSearchingProducts ??
                                  'Error searching products'),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ) ??
                const SliverToBoxAdapter(child: SizedBox.shrink()),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _WholesalerLocationsMap extends StatelessWidget {
  const _WholesalerLocationsMap({required this.locations});

  final List<WholesalerLocationPin> locations;

  @override
  Widget build(BuildContext context) {
    if (locations.isEmpty) return const SizedBox.shrink();

    final first = locations.first;
    final markers = locations
        .map(
          (loc) => Marker(
            point: LatLng(loc.latitude, loc.longitude),
            width: 40,
            height: 40,
            child: const Icon(
              Icons.location_on,
              size: 32,
              color: Colors.redAccent,
            ),
          ),
        )
        .toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(first.latitude, first.longitude),
          initialZoom: 11,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}
