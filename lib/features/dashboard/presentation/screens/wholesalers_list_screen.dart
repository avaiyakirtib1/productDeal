import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/location/location_service.dart';
import '../../data/models/dashboard_models.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../../orders/presentation/widgets/cart_icon_button.dart';
import '../../../../shared/widgets/network_avatar.dart';

final wholesalersListProvider = FutureProvider.autoDispose
    .family<WholesalerDirectoryPage, ({int page, double? lat, double? lng})>(
  (ref, params) async {
    final repo = ref.watch(dashboardRepositoryProvider);
    return repo.fetchWholesalers(
      page: params.page,
      limit: 24,
      latitude: params.lat,
      longitude: params.lng,
    );
  },
);

class WholesalersListScreen extends ConsumerStatefulWidget {
  const WholesalersListScreen({super.key});

  static const routePath = '/wholesalers/all';
  static const routeName = 'wholesalersList';

  @override
  ConsumerState<WholesalersListScreen> createState() =>
      _WholesalersListScreenState();
}

class _WholesalersListScreenState extends ConsumerState<WholesalersListScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final List<SpotlightWholesaler> _allWholesalers = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final location = ref.read(locationControllerProvider).valueOrNull;
    final repo = ref.read(dashboardRepositoryProvider);

    try {
      final page = await repo.fetchWholesalers(
        page: _currentPage + 1,
        limit: 24,
        latitude: location?.latitude,
        longitude: location?.longitude,
      );

      if (mounted) {
        setState(() {
          _allWholesalers.addAll(page.items);
          _currentPage = page.page;
          _hasMore = _allWholesalers.length < page.totalRows;
          _isLoadingMore = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationControllerProvider).valueOrNull;
    final wholesalersAsync = ref.watch(wholesalersListProvider((
      page: 1,
      lat: location?.latitude,
      lng: location?.longitude,
    )));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.allWholesalers ?? 'All Wholesalers',
        ),
        actions: const [
          CartIconButton(),
        ],
      ),
      body: wholesalersAsync.when(
        data: (page) {
          if (_allWholesalers.isEmpty) {
            _allWholesalers.addAll(page.items);
            _hasMore = _allWholesalers.length < page.totalRows;
          }

          if (_allWholesalers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.store_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)?.noWholesalersFound ??
                        'No wholesalers found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _allWholesalers.clear();
                _currentPage = 1;
                _hasMore = true;
              });
              ref.invalidate(wholesalersListProvider((
                page: 1,
                lat: location?.latitude,
                lng: location?.longitude,
              )));
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount:
                  _allWholesalers.length + (_hasMore && _isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _allWholesalers.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final wholesaler = _allWholesalers[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      leading: NetworkAvatar(
                        imageUrl: wholesaler.avatarUrl,
                        size: 50,
                        borderColor: wholesaler.hasActiveStory
                            ? Theme.of(context).colorScheme.secondary
                            : null,
                        borderWidth: wholesaler.hasActiveStory ? 3.0 : 1.5,
                        overlayIcon: wholesaler.hasActiveStory
                            ? Icons.play_circle_fill_outlined
                            : null,
                      ),
                      title: Text(wholesaler.businessName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (wholesaler.city != null) Text(wholesaler.city!),
                          if (wholesaler.distanceKm != null)
                            Text(
                              '${wholesaler.distanceKm!.toStringAsFixed(1)} km away',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          context.push('/wholesalers/${wholesaler.id}'),
                    ),
                  ),
                );
              },
            ),
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
                AppLocalizations.of(context)?.errorLoadingWholesalers ??
                    'Error loading wholesalers',
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
    );
  }
}
