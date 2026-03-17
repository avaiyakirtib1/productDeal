import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/deal_models.dart';
import 'repositories/deal_repository.dart';

/// Shared deal detail provider so [DealLiveDataService] can invalidate it
/// without importing the detail screen (avoids circular deps).
final dealDetailProvider =
    FutureProvider.autoDispose.family<DealDetail, String>((ref, id) async {
  final repo = ref.watch(dealRepositoryProvider);
  return repo.fetchDealDetail(id);
});
