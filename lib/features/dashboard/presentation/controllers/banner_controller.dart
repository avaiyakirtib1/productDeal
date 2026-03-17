import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/language_controller.dart';
import '../../data/repositories/banner_repository.dart';
import '../../domain/models/banner_model.dart';

// Public Banners Controller
class PublicBannersController extends AsyncNotifier<List<BannerModel>> {
  @override
  FutureOr<List<BannerModel>> build() {
    // Watch language to refresh when language changes (though app restart handles this)
    ref.watch(languageControllerProvider);
    return ref.read(bannerRepositoryProvider).fetchPublicBanners();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(bannerRepositoryProvider).fetchPublicBanners());
  }
}

final publicBannersProvider =
    AsyncNotifierProvider<PublicBannersController, List<BannerModel>>(
        PublicBannersController.new);

// Manage Banners Controller (For Admin/Wholesaler List)
// Using family to filter by status if needed, but for now simple list
final manageBannersProvider = FutureProvider.autoDispose
    .family<List<BannerModel>, String?>((ref, status) {
  // Watch language to refresh when language changes (though app restart handles this)
  ref.watch(languageControllerProvider);
  return ref.watch(bannerRepositoryProvider).fetchManageBanners(status: status);
});

// Single banner detail (for detail screen)
final bannerDetailProvider = FutureProvider.autoDispose
    .family<BannerModel?, String>((ref, id) async {
  ref.watch(languageControllerProvider);
  try {
    return await ref.read(bannerRepositoryProvider).fetchBannerById(id);
  } catch (_) {
    return null;
  }
});

// Banner Actions Controller (Create, Update, Delete)
class BannerActionsController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> createBanner(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(bannerRepositoryProvider).createBanner(data));
    return !state.hasError;
  }

  Future<bool> updateStatus(String id, String status) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() =>
        ref.read(bannerRepositoryProvider).updateBannerStatus(id, status));
    return !state.hasError;
  }

  Future<bool> deleteBanner(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(bannerRepositoryProvider).deleteBanner(id));
    return !state.hasError;
  }

  Future<BannerModel?> updateBanner(String id, Map<String, dynamic> data) async {
    try {
      return await ref.read(bannerRepositoryProvider).updateBanner(id, data);
    } catch (_) {
      return null;
    }
  }
}

final bannerActionsControllerProvider =
    AsyncNotifierProvider<BannerActionsController, void>(
        BannerActionsController.new);
