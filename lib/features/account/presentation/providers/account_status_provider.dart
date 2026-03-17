import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/account_models.dart';
import '../../data/repositories/account_repository.dart';

/// Provider for account status with polling
final accountStatusProvider = StreamProvider.autoDispose<AccountStatus>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  final controller = StreamController<AccountStatus>();
  Timer? timer;
  int pollCount = 0;
  bool isDisposed = false;

  // Initial fetch
  repository.getStatus().then((status) {
    if (!isDisposed) controller.add(status);
  });

  // Polling with backoff and jitter
  void scheduleNextPoll() {
    if (isDisposed) return;

    // Calculate delay with backoff and jitter
    int baseDelay;
    if (pollCount < 12) {
      // First 2 minutes: 10-20s (with jitter)
      baseDelay = 10 + (pollCount % 2) * 5; // 10s or 15s
    } else if (pollCount < 32) {
      // Next 10 minutes: 30-60s
      baseDelay = 30 + ((pollCount - 12) % 2) * 15; // 30s or 45s
    } else {
      // After that: 2-5 min
      baseDelay = 120 + ((pollCount - 32) % 3) * 60; // 2min, 3min, or 4min
    }

    // Add jitter (±20%)
    final jitter = (baseDelay * 0.2 * (pollCount % 3 - 1)).round();
    final delay = baseDelay + jitter;

    timer?.cancel();
    timer = Timer(Duration(seconds: delay), () {
      if (!isDisposed) {
        pollCount++;
        repository.getStatus().then((status) {
          if (!isDisposed) {
            controller.add(status);
            if (status.isApproved) {
              // Stop polling when approved
              timer?.cancel();
            } else {
              scheduleNextPoll();
            }
          }
        }).catchError((error) {
          if (!isDisposed) {
            debugPrint('Status poll error: $error');
            scheduleNextPoll(); // Continue polling on error
          }
        });
      }
    });
  }

  scheduleNextPoll();

  ref.onDispose(() {
    isDisposed = true;
    timer?.cancel();
    controller.close();
  });

  return controller.stream;
});
