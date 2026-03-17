import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/location/location_service.dart';
import '../../../../core/localization/language_controller.dart';
import '../../data/models/dashboard_models.dart';
import '../../data/repositories/dashboard_repository.dart';

class DashboardController extends AsyncNotifier<DashboardSnapshot> {
  late final DashboardRepository _repository =
      ref.read(dashboardRepositoryProvider);

  @override
  Future<DashboardSnapshot> build() async {
    debugPrint(
        '🔷 DashboardController.build() called - should only happen ONCE');

    // CRITICAL FIX: Do NOT watch anything in build()!
    // ref.watch() causes rebuilds every time the watched provider changes.
    //
    // Solution: Use ref.read() for one-time reads
    // - Auth token: read from storage via API interceptor
    // - Location: read once, don't watch for changes
    //
    // Small delay ensures auth storage is initialized
    await Future.delayed(const Duration(milliseconds: 150));

    // ✅ Use ref.read (not ref.watch) to avoid rebuilds
    final locationState = ref.read(locationControllerProvider);
    final coords = locationState.valueOrNull;

    // Listen to language changes and refresh data when language changes
    ref.listen<Locale>(languageControllerProvider, (previous, next) {
      if (previous != null && previous != next) {
        debugPrint(
            '🌐 Language changed from ${previous.languageCode} to ${next.languageCode}, refreshing dashboard');
        refresh();
      }
    });

    debugPrint('🔷 Dashboard: Fetching snapshot ONCE with coords: $coords');
    return _repository.fetchSnapshot(
      latitude: coords?.latitude,
      longitude: coords?.longitude,
    );
  }

  Future<void> refresh({bool refreshLocation = false}) async {
    if (refreshLocation) {
      await ref.read(locationControllerProvider.notifier).refreshLocation();
    }

    final coords = ref.read(locationControllerProvider).valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.fetchSnapshot(
          latitude: coords?.latitude,
          longitude: coords?.longitude,
        ));
  }
}

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, DashboardSnapshot>(
        () => DashboardController(),
        name: 'DashboardControllerProvider');
