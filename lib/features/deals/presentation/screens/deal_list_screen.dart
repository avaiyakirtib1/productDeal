import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/currency_controller.dart';
import '../../../../core/services/currency_service.dart';
import '../../data/deal_live_data_service.dart';
import '../../data/models/deal_models.dart';
import '../../data/repositories/deal_repository.dart';
import '../../../orders/presentation/screens/my_orders_screen.dart';
import '../../../orders/presentation/widgets/cart_icon_button.dart';

final dealListControllerProvider = StateNotifierProvider.autoDispose
    .family<DealListController, AsyncValue<DealListPage>, DealListParams>(
  (ref, params) =>
      DealListController(ref.watch(dealRepositoryProvider), params),
);

class DealListParams {
  const DealListParams({
    this.storyId,
    this.wholesalerId,
    this.productId,
    this.title,
  });

  final String? storyId;
  final String? wholesalerId;
  final String? productId;
  final String? title;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DealListParams &&
        other.storyId == storyId &&
        other.wholesalerId == wholesalerId &&
        other.productId == productId &&
        other.title == title;
  }

  @override
  int get hashCode {
    return Object.hash(storyId, wholesalerId, productId, title);
  }
}

class DealListController extends StateNotifier<AsyncValue<DealListPage>> {
  DealListController(this._repo, this.params)
      : super(const AsyncValue.loading()) {
    loadDeals();
  }

  final DealRepository _repo;
  final DealListParams params;
  int _currentPage = 1;
  DealStatus? _statusFilter;
  DealType? _typeFilter;
  bool _hasMore = true;
  bool _isLoading = false;

  Future<void> loadDeals({bool refresh = false}) async {
    // Prevent concurrent requests
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    if (!_hasMore && !refresh) return;

    _isLoading = true;
    try {
      // Only set loading state if we don't have data yet (initial load)
      if (state.value == null) {
        state = const AsyncValue.loading();
      }

      final page = await _repo.fetchDeals(
        page: _currentPage,
        limit: 20,
        status: _statusFilter,
        type: _typeFilter,
        storyId: params.storyId,
        wholesalerId: params.wholesalerId,
        productId: params.productId,
      );

      // Check if controller is still mounted before updating state
      if (mounted) {
        if (refresh) {
          state = AsyncValue.data(page);
        } else {
          final current = state.value;
          if (current != null) {
            state = AsyncValue.data(
              DealListPage(
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

        final snapshot = state.requireValue;
        _hasMore = page.limit > 0 &&
            page.items.length == page.limit &&
            snapshot.items.length < snapshot.totalRows;
        if (_hasMore) {
          _currentPage++;
        }
      }
    } catch (e, stack) {
      if (mounted) {
        state = AsyncValue.error(e, stack);
      }
    } finally {
      _isLoading = false;
    }
  }

  void setStatusFilter(DealStatus? status) {
    _statusFilter = status;
    loadDeals(refresh: true);
  }

  void setTypeFilter(DealType? type) {
    _typeFilter = type;
    loadDeals(refresh: true);
  }
}

class DealListScreen extends ConsumerStatefulWidget {
  const DealListScreen({
    super.key,
    this.storyId,
    this.wholesalerId,
    this.productId,
    this.title,
  });

  static const routePath = '/deals';
  static const routeName = 'dealList';

  final String? storyId;
  final String? wholesalerId;
  final String? productId;
  final String? title;

  @override
  ConsumerState<DealListScreen> createState() => _DealListScreenState();
}

class _DealListScreenState extends ConsumerState<DealListScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final params = DealListParams(
        storyId: widget.storyId,
        wholesalerId: widget.wholesalerId,
        productId: widget.productId,
        title: widget.title,
      );
      ref.read(dealLiveDataProvider).registerList(
            DealListSubscriptionParams(
              storyId: widget.storyId,
              wholesalerId: widget.wholesalerId,
              productId: widget.productId,
            ),
            () => ref.invalidate(dealListControllerProvider(params)),
          );
    });
  }

  @override
  void dispose() {
    ref.read(dealLiveDataProvider).unregisterList();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final params = DealListParams(
      storyId: widget.storyId,
      wholesalerId: widget.wholesalerId,
      productId: widget.productId,
      title: widget.title,
    );
    final state = ref.read(dealListControllerProvider(params));
    final controller = ref.read(dealListControllerProvider(params).notifier);

    if (!_scrollController.hasClients) return;

    final hasMore =
        state.hasValue && state.value!.items.length < state.value!.totalRows;

    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        hasMore &&
        !_isLoadingMore &&
        !state.isLoading) {
      _isLoadingMore = true;
      controller.loadDeals().then((_) {
        if (mounted) {
          _isLoadingMore = false;
        }
      }).catchError((_) {
        if (mounted) {
          _isLoadingMore = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(
        currencyControllerProvider); // Rebuild when display currency changes
    final params = DealListParams(
      storyId: widget.storyId,
      wholesalerId: widget.wholesalerId,
      productId: widget.productId,
      title: widget.title,
    );
    final state = ref.watch(dealListControllerProvider(params));

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? (l10n?.activeDeals ?? 'Active Deals')),
        actions: [
          const CartIconButton(),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: l10n?.myOrders ?? 'My orders',
            onPressed: () => context.push(MyOrdersScreen.routePath),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: l10n?.filter ?? 'Filter',
            onPressed: () => _showFilterDialog(context, ref, params),
          ),
        ],
      ),
      body: state.when(
        data: (page) {
          if (page.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n?.noDealsAvailable ?? 'No deals available',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.checkBackLaterForNewDeals ??
                        'Check back later for new deals',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          final controller =
              ref.read(dealListControllerProvider(params).notifier);
          final hasMore = page.items.length < page.totalRows;

          // Setup scroll listener for load more
          _scrollController.removeListener(_onScroll);
          _scrollController.addListener(_onScroll);

          return RefreshIndicator(
            onRefresh: () async {
              _isLoadingMore = false;
              await controller.loadDeals(refresh: true);
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount:
                  page.items.length + (hasMore && state.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                // Show loading indicator at the end if loading more
                if (index == page.items.length && hasMore && state.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (index < page.items.length) {
                  final deal = page.items[index];
                  return _DealCard(deal: deal);
                }

                return const SizedBox.shrink();
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('${l10n?.error ?? 'Error'}: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref
                        .read(dealListControllerProvider(params).notifier)
                        .loadDeals(refresh: true),
                    child: Text(l10n?.retry ?? 'Retry'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showFilterDialog(
      BuildContext context, WidgetRef ref, DealListParams params) {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        onStatusChanged: (status) {
          ref
              .read(dealListControllerProvider(params).notifier)
              .setStatusFilter(status);
          Navigator.of(context).pop();
        },
        onTypeChanged: (type) {
          ref
              .read(dealListControllerProvider(params).notifier)
              .setTypeFilter(type);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  const _DealCard({required this.deal});

  final Deal deal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = deal.isEnded ? 100.0 : deal.progressPercent;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push('/deals/${deal.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      deal.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(deal.type.name.toUpperCase()),
                    avatar: Icon(_iconForDealType(deal.type), size: 16),
                  ),
                ],
              ),
              if (deal.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  deal.description!,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            final perUnitLabel = l10n?.perUnit ?? '/unit';
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${context.formatPriceEurOnly(deal.dealPrice)}$perUnitLabel',
                                  style: theme.textTheme.titleMedium?.copyWith(
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
                            );
                          },
                        ),
                        Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            return Text(
                              '${l10n?.min ?? 'Min:'} ${deal.minOrderQuantity} - ${l10n?.max ?? 'Max:'} ${deal.targetQuantity}',
                              style: theme.textTheme.bodySmall,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (deal.product != null) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (deal.product!.price > deal.dealPrice) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                context.formatPriceEurOnly(deal.product!.price),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '(${context.formatPriceUsdFromEur(deal.product!.price)})',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          Builder(
                            builder: (context) {
                              final l10n = AppLocalizations.of(context);
                              return Text(
                                '${((1 - deal.dealPrice / deal.product!.price) * 100).toStringAsFixed(0)}% ${l10n?.off ?? 'OFF'}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ],
                        if (deal.product!.hasVariant) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.style,
                                  size: 12,
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                                const SizedBox(width: 2),
                                Builder(
                                  builder: (context) {
                                    final l10n = AppLocalizations.of(context);
                                    return Text(
                                      l10n?.variant ?? 'Variant',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: theme
                                            .colorScheme.onSecondaryContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n?.progress ?? 'Progress',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            '${progress.toStringAsFixed(1)}%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 6,
                  ),
                  const SizedBox(height: 4),
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Text(
                        deal.isEnded
                            ? (l10n?.dealClosed ?? 'Deal Closed')
                            : '${deal.receivedQuantity}/${deal.targetQuantity} ${l10n?.ordered ?? 'ordered'} • ${deal.orderCount} ${deal.orderCount == 1 ? (l10n?.order ?? 'order') : (l10n?.orders ?? 'orders')}',
                        style: theme.textTheme.bodySmall,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return Text(
                            deal.hasLessThanOneHour
                                ? (l10n?.endingSoon ?? 'Ending soon!')
                                : '${l10n?.ends ?? 'Ends'} ${DateFormat('MMM d').format(deal.endAt.toLocal())}',
                            style: theme.textTheme.bodySmall,
                          );
                        },
                      ),
                    ],
                  ),
                  if (deal.wholesaler != null)
                    Row(
                      children: [
                        Icon(
                          Icons.store,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          deal.wholesaler!.businessName ??
                              deal.wholesaler!.fullName,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

class _FilterDialog extends StatelessWidget {
  const _FilterDialog({
    required this.onStatusChanged,
    required this.onTypeChanged,
  });

  final ValueChanged<DealStatus?> onStatusChanged;
  final ValueChanged<DealType?> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n?.filterDeals ?? 'Filter Deals'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.status ?? 'Status',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: Text(l10n?.all ?? 'All'),
                onSelected: (_) => onStatusChanged(null),
              ),
              ...DealStatus.values.map(
                (status) => FilterChip(
                  label: Text(status.name.toUpperCase()),
                  onSelected: (_) => onStatusChanged(status),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n?.type ?? 'Type',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: Text(l10n?.all ?? 'All'),
                onSelected: (_) => onTypeChanged(null),
              ),
              ...DealType.values.map(
                (type) => FilterChip(
                  label: Text(type.name.toUpperCase()),
                  onSelected: (_) => onTypeChanged(type),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n?.close ?? 'Close'),
        ),
      ],
    );
  }
}
