import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/location/location_service.dart';
import '../../data/models/dashboard_models.dart';
import '../../data/repositories/dashboard_repository.dart';

class WholesalerDirectoryState {
  const WholesalerDirectoryState({
    required this.items,
    required this.page,
    required this.limit,
    required this.totalRows,
    required this.totalPages,
    this.isLoadingMore = false,
  });

  final List<SpotlightWholesaler> items;
  final int page;
  final int limit;
  final int totalRows;
  final int totalPages;
  final bool isLoadingMore;

  bool get hasNext => page < totalPages;

  WholesalerDirectoryState copyWith({
    List<SpotlightWholesaler>? items,
    int? page,
    int? limit,
    int? totalRows,
    int? totalPages,
    bool? isLoadingMore,
  }) {
    return WholesalerDirectoryState(
      items: items ?? this.items,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalRows: totalRows ?? this.totalRows,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class WholesalerDirectoryController
    extends AutoDisposeAsyncNotifier<WholesalerDirectoryState> {
  static const int _pageSize = 18;

  late final DashboardRepository _repository =
      ref.read(dashboardRepositoryProvider);

  @override
  FutureOr<WholesalerDirectoryState> build() async {
    final coords = ref.watch(locationControllerProvider).valueOrNull;
    return _fetchPage(page: 1, coords: coords);
  }

  Future<void> refresh() async {
    final coords = ref.read(locationControllerProvider).valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(page: 1, coords: coords));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasNext) return;
    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    try {
      final coords = ref.read(locationControllerProvider).valueOrNull;
      final response = await _repository.fetchWholesalers(
        page: current.page + 1,
        limit: _pageSize,
        latitude: coords?.latitude,
        longitude: coords?.longitude,
      );
      final updated = current.copyWith(
        items: [...current.items, ...response.items],
        page: response.page,
        limit: response.limit,
        totalRows: response.totalRows,
        totalPages: response.totalPages,
        isLoadingMore: false,
      );
      state = AsyncValue.data(updated);
    } catch (error, stack) {
      state = AsyncError(error, stack);
    }
  }

  Future<WholesalerDirectoryState> _fetchPage(
      {required int page, GeoPoint? coords}) async {
    final response = await _repository.fetchWholesalers(
      page: page,
      limit: _pageSize,
      latitude: coords?.latitude,
      longitude: coords?.longitude,
    );

    return WholesalerDirectoryState(
      items: response.items,
      page: response.page,
      limit: response.limit,
      totalRows: response.totalRows,
      totalPages: response.totalPages,
    );
  }
}

final wholesalerDirectoryControllerProvider = AutoDisposeAsyncNotifierProvider<
    WholesalerDirectoryController, WholesalerDirectoryState>(
  WholesalerDirectoryController.new,
  name: 'WholesalerDirectoryController',
);
