import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _storageKey = 'viewed_story_wholesaler_ids';

/// Tracks which wholesaler story groups have been viewed locally,
/// persisted across app restarts, so we can change the story ring color similar to WhatsApp.
class StoryViewStateNotifier
    extends StateNotifier<UnmodifiableSetView<String>> {
  StoryViewStateNotifier(this._prefs) : super(UnmodifiableSetView(<String>{})) {
    // Load from storage asynchronously
    _loadFromStorage();
  }

  final SharedPreferences _prefs;
  bool _isLoaded = false;

  Future<void> _loadFromStorage() async {
    if (_isLoaded) return;
    try {
      final stored = _prefs.getStringList(_storageKey) ?? [];
      if (stored.isNotEmpty) {
        state = UnmodifiableSetView(stored.toSet());
        debugPrint(
            'Loaded ${stored.length} viewed story wholesaler IDs from storage');
      } else {
        debugPrint('No stored story view state found');
      }
      _isLoaded = true;
    } catch (e) {
      // If loading fails, start with empty set
      debugPrint('Failed to load story view state: $e');
      _isLoaded = true;
    }
  }

  Future<void> markViewed(String wholesalerId) async {
    if (wholesalerId.isEmpty) return;
    if (state.contains(wholesalerId)) {
      debugPrint(
          'Story already marked as viewed for wholesaler: $wholesalerId');
      return;
    }

    debugPrint('Marking story as viewed for wholesaler: $wholesalerId');
    final next = {...state, wholesalerId};
    state = UnmodifiableSetView(next);

    // Persist to storage
    try {
      await _prefs.setStringList(_storageKey, next.toList());
      debugPrint('Story view state persisted. Total viewed: ${next.length}');
    } catch (e) {
      debugPrint('Failed to persist story view state: $e');
    }
  }

  bool isViewed(String wholesalerId) => state.contains(wholesalerId);
}

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences must be overridden'),
  name: 'SharedPreferencesProvider',
);

final storyViewStateProvider =
    StateNotifierProvider<StoryViewStateNotifier, UnmodifiableSetView<String>>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return StoryViewStateNotifier(prefs);
  },
  name: 'StoryViewStateProvider',
);
