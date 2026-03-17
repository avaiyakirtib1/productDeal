import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/search_bar.dart';
import '../../data/models/dashboard_models.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../../orders/presentation/widgets/cart_icon_button.dart';
import 'package:cached_network_image/cached_network_image.dart';

final categoriesListProvider = FutureProvider.autoDispose
    .family<List<DashboardCategory>, String?>((ref, searchQuery) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.fetchCategories(searchQuery: searchQuery);
});

class CategoriesListScreen extends ConsumerStatefulWidget {
  const CategoriesListScreen({super.key});

  static const routePath = '/categories/all';
  static const routeName = 'categoriesList';

  @override
  ConsumerState<CategoriesListScreen> createState() =>
      _CategoriesListScreenState();
}

class _CategoriesListScreenState extends ConsumerState<CategoriesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  String _formatProductCount(int count) {
    if (count < 1000) {
      return '$count';
    } else if (count < 1000000) {
      final k = count / 1000;
      return k % 1 == 0 ? '${k.toInt()}K' : '${k.toStringAsFixed(1)}K';
    } else {
      final m = count / 1000000;
      return m % 1 == 0 ? '${m.toInt()}M' : '${m.toStringAsFixed(1)}M';
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _currentQuery = _searchController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(categoriesListProvider(
      _currentQuery.trim().isEmpty ? null : _currentQuery.trim(),
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.allCategories ?? 'All Categories'),
        actions: const [
          CartIconButton(),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppSearchBar(
              controller: _searchController,
              hintText: l10n?.searchCategories ?? 'Search categories...',
              onChanged: (value) {
                // Handled by listener
              },
            ),
          ),
          Expanded(
            child: categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _currentQuery.trim().isEmpty
                              ? (l10n?.noCategoriesFound ??
                                  'No categories found')
                              : (l10n?.noCategoriesMatchSearch ??
                                  'No categories match your search'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentQuery.trim().isEmpty
                              ? (l10n?.categoriesWillAppearHere ??
                                  'Categories will appear here once they are added')
                              : (l10n?.tryDifferentSearchTerm ??
                                  'Try a different search term'),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  cacheExtent: 400,
                  addAutomaticKeepAlives: false,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () =>
                            context.push('/categories/${category.slug}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Category Image with Product Count Badge (center-crop for any size/aspect ratio)
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
                                            Theme.of(context)
                                                .colorScheme
                                                .primaryContainer,
                                            Theme.of(context)
                                                .colorScheme
                                                .secondaryContainer,
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
                                        errorWidget: (_, __, ___) => Center(
                                          child: Icon(
                                            Icons.category,
                                            size: 48,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    Center(
                                      child: Icon(
                                        Icons.category,
                                        size: 48,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                    ),
                                  // Product Count Badge
                                  if (category.productCount > 0)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        constraints: const BoxConstraints(
                                          minWidth: 28,
                                          minHeight: 28,
                                        ),
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            _formatProductCount(
                                                category.productCount),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Category Name
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                category.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
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
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
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
                      l10n?.errorLoadingCategories ??
                          'Error loading categories',
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
                          ref.invalidate(categoriesListProvider(null)),
                      child: Text(l10n?.retry ?? 'Retry'),
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
