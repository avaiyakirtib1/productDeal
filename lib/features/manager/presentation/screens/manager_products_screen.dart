import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/data/models/auth_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/permissions/permissions.dart';
import '../../data/models/manager_models.dart';
import '../../data/repositories/manager_repository.dart';
import '../../data/providers/manager_data_providers.dart';
import '../../../wholesaler/presentation/widgets/create_product_modal.dart'
    show CreateProductModal;
import '../../../wholesaler/presentation/widgets/edit_product_modal.dart'
    show EditProductModal;

import '../widgets/csv_import_modal.dart' show CsvImportModal;
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/currency_controller.dart';
import '../../../../core/services/currency_service.dart';

final managerProductsProvider = StateNotifierProvider.autoDispose<
    ManagerProductsController, AsyncValue<ManagerProductsPage>>(
  (ref) => ManagerProductsController(ref.watch(managerRepositoryProvider)),
);

class ManagerProductsController
    extends StateNotifier<AsyncValue<ManagerProductsPage>> {
  ManagerProductsController(this._repo) : super(const AsyncValue.loading()) {
    loadProducts();
  }

  final ManagerRepository _repo;
  int _currentPage = 1;
  String? _search;
  String? _statusFilter;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _isLoadingMore = false;
      state = const AsyncValue.loading();
    }

    try {
      final page = await _repo.fetchProducts(
        page: _currentPage,
        search: _search,
        status: _statusFilter,
      );

      // Calculate if there are more pages
      final totalPages = (page.totalRows / page.limit).ceil();
      _hasMore = _currentPage < totalPages;

      if (refresh) {
        state = AsyncValue.data(page);
        _currentPage = 1;
      } else {
        final current = state.value;
        if (current != null) {
          state = AsyncValue.data(
            ManagerProductsPage(
              items: [...current.items, ...page.items],
              page: page.page,
              limit: page.limit,
              totalRows: page.totalRows,
            ),
          );
        } else {
          state = AsyncValue.data(page);
        }
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    _currentPage++;
    await loadProducts(refresh: false);
  }

  void setSearch(String? search) {
    _search = search;
    loadProducts(refresh: true);
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    loadProducts(refresh: true);
  }
}

class ManagerProductsScreen extends ConsumerStatefulWidget {
  const ManagerProductsScreen({super.key});

  static const routePath = '/manager/products';
  static const routeName = 'managerProducts';

  @override
  ConsumerState<ManagerProductsScreen> createState() =>
      _ManagerProductsScreenState();
}

class _ManagerProductsScreenState extends ConsumerState<ManagerProductsScreen> {
  late final ScrollController _scrollController;
  final _searchController = TextEditingController();
  String? _selectedStatusFilter;

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
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final controller = ref.read(managerProductsProvider.notifier);
    final state = ref.read(managerProductsProvider);

    // Load more when user scrolls to 80% of the list
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        controller.hasMore &&
        !controller.isLoadingMore &&
        state.hasValue) {
      controller.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(
        currencyControllerProvider); // Rebuild when display currency changes
    final authState = ref.watch(authControllerProvider);
    final productsAsync = ref.watch(managerProductsProvider);
    final l10n = AppLocalizations.of(context)!;

    return authState.when(
      data: (session) {
        final user = session?.user;
        final canAdd = user != null && Permissions.canAddProducts(user.role);
        final canEdit = user != null && Permissions.canEditProducts(user.role);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              Permissions.isAdminOrSubAdmin(user?.role ?? UserRole.kiosk)
                  ? l10n.allProducts
                  : l10n.myProducts,
            ),
            actions: [
              if (canAdd)
                IconButton(
                  icon: const Icon(Icons.upload_file),
                  tooltip: l10n.importCsv,
                  onPressed: () => _showCsvImportModal(context, ref),
                ),
            ],
          ),
          floatingActionButton: canAdd
              ? Padding(
                  padding: const EdgeInsets.only(
                    bottom: kBottomNavigationBarHeight,
                  ),
                  child: FloatingActionButton(
                    onPressed: () => _showCreateProductModal(context, ref),
                    tooltip: l10n.addProduct,
                    child: const Icon(Icons.add),
                  ))
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          body: Column(
            children: [
              // Search and Filter Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search Field
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n.searchProductsHint,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(managerProductsProvider.notifier)
                                      .setSearch(null);
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.3),
                      ),
                      onSubmitted: (value) {
                        ref.read(managerProductsProvider.notifier).setSearch(
                              value.trim().isEmpty ? null : value.trim(),
                            );
                      },
                      onChanged: (value) {
                        setState(() {}); // Update UI to show/hide clear button
                      },
                    ),
                    const SizedBox(height: 12),
                    // Status Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: l10n.all,
                            isSelected: _selectedStatusFilter == null,
                            onSelected: () {
                              setState(() {
                                _selectedStatusFilter = null;
                              });
                              ref
                                  .read(managerProductsProvider.notifier)
                                  .setStatusFilter(null);
                            },
                            color: Colors.greenAccent,
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: l10n.pending,
                            isSelected: _selectedStatusFilter == 'pending',
                            onSelected: () {
                              setState(() {
                                _selectedStatusFilter = 'pending';
                              });
                              ref
                                  .read(managerProductsProvider.notifier)
                                  .setStatusFilter('pending');
                            },
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: l10n.approved,
                            isSelected: _selectedStatusFilter == 'approved',
                            onSelected: () {
                              setState(() {
                                _selectedStatusFilter = 'approved';
                              });
                              ref
                                  .read(managerProductsProvider.notifier)
                                  .setStatusFilter('approved');
                            },
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: l10n.rejected,
                            isSelected: _selectedStatusFilter == 'rejected',
                            onSelected: () {
                              setState(() {
                                _selectedStatusFilter = 'rejected';
                              });
                              ref
                                  .read(managerProductsProvider.notifier)
                                  .setStatusFilter('rejected');
                            },
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Products List
              Expanded(
                child: productsAsync.when(
                  data: (page) {
                    if (page.items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noProductsYet,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            if (canAdd)
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _showCreateProductModal(context, ref),
                                icon: const Icon(Icons.add),
                                label: Text(l10n.addFirstProduct),
                              ),
                          ],
                        ),
                      );
                    }

                    final controller =
                        ref.read(managerProductsProvider.notifier);
                    final hasMore = controller.hasMore;
                    final isLoadingMore = controller.isLoadingMore;

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref
                            .read(managerProductsProvider.notifier)
                            .loadProducts(refresh: true);
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        cacheExtent: 400,
                        addAutomaticKeepAlives: false,
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                          bottom: 16 +
                              MediaQuery.of(context).padding.bottom +
                              140, // Extra space for FAB above bottom nav (65 nav + 56 FAB + 20 margin)
                        ),
                        itemCount: page.items.length +
                            (isLoadingMore ? 1 : 0) +
                            (!hasMore && page.items.isNotEmpty ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Show loading indicator at bottom when loading more
                          if (index == page.items.length && isLoadingMore) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    height: 32,
                                    width: 32,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 3),
                                  ),
                                  const SizedBox(height: 12),
                                  const SizedBox(height: 12),
                                  Text(
                                    l10n.loadingMoreProducts,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Show end of list indicator
                          if (index == page.items.length &&
                              !hasMore &&
                              page.items.isNotEmpty) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(
                                child: Text(
                                  l10n.reachedEnd,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ),
                            );
                          }

                          // Show product item
                          final product = page.items[index];
                          return RepaintBoundary(
                            child: _ManagerProductListItem(
                            product: product,
                            canEdit: canEdit,
                            user: user,
                            onEdit: () =>
                                _showEditProductModal(context, ref, product),
                            onStatusChange: () =>
                                _showStatusDialog(context, ref, product),
                            onDelete: () =>
                                _showDeleteDialog(context, ref, product),
                            onTap: () =>
                                context.push('/products/${product.id}'),
                          ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          '${AppLocalizations.of(context)?.error ?? 'Error'}: $error',
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref
                              .read(managerProductsProvider.notifier)
                              .loadProducts(refresh: true),
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
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            '${AppLocalizations.of(context)?.error ?? 'Error'}: $error',
          ),
        ),
      ),
    );
  }

  void _showCreateProductModal(BuildContext context, WidgetRef ref) {
    debugPrint('showCreateProductModal Invoked');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Consumer(
        builder: (context, ref, child) {
          final categoriesAsync = ref.watch(categoriesForProductProvider);
          final authState = ref.watch(authControllerProvider);
          final isAdmin = authState.maybeWhen(
            data: (session) => Permissions.isAdminOrSubAdmin(
                session?.user.role ?? UserRole.kiosk),
            orElse: () => false,
          );

          return categoriesAsync.when(
            data: (categories) {
              debugPrint('categoriesForProductModal categories: $categories');

              if (isAdmin) {
                final wholesalersAsync =
                    ref.watch(wholesalersForProductProvider);
                return wholesalersAsync.when(
                  data: (wholesalers) {
                    debugPrint(
                        'categoriesForProductModal wholesalers: $wholesalers');
                    return CreateProductModal(
                      onSave: (data) async {
                        try {
                          await ref
                              .read(managerRepositoryProvider)
                              .createProduct(data.toJson());
                          if (modalContext.mounted) {
                            SchedulerBinding.instance.addPostFrameCallback((_) {
                              if (modalContext.mounted &&
                                  Navigator.canPop(modalContext)) {
                                Navigator.pop(modalContext);
                              }
                            });
                            ref
                                .read(managerProductsProvider.notifier)
                                .loadProducts(refresh: true);
                            if (modalContext.mounted) {
                              ScaffoldMessenger.of(modalContext).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        AppLocalizations.of(modalContext)!
                                            .productCreatedSuccessfully)),
                              );
                            }
                          }
                        } catch (e) {
                          if (modalContext.mounted) {
                            ScaffoldMessenger.of(modalContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${AppLocalizations.of(modalContext)?.error ?? 'Error'}: $e',
                                ),
                              ),
                            );
                          }
                          rethrow;
                        }
                      },
                      categories: categories,
                      wholesalers: wholesalers,
                      currentUserId: authState.maybeWhen(
                        data: (session) => session?.user.id,
                        orElse: () => null,
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stack) {
                    debugPrint('wholesalersForProductProvider error: $error');
                    return CreateProductModal(
                      onSave: (data) async {
                        try {
                          await ref
                              .read(managerRepositoryProvider)
                              .createProduct(data.toJson());
                          if (modalContext.mounted) {
                            SchedulerBinding.instance.addPostFrameCallback((_) {
                              if (modalContext.mounted &&
                                  Navigator.canPop(modalContext)) {
                                Navigator.pop(modalContext);
                              }
                            });
                            ref
                                .read(managerProductsProvider.notifier)
                                .loadProducts(refresh: true);
                            if (modalContext.mounted) {
                              ScaffoldMessenger.of(modalContext).showSnackBar(
                                SnackBar(
                                    content: Text(
                                      AppLocalizations.of(modalContext)
                                              ?.productCreatedSuccessfully ??
                                          'Product created successfully',
                                    ),
                                  ),
                              );
                            }
                          }
                        } catch (e) {
                          if (modalContext.mounted) {
                            ScaffoldMessenger.of(modalContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${AppLocalizations.of(modalContext)?.error ?? 'Error'}: $e',
                                ),
                              ),
                            );
                          }
                          rethrow;
                        }
                      },
                      categories: categories,
                      wholesalers: const [],
                      currentUserId: authState.maybeWhen(
                        data: (session) => session?.user.id,
                        orElse: () => null,
                      ),
                    );
                  },
                );
              }

              return CreateProductModal(
                onSave: (data) async {
                  try {
                    await ref
                        .read(managerRepositoryProvider)
                        .createProduct(data.toJson());
                    if (modalContext.mounted) {
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        if (modalContext.mounted &&
                            Navigator.canPop(modalContext)) {
                          Navigator.pop(modalContext);
                        }
                      });
                      ref
                          .read(managerProductsProvider.notifier)
                          .loadProducts(refresh: true);
                      if (modalContext.mounted) {
                        ScaffoldMessenger.of(modalContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(modalContext)
                                      ?.productCreatedSuccessfully ??
                                  'Product created successfully',
                            ),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (modalContext.mounted) {
                      ScaffoldMessenger.of(modalContext).showSnackBar(
                        SnackBar(
                        content: Text(
                          '${AppLocalizations.of(modalContext)?.error ?? 'Error'}: $e',
                        ),
                      ),
                      );
                    }
                    rethrow;
                  }
                },
                categories: categories,
                wholesalers: const [],
                currentUserId: authState.maybeWhen(
                  data: (session) => session?.user.id,
                  orElse: () => null,
                ),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) {
              debugPrint('categoriesForProductProvider error: $error');
              return CreateProductModal(
                onSave: (data) async {
                  try {
                    await ref
                        .read(managerRepositoryProvider)
                        .createProduct(data.toJson());
                    if (modalContext.mounted) {
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        if (modalContext.mounted &&
                            Navigator.canPop(modalContext)) {
                          Navigator.pop(modalContext);
                        }
                      });
                      ref
                          .read(managerProductsProvider.notifier)
                          .loadProducts(refresh: true);
                      if (modalContext.mounted) {
                        ScaffoldMessenger.of(modalContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(modalContext)
                                      ?.productCreatedSuccessfully ??
                                  'Product created successfully',
                            ),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (modalContext.mounted) {
                      ScaffoldMessenger.of(modalContext).showSnackBar(
                        SnackBar(
                        content: Text(
                          '${AppLocalizations.of(modalContext)?.error ?? 'Error'}: $e',
                        ),
                      ),
                      );
                    }
                    rethrow;
                  }
                },
                categories: const [],
                wholesalers: const [],
                currentUserId: authState.maybeWhen(
                  data: (session) => session?.user.id,
                  orElse: () => null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEditProductModal(
      BuildContext context, WidgetRef ref, ManagerProduct product) {
    // Invalidate to ensure fresh data
    ref.invalidate(managerProductDetailProvider(product.id));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _EditProductModalContent(
        product: product,
        modalContext: modalContext,
      ),
    );
  }

  void _showStatusDialog(
      BuildContext context, WidgetRef ref, ManagerProduct product) {
    bool isUpdating = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing during update
      builder: (dialogContext) => StatefulBuilder(builder: (context, setState) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.changeProductStatus),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isUpdating)
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text(l10n.updatingStatus),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              // Pending Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isUpdating || product.status == 'pending'
                      ? null
                      : () async {
                          setState(() => isUpdating = true);
                          try {
                            await ref
                                .read(managerRepositoryProvider)
                                .updateProductStatus(product.id, 'pending');
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                              ref
                                  .read(managerProductsProvider.notifier)
                                  .loadProducts(refresh: true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                      l10n.statusUpdatedToPending,
                                    ),
                                  ),
                              );
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setState(() => isUpdating = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${l10n.error}: $e',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  icon: const Icon(Icons.pending, color: Colors.orange),
                  label: Text(l10n.pending),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Approved Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isUpdating || product.status == 'approved'
                      ? null
                      : () async {
                          setState(() => isUpdating = true);
                          try {
                            await ref
                                .read(managerRepositoryProvider)
                                .updateProductStatus(product.id, 'approved');
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                              ref
                                  .read(managerProductsProvider.notifier)
                                  .loadProducts(refresh: true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                      l10n.statusUpdatedToApproved,
                                    ),
                                  ),
                              );
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setState(() => isUpdating = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${l10n.error}: $e',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  icon: const Icon(Icons.check_circle),
                  label: Text(l10n.approved),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Rejected Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isUpdating || product.status == 'rejected'
                      ? null
                      : () async {
                          setState(() => isUpdating = true);
                          try {
                            await ref
                                .read(managerRepositoryProvider)
                                .updateProductStatus(product.id, 'rejected');
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                              ref
                                  .read(managerProductsProvider.notifier)
                                  .loadProducts(refresh: true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                      l10n.statusUpdatedToRejected,
                                    ),
                                  ),
                              );
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setState(() => isUpdating = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${l10n.error}: $e',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: Text(l10n.rejected),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isUpdating ? null : () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
          ],
        );
      }),
    );
  }

  void _showCsvImportModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Consumer(
        builder: (context, ref, child) {
          final l10n = AppLocalizations.of(context)!;
          final authState = ref.watch(authControllerProvider);

          return authState.when(
            data: (session) {
              return CsvImportModal(
                currentUserId: session?.user.id ?? "",
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) {
              debugPrint('authControllerProvider error: $error');
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(l10n.somethingWentWrong),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, WidgetRef ref, ManagerProduct product) {
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing during delete
      builder: (dialogContext) => StatefulBuilder(builder: (context, setState) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.deleteProduct),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isDeleting)
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text(l10n.deletingProduct),
                    ],
                  ),
                ),
              Text(l10n.deleteProductConfirmGeneric),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: isDeleting
                  ? null
                  : () async {
                      // Show loading immediately
                      setState(() => isDeleting = true);

                      try {
                        await ref
                            .read(managerRepositoryProvider)
                            .deleteProduct(product.id);

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                          // Refresh products list asynchronously
                          ref
                              .read(managerProductsProvider.notifier)
                              .loadProducts(refresh: true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(l10n.productDeletedSuccessfully)),
                          );
                        }
                      } catch (e) {
                        if (dialogContext.mounted) {
                          setState(() => isDeleting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${l10n.error}: $e')),
                          );
                        }
                      }
                    },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.delete),
            ),
          ],
        );
      }),
    );
  }
}

// Separate widget to manage lifecycle properly and prevent infinite rebuilds
class _EditProductModalContent extends ConsumerStatefulWidget {
  const _EditProductModalContent({
    required this.product,
    required this.modalContext,
  });

  final ManagerProduct product;
  final BuildContext modalContext;

  @override
  ConsumerState<_EditProductModalContent> createState() =>
      _EditProductModalContentState();
}

class _EditProductModalContentState
    extends ConsumerState<_EditProductModalContent> {
  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesForProductProvider);
    final authState = ref.watch(authControllerProvider);
    final isAdmin = authState.maybeWhen(
      data: (session) =>
          Permissions.isAdminOrSubAdmin(session?.user.role ?? UserRole.kiosk),
      orElse: () => false,
    );

    // Use the existing family provider - this prevents infinite rebuilds
    final productDetailAsync = ref.watch(
      managerProductDetailProvider(widget.product.id),
    );

    return categoriesAsync.when(
      data: (categories) {
        return productDetailAsync.when(
          data: (productDetail) {
            // Handle category - support categoryIds (multi) and categoryId/category (single)
            Map<String, dynamic>? category;
            String? categoryId;
            List<String>? categoryIds;

            final ids = productDetail['categoryIds'];
            if (ids is List && ids.isNotEmpty) {
              categoryIds = ids
                  .map((e) => e?.toString() ?? '')
                  .where((s) => s.isNotEmpty)
                  .toList();
              categoryId = categoryIds.isNotEmpty ? categoryIds.first : null;
            }
            if (categoryId == null) {
              final categoryValue = productDetail['category'];
              if (categoryValue is Map<String, dynamic>) {
                category = categoryValue;
                categoryId =
                    category['_id']?.toString() ?? category['_id'].toString();
              } else {
                categoryId = productDetail['categoryId']?.toString();
              }
            }

            // Handle variants - can be List or null
            final variantsRaw = productDetail['variants'];
            final variants = variantsRaw is List ? variantsRaw : [];

            return EditProductModal(
              product: {
                'id': productDetail['_id']?.toString() ??
                    productDetail['id']?.toString() ??
                    widget.product.id,
                'title': productDetail['title']?.toString() ??
                    productDetail['name']?.toString() ??
                    widget.product.title,
                'description': productDetail['description']?.toString() ?? '',
                'price': (productDetail['price'] as num?)?.toDouble() ??
                    (productDetail['listPrice'] as num?)?.toDouble() ??
                    widget.product.price,
                'basePrice': (productDetail['basePrice'] as num?)?.toDouble(),
                'stock': (productDetail['stock'] as num?)?.toInt() ??
                    widget.product.stock,
                'sku': productDetail['sku']?.toString() ?? '',
                'costPrice': (productDetail['costPrice'] as num?)?.toDouble(),
                'baseCostPrice':
                    (productDetail['baseCostPrice'] as num?)?.toDouble(),
                'status': productDetail['status']?.toString() ??
                    widget.product.status,
                'unit': productDetail['unit']?.toString() ?? 'unit',
                'imageUrl': productDetail['imageUrl']?.toString() ??
                    widget.product.imageUrl,
                'images': (productDetail['images'] as List<dynamic>?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    (productDetail['imageUrl'] != null
                        ? [productDetail['imageUrl'].toString()]
                        : []),
                'isFeatured': productDetail['isFeatured'] == true,
                'categoryId': categoryId,
                'categoryIds': categoryIds,
                'variants': variants.map((v) {
                  final variant = v as Map<String, dynamic>;
                  return {
                    'id':
                        variant['_id']?.toString() ?? variant['id']?.toString(),
                    'sku': variant['sku']?.toString() ?? '',
                    'attributes':
                        variant['attributes'] as Map<String, dynamic>? ?? {},
                    'price': (variant['price'] as num?)?.toDouble() ?? 0.0,
                    'costPrice': (variant['costPrice'] as num?)?.toDouble(),
                    'stock': (variant['stock'] as num?)?.toInt() ?? 0,
                    'reservedStock':
                        (variant['reservedStock'] as num?)?.toInt() ?? 0,
                    'images': (variant['images'] as List<dynamic>?)
                            ?.map((e) => e.toString())
                            .toList() ??
                        [],
                    'isDefault': variant['isDefault'] == true,
                    'isActive': variant['isActive'] != false,
                  };
                }).toList(),
              },
              onSave: (data) async {
                await ref
                    .read(managerRepositoryProvider)
                    .updateProduct(widget.product.id, data.toJson());
                ref
                    .read(managerProductsProvider.notifier)
                    .loadProducts(refresh: true);
                if (widget.modalContext.mounted) {
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    if (widget.modalContext.mounted &&
                        Navigator.canPop(widget.modalContext)) {
                      Navigator.pop(widget.modalContext);
                    }
                  });
                  ScaffoldMessenger.of(widget.modalContext).showSnackBar(
                    SnackBar(
                        content: Text(AppLocalizations.of(widget.modalContext)!
                            .productUpdatedSuccessfully)),
                  );
                }
              },
              categories: categories,
              canChangeStatus: isAdmin,
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) {
            debugPrint('fetchProductDetail error: $error');
            return EditProductModal(
              product: {
                'id': widget.product.id,
                'title': widget.product.title,
                'description': '',
                'price': widget.product.price,
                'stock': widget.product.stock,
                'sku': '',
                'costPrice': null,
                'status': widget.product.status,
                'unit': 'unit',
                'imageUrl': widget.product.imageUrl,
                'images': widget.product.imageUrl != null
                    ? [widget.product.imageUrl!]
                    : [],
                'isFeatured': false,
                'categoryId': null,
                'variants': [],
              },
              onSave: (data) async {
                await ref
                    .read(managerRepositoryProvider)
                    .updateProduct(widget.product.id, data.toJson());
                if (widget.modalContext.mounted) {
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    if (widget.modalContext.mounted &&
                        Navigator.canPop(widget.modalContext)) {
                      Navigator.pop(widget.modalContext);
                    }
                  });
                  ref
                      .read(managerProductsProvider.notifier)
                      .loadProducts(refresh: true);
                  if (widget.modalContext.mounted) {
                    ScaffoldMessenger.of(widget.modalContext).showSnackBar(
                      SnackBar(
                          content: Text(
                              AppLocalizations.of(widget.modalContext)!
                                  .productUpdatedSuccessfully)),
                    );
                  }
                }
              },
              categories: categories,
              canChangeStatus: isAdmin,
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) {
        debugPrint('categoriesForProductProvider error: $error');
        return productDetailAsync.when(
          data: (productDetail) {
            // Handle category - support categoryIds (multi) and categoryId/category (single)
            Map<String, dynamic>? category;
            String? categoryId;
            List<String>? categoryIds;

            final ids = productDetail['categoryIds'];
            if (ids is List && ids.isNotEmpty) {
              categoryIds = ids
                  .map((e) => e?.toString() ?? '')
                  .where((s) => s.isNotEmpty)
                  .toList();
              categoryId = categoryIds.isNotEmpty ? categoryIds.first : null;
            }
            if (categoryId == null) {
              final categoryValue = productDetail['category'];
              if (categoryValue is Map<String, dynamic>) {
                category = categoryValue;
                categoryId =
                    category['_id']?.toString() ?? category['_id'].toString();
              } else {
                categoryId = productDetail['categoryId']?.toString();
              }
            }

            // Handle variants - can be List or null
            final variantsRaw = productDetail['variants'];
            final variants = variantsRaw is List ? variantsRaw : [];

            return EditProductModal(
              product: {
                'id': productDetail['_id']?.toString() ??
                    productDetail['id']?.toString() ??
                    widget.product.id,
                'title': productDetail['title']?.toString() ??
                    productDetail['name']?.toString() ??
                    widget.product.title,
                'description': productDetail['description']?.toString() ?? '',
                'price': (productDetail['price'] as num?)?.toDouble() ??
                    (productDetail['listPrice'] as num?)?.toDouble() ??
                    widget.product.price,
                'basePrice': (productDetail['basePrice'] as num?)?.toDouble(),
                'stock': (productDetail['stock'] as num?)?.toInt() ??
                    widget.product.stock,
                'sku': productDetail['sku']?.toString() ?? '',
                'costPrice': (productDetail['costPrice'] as num?)?.toDouble(),
                'baseCostPrice':
                    (productDetail['baseCostPrice'] as num?)?.toDouble(),
                'status': productDetail['status']?.toString() ??
                    widget.product.status,
                'unit': productDetail['unit']?.toString() ?? 'unit',
                'imageUrl': productDetail['imageUrl']?.toString() ??
                    widget.product.imageUrl,
                'images': (productDetail['images'] as List<dynamic>?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    (productDetail['imageUrl'] != null
                        ? [productDetail['imageUrl'].toString()]
                        : []),
                'isFeatured': productDetail['isFeatured'] == true,
                'categoryId': categoryId,
                'categoryIds': categoryIds,
                'variants': variants.map((v) {
                  final variant = v as Map<String, dynamic>;
                  return {
                    'id':
                        variant['_id']?.toString() ?? variant['id']?.toString(),
                    'sku': variant['sku']?.toString() ?? '',
                    'attributes':
                        variant['attributes'] as Map<String, dynamic>? ?? {},
                    'price': (variant['price'] as num?)?.toDouble() ?? 0.0,
                    'costPrice': (variant['costPrice'] as num?)?.toDouble(),
                    'stock': (variant['stock'] as num?)?.toInt() ?? 0,
                    'reservedStock':
                        (variant['reservedStock'] as num?)?.toInt() ?? 0,
                    'images': (variant['images'] as List<dynamic>?)
                            ?.map((e) => e.toString())
                            .toList() ??
                        [],
                    'isDefault': variant['isDefault'] == true,
                    'isActive': variant['isActive'] != false,
                  };
                }).toList(),
              },
              onSave: (data) async {
                await ref
                    .read(managerRepositoryProvider)
                    .updateProduct(widget.product.id, data.toJson());
                if (widget.modalContext.mounted) {
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    if (widget.modalContext.mounted &&
                        Navigator.canPop(widget.modalContext)) {
                      Navigator.pop(widget.modalContext);
                    }
                  });
                  ref
                      .read(managerProductsProvider.notifier)
                      .loadProducts(refresh: true);
                  if (widget.modalContext.mounted) {
                    ScaffoldMessenger.of(widget.modalContext).showSnackBar(
                      SnackBar(
                          content: Text(
                            AppLocalizations.of(widget.modalContext)
                                    ?.productUpdatedSuccessfully ??
                                'Product updated successfully',
                          ),
                        ),
                    );
                  }
                }
              },
              categories: const [],
              canChangeStatus: isAdmin,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => EditProductModal(
            product: {
              'id': widget.product.id,
              'title': widget.product.title,
              'description': '',
              'price': widget.product.price,
              'stock': widget.product.stock,
              'sku': '',
              'costPrice': null,
              'status': widget.product.status,
              'unit': 'unit',
              'imageUrl': widget.product.imageUrl,
              'images': widget.product.imageUrl != null
                  ? [widget.product.imageUrl!]
                  : [],
              'isFeatured': false,
              'categoryId': null,
              'variants': [],
            },
            onSave: (data) async {
              await ref
                  .read(managerRepositoryProvider)
                  .updateProduct(widget.product.id, data.toJson());
              if (widget.modalContext.mounted) {
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  if (widget.modalContext.mounted &&
                      Navigator.canPop(widget.modalContext)) {
                    Navigator.pop(widget.modalContext);
                  }
                });
                ref
                    .read(managerProductsProvider.notifier)
                    .loadProducts(refresh: true);
                if (widget.modalContext.mounted) {
                  final l10nModal =
                      AppLocalizations.of(widget.modalContext)!;
                  ScaffoldMessenger.of(widget.modalContext).showSnackBar(
                    SnackBar(
                        content: Text(l10nModal.productUpdatedSuccessfully)),
                  );
                }
              }
            },
            categories: const [],
            canChangeStatus: isAdmin,
          ),
        );
      },
    );
  }
}

// Filter Chip Widget
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: color?.withValues(alpha: 0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color:
            isSelected ? color ?? Theme.of(context).colorScheme.primary : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected
            ? (color ?? Theme.of(context).colorScheme.primary)
            : Colors.grey.shade300,
        width: isSelected ? 2 : 1,
      ),
    );
  }
}

// Optimized product list item widget with image caching
class _ManagerProductListItem extends StatelessWidget {
  const _ManagerProductListItem({
    required this.product,
    required this.canEdit,
    required this.user,
    required this.onEdit,
    required this.onStatusChange,
    required this.onDelete,
    required this.onTap,
  });

  final ManagerProduct product;
  final bool canEdit;
  final UserModel? user;
  final VoidCallback onEdit;
  final VoidCallback onStatusChange;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: product.imageUrl != null
            ? CircleAvatar(
                radius: 28,
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 56,
                      height: 56,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
            : CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
        title: Text(
          product.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${context.formatPriceEurOnly(product.price)} '
              '(${context.formatPriceUsdFromEur(product.price)}) • Stock: ${product.stock}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${l10n.status}: ',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                ),
                const SizedBox(width: 4),
                Text(
                  product.status.toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: canEdit
            ? PopupMenuButton<String>(
                itemBuilder: (context) {
                  final canChangeStatus = Permissions.isAdminOrSubAdmin(
                      user?.role ?? UserRole.kiosk);
                  return [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text(l10n.edit),
                        ],
                      ),
                    ),
                    if (canChangeStatus)
                      PopupMenuItem(
                        value: 'status',
                        child: Row(
                          children: [
                            Icon(Icons.swap_vert, size: 20),
                            SizedBox(width: 8),
                            Text(l10n.changeStatus),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text(l10n.delete,
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ];
                },
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'status') {
                    onStatusChange();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
