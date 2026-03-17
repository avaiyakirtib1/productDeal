import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/networking/api_client.dart';

/// Provider for fetching wholesalers with pagination and search
final selectWholesalersProvider = StateNotifierProvider.autoDispose<
    SelectWholesalersController, AsyncValue<SelectWholesalersPage>>(
  (ref) => SelectWholesalersController(ref.watch(dioProvider)),
);

class SelectWholesalersPage {
  const SelectWholesalersPage({
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

class SelectWholesalersController
    extends StateNotifier<AsyncValue<SelectWholesalersPage>> {
  SelectWholesalersController(this._dio) : super(const AsyncValue.loading()) {
    loadWholesalers();
  }

  final dynamic _dio; // Dio instance
  int _currentPage = 1;
  String? _search;
  final int _pageSize = 25;

  Future<void> loadWholesalers({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      state = const AsyncValue.loading();
    }

    try {
      final query = <String, dynamic>{
        'page': _currentPage,
        'limit': _pageSize,
        'role': 'wholesaler',
        'status': 'approved',
        if (_search != null && _search!.isNotEmpty) 'search': _search,
      };

      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/users',
        queryParameters: query,
      );

      final data = response.data?['data'] as List<dynamic>? ?? [];
      final meta = response.data?['meta'] as Map<String, dynamic>? ?? {};

      final items = data.map((user) {
        final u = user as Map<String, dynamic>;
        return {
          'id': (u['_id'] ?? u['id']).toString(),
          'name': u['fullName'] ?? 'Unknown',
          'businessName': u['businessName'] ?? '',
          'email': u['email'] ?? '',
          'avatar': u['avatar'] ?? '',
        };
      }).toList();

      state = AsyncValue.data(
        SelectWholesalersPage(
          items: items,
          page: meta['page'] as int? ?? _currentPage,
          limit: meta['limit'] as int? ?? _pageSize,
          totalRows: meta['totalRows'] as int? ?? items.length,
        ),
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void setSearch(String? search) {
    _search = search?.trim().isEmpty == true ? null : search?.trim();
    loadWholesalers(refresh: true);
  }

  void nextPage() {
    final current = state.value;
    if (current != null &&
        _currentPage < (current.totalRows / _pageSize).ceil()) {
      _currentPage++;
      loadWholesalers();
    }
  }

  void previousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      loadWholesalers();
    }
  }

  void refresh() {
    loadWholesalers(refresh: true);
  }
}

class SelectWholesalerScreen extends ConsumerStatefulWidget {
  const SelectWholesalerScreen({
    super.key,
    this.selectedWholesalerId,
  });

  final String? selectedWholesalerId;

  static const routePath = '/select/wholesaler';
  static const routeName = 'selectWholesaler';

  @override
  ConsumerState<SelectWholesalerScreen> createState() =>
      _SelectWholesalerScreenState();
}

class _SelectWholesalerScreenState
    extends ConsumerState<SelectWholesalerScreen> {
  final _searchController = TextEditingController();
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedWholesalerId;
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
    final wholesalersAsync = ref.watch(selectWholesalersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.selectWholesaler ?? 'Select Wholesaler',
        ),
        actions: [
          if (_selectedId != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_selectedId);
              },
              child: Text(
                AppLocalizations.of(context)?.select ?? 'Select',
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
                hintText: AppLocalizations.of(context)
                        ?.searchByNameBusinessEmail ??
                    'Search by name, business name, email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(selectWholesalersProvider.notifier)
                              .setSearch(null);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (value) {
                ref.read(selectWholesalersProvider.notifier).setSearch(value);
              },
            ),
          ),
          // List
          Expanded(
            child: wholesalersAsync.when(
              data: (page) {
                final wholesalers = page.items;
                final totalRows = page.totalRows;
                final currentPage = page.page;
                final totalPages = (totalRows / page.limit).ceil();

                if (wholesalers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_off,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          (AppLocalizations.of(context)?.noWholesalersFound ??
                              'No wholesalers found'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchController.text.isNotEmpty
                              ? (AppLocalizations.of(context)
                                      ?.tryDifferentSearchTerm ??
                                  'Try a different search term')
                              : (AppLocalizations.of(context)
                                      ?.noApprovedWholesalersAvailable ??
                                  'No approved wholesalers available'),
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
                        itemCount: wholesalers.length,
                        itemBuilder: (context, index) {
                          final wholesaler = wholesalers[index];
                          final id = wholesaler['id'] as String;
                          final name = wholesaler['name'] as String;
                          final businessName =
                              wholesaler['businessName'] as String;
                          final email = wholesaler['email'] as String;
                          final avatar = wholesaler['avatar'] as String?;
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
                              leading: CircleAvatar(
                                backgroundImage:
                                    avatar != null && avatar.isNotEmpty
                                        ? CachedNetworkImageProvider(avatar)
                                        : null,
                                child: avatar == null || avatar.isEmpty
                                    ? Text(name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '?')
                                    : null,
                              ),
                              title: Text(
                                businessName.isNotEmpty ? businessName : name,
                                style: TextStyle(
                                  fontWeight:
                                      isSelected ? FontWeight.bold : null,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (businessName.isNotEmpty &&
                                      name != businessName)
                                    Text(name),
                                  Text(email),
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
                                          .read(selectWholesalersProvider
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
                                          .read(selectWholesalersProvider
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
                      (AppLocalizations.of(context)
                              ?.errorLoadingWholesalers ??
                          'Error loading wholesalers'),
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
                        ref.read(selectWholesalersProvider.notifier).refresh();
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
