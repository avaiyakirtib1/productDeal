import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/fcm_service.dart';
import '../../manager/presentation/screens/manager_dashboard_screen.dart';
import 'deal_providers.dart';
import 'repositories/deal_repository.dart';

/// Notification types that affect manager dashboard (orders, stats).
/// When these arrive via FCM, we invalidate manager stats so dashboard shows fresh data.
const _managerAffectingNotificationTypes = {
  'new_product_order',
  'new_deal_order',
  'order_status_changed',
  'deal_status_changed',
  'order_quantity_changed',
  'deal_order_quantity_changed',
  'payment_reported_by_buyer',
};

/// Parameters for the deal list (used when registering for live refresh).
/// Must match [DealListParams] from deal_list_screen (same shape for subscription).
class DealListSubscriptionParams {
  const DealListSubscriptionParams({
    this.storyId,
    this.wholesalerId,
    this.productId,
  });

  final String? storyId;
  final String? wholesalerId;
  final String? productId;
}

/// Centralized live data for deals: one place that polls deal list and open
/// deal details so that when a deal is closed (or data changes), list and
/// detail screens update without each doing their own polling.
///
/// - Registers detail when deal detail screen is visible; unregisters on dispose.
/// - Registers list when deal list screen is visible; unregisters on dispose.
/// - Single timer (e.g. every 15s) only when at least one subscriber exists.
/// - On tick: refetches subscribed deal details; invalidates detail provider
///   if deal ended; calls list invalidate callback so list refetches.
///
/// Server load: one request per open detail every 15s; list invalidation triggers
/// one list fetch. No polling when no deal/list screen is open.
class DealLiveDataService {
  DealLiveDataService(this._ref, this._repo);

  final Ref _ref;
  final DealRepository _repo;

  final Set<String> _detailIds = {};
  VoidCallback? _listInvalidate;

  Timer? _timer;

  static const Duration _pollInterval = Duration(seconds: 15);

  void registerDetail(String dealId) {
    _detailIds.add(dealId);
    _startTimerIfNeeded();
  }

  void unregisterDetail(String dealId) {
    _detailIds.remove(dealId);
    _stopTimerIfNoSubscribers();
  }

  /// [invalidate] is typically ref.invalidate(dealListControllerProvider(params)).
  void registerList(DealListSubscriptionParams params, VoidCallback invalidate) {
    _listInvalidate = invalidate;
    _startTimerIfNeeded();
  }

  void unregisterList() {
    _listInvalidate = null;
    _stopTimerIfNoSubscribers();
  }

  bool get _hasSubscribers =>
      _detailIds.isNotEmpty || _listInvalidate != null;

  void _startTimerIfNeeded() {
    if (_timer?.isActive == true) return;
    _timer = Timer.periodic(_pollInterval, (_) => _onTick());
    if (kDebugMode) {
      debugPrint(
          'DealLiveData: timer started (details: ${_detailIds.length}, list: ${_listInvalidate != null})');
    }
  }

  void _stopTimerIfNoSubscribers() {
    if (!_hasSubscribers) {
      _timer?.cancel();
      _timer = null;
      if (kDebugMode) debugPrint('DealLiveData: timer stopped');
    }
  }

  Future<void> _onTick() async {
    if (!_hasSubscribers) return;

    final detailIds = Set<String>.from(_detailIds);
    final listInvalidate = _listInvalidate;

    for (final id in detailIds) {
      try {
        final detail = await _repo.fetchDealDetail(id);
        if (detail.isEnded) {
          _ref.invalidate(dealDetailProvider(id));
        }
      } catch (_) {
        _ref.invalidate(dealDetailProvider(id));
      }
    }

    listInvalidate?.call();
  }
}

final dealLiveDataProvider = Provider<DealLiveDataService>((ref) {
  return DealLiveDataService(ref, ref.watch(dealRepositoryProvider));
});

/// Sets FCM notification handler for deal_closed and order-related pushes.
/// - deal_closed: invalidates deal detail (UI refreshes / hides closed deal).
/// - Order-related types: invalidates manager stats so dashboard shows fresh data
///   when orders are placed from another device (zero extra server/DB load).
final fcmDealClosedHandlerProvider = Provider<void>((ref) {
  ref.watch(fcmInitializedProvider);
  ref.read(fcmServiceProvider).setNotificationDataHandler((type, data) {
    if (type == 'deal_closed') {
      final dealId = data['dealId'] as String?;
      if (dealId != null && dealId.isNotEmpty) {
        ref.invalidate(dealDetailProvider(dealId));
      }
    }
    if (_managerAffectingNotificationTypes.contains(type)) {
      ref.invalidate(managerStatsProvider);
    }
  });
});
