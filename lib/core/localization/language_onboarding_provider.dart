import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/dashboard/presentation/controllers/story_view_state.dart';

const String _hasSelectedLanguageKey = 'has_selected_language';

/// Tracks whether the user has completed the initial language selection screen.
/// Used to show the onboarding language screen only once for unauthenticated users.
class HasSelectedLanguageNotifier extends StateNotifier<bool> {
  HasSelectedLanguageNotifier(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;

  static bool _read(SharedPreferences prefs) {
    return prefs.getBool(_hasSelectedLanguageKey) ?? false;
  }

  Future<void> setHasSelectedLanguage(bool value) async {
    if (state == value) return;
    state = value;
    await _prefs.setBool(_hasSelectedLanguageKey, value);
  }
}

final hasSelectedLanguageProvider =
    StateNotifierProvider<HasSelectedLanguageNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return HasSelectedLanguageNotifier(prefs);
});
