import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../services/places_service.dart';

final placesServiceProvider = Provider<PlacesService>(
  (ref) {
    final base = ref.watch(appConfigProvider).apiBaseUrl;
    debugPrint(
      '[PlacesServiceProvider] apiBaseUrl non-empty: ${base.trim().isNotEmpty}',
    );
    final service = PlacesService(apiBaseUrl: base);
    ref.onDispose(service.dispose);
    return service;
  },
  name: 'PlacesServiceProvider',
);
