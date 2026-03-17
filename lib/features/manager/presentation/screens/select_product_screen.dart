import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../data/repositories/manager_repository.dart';

/// Provider for fetching products with pagination and search
final selectProductsProvider = StateNotifierProvider.autoDispose
    .family<SelectProductsController, AsyncValue<SelectProductsPage>, String?>(
  (ref, wholesalerId) => SelectProductsController(
    ref.watch(managerRepositoryProvider),
    initialWholesalerId: wholesalerId,
  ),
);

class SelectProductsPage {
  const SelectProductsPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.totalRows,
  });

  final List<Map<String, dynamic>> items;
  final int page;
  final int limit;
  final int totalRows;
}

class SelectProductsController
    extends StateNotifier<AsyncValue<SelectProductsPage>> {
  SelectProductsController(
    this._repo, {
    String? initialWholesalerId,
  })  : _wholesalerId = initialWholesalerId,
        super(const AsyncValue.loading()) {
    loadProducts();
  }

  final ManagerRepository _repo;
  int _currentPage = 1;
  String? _search;
  String? _wholesalerId;
  final int _pageSize = 25;

  void setWholesalerId(String? wholesalerId) {
    if (_wholesalerId == wholesalerId) return; // Avoid unnecessary reload
    _wholesalerId = wholesalerId;
    loadProducts(refresh: true);
  }

  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      state = const AsyncValue.loading();
    }

    try {
      final page = await _repo.fetchProducts(
        page: _currentPage,
        limit: _pageSize,
        search: _search,
        wholesalerId: _wholesalerId,
      );

      final items = page.items.map((product) {
        return {
          'id': product.id,
          'title': product.title,
          'price': product.price,
          'imageUrl': product.imageUrl,
          'status': product.status,
        };
      }).toList();

      state = AsyncValue.data(
        SelectProductsPage(
          items: items,
          page: page.page,
          limit: page.limit,
          totalRows: page.totalRows,
        ),
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void setSearch(String? search) {
    _search = search?.trim().isEmpty == true ? null : search?.trim();
    loadProducts(refresh: true);
  }

  void nextPage() {
    final current = state.value;
    if (current != null &&
        _currentPage < (current.totalRows / _pageSize).ceil()) {
      _currentPage++;
      loadProducts();
    }
  }

  void previousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      loadProducts();
    }
  }

  void refresh() {
    loadProducts(refresh: true);
  }
}

class SelectProductScreen extends ConsumerStatefulWidget {
  const SelectProductScreen({
    super.key,
    this.selectedProductId,
    this.wholesalerId,
  });

  final String? selectedProductId;
  final String? wholesalerId; // Filter products by wholesaler

  static const routePath = '/select/product';
  static const routeName = 'selectProduct';

  @override
  ConsumerState<SelectProductScreen> createState() =>
      _SelectProductScreenState();
}

class _SelectProductScreenState extends ConsumerState<SelectProductScreen> {
  final _searchController = TextEditingController();
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedProductId;
    _searchController.addListener(_onSearchChanged);

    // Wholesaler filter is now handled by the family provider
    // No need to set it manually as it's passed during provider creation
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Debounce will be handled by onSubmitted
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync =
        ref.watch(selectProductsProvider(widget.wholesalerId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.selectProduct ?? 'Select Product',
        ),
        actions: [
          if (_selectedId != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_selectedId);
              },
                              child: Text(
                                AppLocalizations.of(context)?.select ??
                                    'Select',
                              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)?.searchProductsHint ??
                    'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(selectProductsProvider(widget.wholesalerId)
                                  .notifier)
                              .setSearch(null);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (value) {
                ref
                    .read(selectProductsProvider(widget.wholesalerId).notifier)
                    .setSearch(value);
              },
            ),
          ),
          // List
          Expanded(
            child: productsAsync.when(
              data: (page) {
                final products = page.items;
                final totalRows = page.totalRows;
                final currentPage = page.page;
                final totalPages = (totalRows / page.limit).ceil();

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          (AppLocalizations.of(context)?.noProductsFound ??
                              'No products found'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchController.text.isNotEmpty
                              ? (AppLocalizations.of(context)
                                      ?.tryDifferentSearchTerm ??
                                  'Try a different search term')
                              : widget.wholesalerId != null
                                  ? (AppLocalizations.of(context)
                                          ?.noProductsFoundForWholesaler ??
                                      'No products found for selected wholesaler')
                                  : (AppLocalizations.of(context)
                                          ?.noProductsAvailable ??
                                      'No products available'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final id = product['id'] as String;
                          final title = product['title'] as String;
                          final price = product['price'] as double? ?? 0.0;
                          final imageUrl = product['imageUrl'] as String?;
                          final status = product['status'] as String?;
                          final isSelected = _selectedId == id;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : null,
                            child: ListTile(
                              leading: imageUrl != null && imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const SizedBox(
                                          width: 60,
                                          height: 60,
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            const Icon(
                                                Icons.image_not_supported),
                                      ),
                                    )
                                  : const Icon(Icons.inventory_2, size: 40),
                              title: Text(
                                title,
                                style: TextStyle(
                                  fontWeight:
                                      isSelected ? FontWeight.bold : null,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                  '${AppLocalizations.of(context)?.priceLabel ?? 'Price'}: \$${price.toStringAsFixed(2)}',
                                ),
                                  if (status != null)
                                    Text(
                                      '${AppLocalizations.of(context)?.statusLabel ?? 'Status'}: $status',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: status == 'approved'
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    )
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedId = id;
                                });
                                // Auto-select after a short delay for better UX
                                Future.delayed(
                                    const Duration(milliseconds: 300), () {
                                  if (context.mounted) {
                                    Navigator.of(context).pop(id);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    // Pagination
                    if (totalPages > 1)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: currentPage > 1
                                  ? () {
                                      ref
                                          .read(selectProductsProvider(
                                                  widget.wholesalerId)
                                              .notifier)
                                          .previousPage();
                                    }
                                  : null,
                            ),
                            Text(
                              (AppLocalizations.of(context)?.pageNOfM
                                      .replaceAll(
                                          '{current}', currentPage.toString())
                                      .replaceAll(
                                          '{total}', totalPages.toString()) ??
                                  'Page $currentPage of $totalPages'),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: currentPage < totalPages
                                  ? () {
                                      ref
                                          .read(selectProductsProvider(
                                                  widget.wholesalerId)
                                              .notifier)
                                          .nextPage();
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      (AppLocalizations.of(context)?.errorLoadingProducts ??
                          'Error loading products'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(selectProductsProvider(widget.wholesalerId)
                                .notifier)
                            .refresh();
                      },
                      child: Text(
                        AppLocalizations.of(context)?.retry ?? 'Retry',
                      ),
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
