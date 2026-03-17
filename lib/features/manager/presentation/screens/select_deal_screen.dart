import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../data/repositories/manager_repository.dart';

/// Provider for fetching deals with pagination and search
final selectDealsProvider = StateNotifierProvider.autoDispose<
    SelectDealsController, AsyncValue<SelectDealsPage>>(
  (ref) => SelectDealsController(ref.watch(managerRepositoryProvider)),
);

class SelectDealsPage {
  const SelectDealsPage({
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

class SelectDealsController extends StateNotifier<AsyncValue<SelectDealsPage>> {
  SelectDealsController(this._repo) : super(const AsyncValue.loading()) {
    loadDeals();
  }

  final ManagerRepository _repo;
  int _currentPage = 1;
  String? _status;
  final int _pageSize = 25;

  Future<void> loadDeals({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      state = const AsyncValue.loading();
    }

    try {
      final page = await _repo.fetchDeals(
        page: _currentPage,
        limit: _pageSize,
        status: _status,
      );

      final items = page.items.map((deal) {
        return {
          'id': deal.id,
          'title': deal.title,
          'dealPrice': deal.dealPrice,
          'status': deal.status,
          'progressPercent': deal.progressPercent,
          'targetQuantity': deal.targetQuantity,
          'receivedQuantity': deal.receivedQuantity,
        };
      }).toList();

      state = AsyncValue.data(
        SelectDealsPage(
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

  void setStatus(String? status) {
    _status = status;
    loadDeals(refresh: true);
  }

  void nextPage() {
    final current = state.value;
    if (current != null &&
        _currentPage < (current.totalRows / _pageSize).ceil()) {
      _currentPage++;
      loadDeals();
    }
  }

  void previousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      loadDeals();
    }
  }

  void refresh() {
    loadDeals(refresh: true);
  }
}

class SelectDealScreen extends ConsumerStatefulWidget {
  const SelectDealScreen({
    super.key,
    this.selectedDealId,
  });

  final String? selectedDealId;

  static const routePath = '/select/deal';
  static const routeName = 'selectDeal';

  @override
  ConsumerState<SelectDealScreen> createState() => _SelectDealScreenState();
}

class _SelectDealScreenState extends ConsumerState<SelectDealScreen> {
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedDealId;
  }

  @override
  Widget build(BuildContext context) {
    final dealsAsync = ref.watch(selectDealsProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.selectDeal ?? 'Select Deal'),
        actions: [
          if (_selectedId != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_selectedId);
              },
              child: Text(l10n?.select ?? 'Select'),
            ),
        ],
      ),
      body: Column(
        children: [
          // List
          Expanded(
            child: dealsAsync.when(
              data: (page) {
                final deals = page.items;
                final totalRows = page.totalRows;
                final currentPage = page.page;
                final totalPages = (totalRows / page.limit).ceil();

                if (deals.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_offer_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          l10n?.noDealsFound ?? 'No deals found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n?.noDealsAvailable ?? 'No deals available',
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
                        itemCount: deals.length,
                        itemBuilder: (context, index) {
                          final deal = deals[index];
                          final id = deal['id'] as String;
                          final title = deal['title'] as String;
                          final dealPrice = deal['dealPrice'] as double? ?? 0.0;
                          final status = deal['status'] as String?;
                          final isEnded = status == 'ended' || status == 'cancelled';
                          final progressPercent =
                              isEnded ? 100.0 : (deal['progressPercent'] as double? ?? 0.0);
                          final targetQuantity =
                              deal['targetQuantity'] as int? ?? 0;
                          final receivedQuantity =
                              deal['receivedQuantity'] as int? ?? 0;
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
                              leading: const Icon(Icons.local_offer, size: 40),
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
                                      'Deal Price: \$${dealPrice.toStringAsFixed(2)}'),
                                  if (status != null)
                                    Text(
                                      'Status: $status',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: status == 'live'
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                    ),
                                  if (targetQuantity > 0)
                                    Text(
                                      isEnded
                                          ? 'Deal Closed (100%)'
                                          : 'Progress: $receivedQuantity / $targetQuantity (${progressPercent.toStringAsFixed(1)}%)',
                                      style: const TextStyle(fontSize: 12),
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
                                          .read(selectDealsProvider.notifier)
                                          .previousPage();
                                    }
                                  : null,
                            ),
                            Text(
                              '${l10n?.pageOf ?? 'Page'} $currentPage ${l10n?.ofLabel ?? 'of'} $totalPages',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: currentPage < totalPages
                                  ? () {
                                      ref
                                          .read(selectDealsProvider.notifier)
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
                      l10n?.errorLoadingDeals ?? 'Error loading deals',
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
                        ref.read(selectDealsProvider.notifier).refresh();
                      },
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
