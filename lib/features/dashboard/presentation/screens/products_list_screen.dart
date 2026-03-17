import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/location/location_service.dart';
import '../../../../shared/widgets/search_bar.dart';
import '../../data/models/dashboard_models.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../../orders/presentation/widgets/cart_icon_button.dart';
import '../widgets/product_list_item.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/language_controller.dart';

final productsListProvider = FutureProvider.autoDispose.family<
    ProductsPage,
    ({
      String query,
      int page,
      double? lat,
      double? lng,
      bool featuredOnly,
      String? wholesalerId
    })>(
  (ref, params) async {
    // Watch language to refresh when language changes
    ref.watch(languageControllerProvider);

    final repo = ref.watch(dashboardRepositoryProvider);

    if (params.query.trim().isEmpty) {
      // If no search query, fetch all products with pagination
      return repo.fetchAllProducts(
        page: params.page,
        latitude: params.lat,
        longitude: params.lng,
        featuredOnly: params.featuredOnly,
        wholesalerId: params.wholesalerId,
      );
    }

    // For search, use search endpoint (no pagination yet)
    final products = await repo.searchProducts(
      params.query,
      latitude: params.lat,
      longitude: params.lng,
      wholesalerId: params.wholesalerId,
    );

    // Convert search results to ProductsPage format
    return ProductsPage(
      items: products,
      page: 1,
      limit: products.length,
      totalRows: products.length,
      totalPages: 1,
    );
  },
);

class ProductsListScreen extends ConsumerStatefulWidget {
  const ProductsListScreen({
    super.key,
    this.initialQuery,
    this.featuredOnly = false,
    this.showSearch = true,
    this.showCartAction = true,
    this.title,
    this.wholesalerId,
  });

  static const routePath = '/products/all';
  static const routeName = 'productsList';

  final String? initialQuery;
  final bool featuredOnly;
  final bool showSearch;
  final bool showCartAction;
  final String? title;
  final String? wholesalerId;

  @override
  ConsumerState<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends ConsumerState<ProductsListScreen> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  String _currentQuery = '';
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _isInitialLoad = true;
  List<DashboardProduct> _accumulatedProducts = [];
  int _totalPages = 1;
  bool _hasError = false;
  Object? _error;
  late final bool _featuredOnly;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    debugPrint('ProductsListScreen initState');
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _currentQuery = widget.initialQuery ?? '';
    _featuredOnly = widget.featuredOnly;
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _currentQuery = value;
    });

    // Cancel previous debounce timer
    _searchDebounceTimer?.cancel();

    // Debounce search to avoid too many API calls while typing
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _currentPage = 1;
          _accumulatedProducts = []; // Reset accumulated products on search
          _isInitialLoad = true;
          _hasError = false;
          _isLoadingMore = false;
        });
        // Invalidate provider to trigger new fetch
        final location = ref.read(locationControllerProvider).valueOrNull;
        ref.invalidate(productsListProvider((
          query: value.trim(),
          page: 1,
          lat: location?.latitude,
          lng: location?.longitude,
          featuredOnly: _featuredOnly,
          wholesalerId: widget.wholesalerId,
        )));
      }
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_isLoadingMore ||
        _currentQuery.trim().isNotEmpty ||
        _currentPage >= _totalPages ||
        _isInitialLoad) {
      return; // Don't load more if already loading, searching, or no more pages
    }

    final location = ref.read(locationControllerProvider).valueOrNull;

    setState(() {
      _isLoadingMore = true;
    });

    // Fetch next page
    ref
        .read(productsListProvider((
      query: _currentQuery,
      page: _currentPage + 1,
      lat: location?.latitude,
      lng: location?.longitude,
      featuredOnly: _featuredOnly,
      wholesalerId: widget.wholesalerId,
    )).future)
        .then((nextPage) {
      if (mounted) {
        setState(() {
          _accumulatedProducts.addAll(nextPage.items);
          _currentPage = nextPage.page;
          _totalPages = nextPage.totalPages;
          _isLoadingMore = false;
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _hasError = true;
          _error = error;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationControllerProvider).valueOrNull;
    final productsAsync = ref.watch(productsListProvider((
      query: _currentQuery,
      page: 1, // Always fetch page 1, we accumulate manually
      lat: location?.latitude,
      lng: location?.longitude,
      featuredOnly: _featuredOnly,
      wholesalerId: widget.wholesalerId,
    )));

    // Handle initial load and update accumulated products
    productsAsync.whenData((page) {
      if (_isInitialLoad && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _accumulatedProducts = List.from(page.items);
            _currentPage = page.page;
            _totalPages = page.totalPages;
            _isInitialLoad = false;
            _hasError = false;
          });
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title ??
              (AppLocalizations.of(context)?.allProducts ?? 'All Products'),
        ),
        actions: [
          if (widget.showCartAction) const CartIconButton(),
        ],
      ),
      body: Column(
        children: [
          if (widget.showSearch)
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppSearchBar(
                controller: _searchController,
                hintText: AppLocalizations.of(context)?.searchProductsHint ??
                    'Search products by name, SKU...',
                onChanged: _onSearchChanged,
              ),
            ),
          Expanded(
            child: _buildContent(context, productsAsync, location),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AsyncValue<ProductsPage> productsAsync,
    GeoPoint? location,
  ) {
    // Show loading only on initial load
    if (_isInitialLoad) {
      return productsAsync.when(
        data: (_) =>
            const SizedBox.shrink(), // Will be handled by whenData above
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error, location),
      );
    }

    // Show error state if there's an error and no products
    if (_hasError && _accumulatedProducts.isEmpty) {
      return _buildErrorState(context, _error, location);
    }

    // Show empty state
    if (_currentQuery.trim().isEmpty && _accumulatedProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)?.noProductsAvailable ??
                  'No products available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)?.productsWillAppearHere ??
                  'Products will appear here once they are added',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Show search empty state
    if (_currentQuery.trim().isNotEmpty && _accumulatedProducts.isEmpty) {
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
              AppLocalizations.of(context)?.noProductsFound ??
                  'No products found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)?.tryDifferentSearchTerm ??
                  'Try a different search term',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Show product list with pagination loading indicator, add padding to the bottom of the list to show the bottom navigation bar
    return ListView.builder(
      controller: _scrollController,
      cacheExtent: 400,
      addAutomaticKeepAlives: false,
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: _accumulatedProducts.length +
          (_isLoadingMore ? 1 : 0) +
          (_currentPage >= _totalPages && _accumulatedProducts.isNotEmpty
              ? 1
              : 0),
      itemBuilder: (context, index) {
        // Show loading indicator at bottom when loading more
        if (index == _accumulatedProducts.length && _isLoadingMore) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        // Show end of list indicator
        if (index == _accumulatedProducts.length &&
            _currentPage >= _totalPages &&
            _accumulatedProducts.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text(
                AppLocalizations.of(context)?.youveReachedEnd ??
                    "You've reached the end",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          );
        }

        // Show product item
        final product = _accumulatedProducts[index];
        return RepaintBoundary(
          child: ProductListItem(
            product: product,
            onTap: () => context.push('/products/${product.id}'),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    Object? error,
    GeoPoint? location,
  ) {
    return Center(
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
            AppLocalizations.of(context)?.errorLoadingProducts ??
                'Error loading products',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error?.toString() ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _currentPage = 1;
                _accumulatedProducts = [];
                _isInitialLoad = true;
                _hasError = false;
              });
              ref.invalidate(productsListProvider((
                query: _currentQuery,
                page: 1,
                lat: location?.latitude,
                lng: location?.longitude,
                featuredOnly: _featuredOnly,
                wholesalerId: widget.wholesalerId,
              )));
            },
            child: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return Text(l10n?.retry ?? 'Retry');
              },
            ),
          ),
        ],
      ),
    );
  }
}
