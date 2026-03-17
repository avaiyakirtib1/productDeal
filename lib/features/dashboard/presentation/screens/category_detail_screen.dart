import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/location/location_service.dart';
import '../../data/models/dashboard_models.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../../orders/presentation/widgets/cart_icon_button.dart';
import '../widgets/product_list_item.dart';

final categoryDetailProvider = StateNotifierProvider.autoDispose.family<
    CategoryDetailNotifier,
    CategoryDetailState,
    ({String slug, String? wholesalerId, double? lat, double? lng})>(
  (ref, params) {
    final repo = ref.watch(dashboardRepositoryProvider);
    return CategoryDetailNotifier(
      repo,
      slug: params.slug,
      wholesalerId: params.wholesalerId,
      latitude: params.lat,
      longitude: params.lng,
    );
  },
);

class CategoryDetailState {
  const CategoryDetailState({
    this.category,
    this.products = const [],
    this.page = 1,
    this.limit = 24,
    this.totalRows = 0,
    this.totalPages = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  final DashboardCategory? category;
  final List<DashboardProduct> products;
  final int page;
  final int limit;
  final int totalRows;
  final int totalPages;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;

  bool get hasNext => page < totalPages;
  bool get hasMore => hasNext && !isLoadingMore;

  CategoryDetailState copyWith({
    DashboardCategory? category,
    List<DashboardProduct>? products,
    int? page,
    int? limit,
    int? totalRows,
    int? totalPages,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
  }) {
    return CategoryDetailState(
      category: category ?? this.category,
      products: products ?? this.products,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalRows: totalRows ?? this.totalRows,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

class CategoryDetailNotifier extends StateNotifier<CategoryDetailState> {
  CategoryDetailNotifier(
    this._repo, {
    required this.slug,
    this.wholesalerId,
    this.latitude,
    this.longitude,
  }) : super(const CategoryDetailState()) {
    _loadInitial();
  }

  final DashboardRepository _repo;
  final String slug;
  final String? wholesalerId;
  final double? latitude;
  final double? longitude;

  Future<void> _loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final detail = await _repo.fetchCategoryDetail(
        slug,
        wholesalerId: wholesalerId,
        latitude: latitude,
        longitude: longitude,
        page: 1,
        limit: state.limit,
      );
      state = state.copyWith(
        category: detail.category,
        products: detail.products,
        page: detail.page,
        limit: detail.limit,
        totalRows: detail.totalRows,
        totalPages: detail.totalPages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final detail = await _repo.fetchCategoryDetail(
        slug,
        wholesalerId: wholesalerId,
        latitude: latitude,
        longitude: longitude,
        page: state.page + 1,
        limit: state.limit,
      );
      state = state.copyWith(
        products: [...state.products, ...detail.products],
        page: detail.page,
        totalRows: detail.totalRows,
        totalPages: detail.totalPages,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }
}

class CategoryDetailScreen extends ConsumerWidget {
  const CategoryDetailScreen({
    super.key,
    required this.slug,
    this.wholesalerId,
  });

  static const routePath = '/categories/:slug';
  static const routeName = 'categoryDetail';

  final String slug;
  final String? wholesalerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get user location for distance sorting
    final location = ref.watch(locationControllerProvider).valueOrNull;
    final state = ref.watch(categoryDetailProvider((
      slug: slug,
      wholesalerId: wholesalerId,
      lat: location?.latitude,
      lng: location?.longitude,
    )));

    if (state.isLoading && state.products.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null && state.products.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          actions: const [CartIconButton()],
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
                AppLocalizations.of(context)!.unableToLoadCategory,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                state.error.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(categoryDetailProvider((
                  slug: slug,
                  wholesalerId: wholesalerId,
                  lat: location?.latitude,
                  lng: location?.longitude,
                ))),
                child: Text(
                  AppLocalizations.of(context)?.retry ?? 'Retry',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _CategoryDetailView(
      state: state,
      onLoadMore: () => ref
          .read(categoryDetailProvider((
            slug: slug,
            wholesalerId: wholesalerId,
            lat: location?.latitude,
            lng: location?.longitude,
          )).notifier)
          .loadMore(),
    );
  }
}

class _CategoryDetailView extends StatefulWidget {
  const _CategoryDetailView({
    required this.state,
    required this.onLoadMore,
  });

  final CategoryDetailState state;
  final VoidCallback onLoadMore;

  @override
  State<_CategoryDetailView> createState() => _CategoryDetailViewState();
}

class _CategoryDetailViewState extends State<_CategoryDetailView> {
  late final ScrollController _scrollController;
  Timer? _loadMoreTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _loadMoreTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.state.hasMore) return;
    if (widget.state.isLoadingMore) return;

    final threshold = _scrollController.position.maxScrollExtent * 0.8;
    if (_scrollController.position.pixels >= threshold) {
      // Debounce load more to avoid multiple rapid calls
      _loadMoreTimer?.cancel();
      _loadMoreTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted && widget.state.hasMore && !widget.state.isLoadingMore) {
          widget.onLoadMore();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final category = state.category;

    if (category == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
        actions: const [CartIconButton()],
      ),
      body: state.products.isEmpty
          ? _buildEmptyState(context)
          : CustomScrollView(
              controller: _scrollController,
              slivers: [
                if (category.description != null &&
                    category.description!.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        category.description!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= state.products.length) {
                        return null;
                      }
                      final product = state.products[index];
                      return RepaintBoundary(
                        child: ProductListItem(
                          product: product,
                          onTap: () => context.push('/products/${product.id}'),
                        ),
                      );
                    },
                    childCount: state.products.length,
                    addAutomaticKeepAlives: false,
                  ),
                ),
                if (state.isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                if (state.hasMore && !state.isLoadingMore)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'Scroll to load more',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ),
                    ),
                  ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
              ],
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No products in this category',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Products will appear here once they are added to this category',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
