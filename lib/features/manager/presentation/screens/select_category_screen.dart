import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../dashboard/data/repositories/dashboard_repository.dart';

/// Provider for fetching categories with search
final selectCategoriesProvider = StateNotifierProvider.autoDispose<
    SelectCategoriesController, AsyncValue<List<Map<String, dynamic>>>>(
  (ref) => SelectCategoriesController(ref.watch(dashboardRepositoryProvider)),
);

class SelectCategoriesController
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  SelectCategoriesController(this._repo) : super(const AsyncValue.loading()) {
    loadCategories();
  }

  final DashboardRepository _repo;
  String? _search;

  Future<void> loadCategories({bool refresh = false}) async {
    if (refresh) {
      state = const AsyncValue.loading();
    }

    try {
      final categories = await _repo.fetchCategories(
        searchQuery: _search,
      );

      final items = categories.map((cat) {
        return {
          'id': cat.id,
          'name': cat.name,
          'slug': cat.slug,
          'imageUrl': cat.imageUrl,
          'description': cat.description,
          'productCount': cat.productCount,
        };
      }).toList();

      state = AsyncValue.data(items);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void setSearch(String? search) {
    _search = search?.trim().isEmpty == true ? null : search?.trim();
    loadCategories(refresh: true);
  }

  void refresh() {
    loadCategories(refresh: true);
  }
}

class SelectCategoryScreen extends ConsumerStatefulWidget {
  const SelectCategoryScreen({
    super.key,
    this.selectedCategoryId,
    this.selectedCategoryIds = const [],
    this.multiSelect = false,
  });

  final String? selectedCategoryId;
  final List<String> selectedCategoryIds;
  final bool multiSelect;

  static const routePath = '/select/category';
  static const routeName = 'selectCategory';

  @override
  ConsumerState<SelectCategoryScreen> createState() =>
      _SelectCategoryScreenState();
}

class _SelectCategoryScreenState extends ConsumerState<SelectCategoryScreen> {
  final _searchController = TextEditingController();
  String? _selectedId;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedCategoryId;
    _selectedIds.addAll(widget.selectedCategoryIds);
    _searchController.addListener(_onSearchChanged);
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
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(selectCategoriesProvider);

    final showDone = widget.multiSelect && _selectedIds.isNotEmpty;
    final showSelect = !widget.multiSelect && _selectedId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.multiSelect ? l10n.selectCategories : l10n.selectCategory),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchCategories,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(selectCategoriesProvider.notifier)
                              .setSearch(null);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (value) {
                ref.read(selectCategoriesProvider.notifier).setSearch(value);
              },
            ),
          ),
          // List
          Expanded(
            child: categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.category_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noCategoriesFound,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchController.text.isNotEmpty
                              ? l10n.tryDifferentSearchTerm
                              : l10n.noCategoriesAvailable,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final id = category['id'] as String;
                    final name = category['name'] as String;
                    final imageUrl = category['imageUrl'] as String?;
                    final description = category['description'] as String?;
                    final productCount = category['productCount'] as int? ?? 0;
                    final isSelected = widget.multiSelect
                        ? _selectedIds.contains(id)
                        : _selectedId == id;

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
                                  placeholder: (context, url) => const SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.category, size: 40),
                                ),
                              )
                            : const Icon(Icons.category, size: 40),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (description != null && description.isNotEmpty)
                              Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            if (productCount > 0)
                              Text(
                                l10n.productsCount.replaceAll('{n}', '$productCount'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                        onTap: () {
                          if (widget.multiSelect) {
                            setState(() {
                              if (_selectedIds.contains(id)) {
                                _selectedIds.remove(id);
                              } else {
                                _selectedIds.add(id);
                              }
                            });
                          } else {
                            setState(() => _selectedId = id);
                            Future.delayed(const Duration(milliseconds: 300),
                                () {
                              if (context.mounted) {
                                Navigator.of(context).pop(category);
                              }
                            });
                          }
                        },
                      ),
                    );
                  },
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
                      l10n.errorLoadingCategories,
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
                        ref.read(selectCategoriesProvider.notifier).refresh();
                      },
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: (showDone || showSelect)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final categories = categoriesAsync.value;
                      if (widget.multiSelect && _selectedIds.isNotEmpty && categories != null) {
                        final selected = categories
                            .where((c) => _selectedIds.contains(c['id'] as String?))
                            .toList();
                        Navigator.of(context).pop(selected);
                      } else if (!widget.multiSelect && _selectedId != null && categories != null) {
                        final selected = categories.firstWhere(
                          (c) => c['id'] == _selectedId,
                          orElse: () => <String, dynamic>{},
                        );
                        if (selected.isNotEmpty) {
                          Navigator.of(context).pop(selected);
                        }
                      }
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: Theme.of(context).textTheme.titleMedium,
                    ),
                    child: Text(
                      widget.multiSelect
                          ? '${l10n.done} (${_selectedIds.length})'
                          : l10n.select,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
