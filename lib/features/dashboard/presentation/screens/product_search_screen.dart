import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/location/location_service.dart';
import '../../data/models/dashboard_models.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../../orders/presentation/widgets/cart_icon_button.dart';
import '../widgets/product_list_item.dart';
import '../../../../shared/widgets/search_bar.dart';

final productSearchProvider = FutureProvider.autoDispose
    .family<List<DashboardProduct>, ({String query, double? lat, double? lng})>(
  (ref, params) async {
    if (params.query.trim().isEmpty) {
      return [];
    }
    final repo = ref.watch(dashboardRepositoryProvider);
    return repo.searchProducts(
      params.query,
      latitude: params.lat,
      longitude: params.lng,
    );
  },
);

class ProductSearchScreen extends ConsumerStatefulWidget {
  const ProductSearchScreen({super.key, this.initialQuery});

  static const routePath = '/search/products';
  static const routeName = 'productSearch';

  final String? initialQuery;

  @override
  ConsumerState<ProductSearchScreen> createState() =>
      _ProductSearchScreenState();
}

class _ProductSearchScreenState extends ConsumerState<ProductSearchScreen> {
  late final TextEditingController _searchController;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    debugPrint('ProductSearchScreen initState');
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _currentQuery = widget.initialQuery ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _currentQuery = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationControllerProvider).valueOrNull;
    final searchAsync = ref.watch(productSearchProvider((
      query: _currentQuery,
      lat: location?.latitude,
      lng: location?.longitude,
    )));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.searchProducts ?? 'Search Products',
        ),
        actions: const [CartIconButton()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppSearchBar(
              controller: _searchController,
              hintText: AppLocalizations.of(context)?.searchProductsHint ??
                  'Search products...',
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: searchAsync.when(
              data: (products) {
                if (_currentQuery.trim().isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start typing to search products',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  );
                }

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search term',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  cacheExtent: 400,
                  addAutomaticKeepAlives: false,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return RepaintBoundary(
                      child: ProductListItem(
                        product: product,
                        onTap: () => context.push('/products/${product.id}'),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error searching products',
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
