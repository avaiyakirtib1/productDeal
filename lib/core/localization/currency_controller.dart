import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/dashboard/presentation/controllers/story_view_state.dart';

/// Selected display currency. Null means use system/device default.
class CurrencyController extends StateNotifier<String?> {
  CurrencyController(this._prefs) : super(null) {
    _loadCurrency();
  }

  final SharedPreferences _prefs;
  static const String _currencyKey = 'app_display_currency';

  Future<void> _loadCurrency() async {
    final saved = _prefs.getString(_currencyKey);
    // Empty string is treated as system default
    state = (saved != null && saved.isNotEmpty) ? saved : null;
  }

  /// Set display currency. Pass null or empty to use system default.
  Future<void> setCurrency(String? code) async {
    final effective = (code != null && code.isNotEmpty) ? code : null;
    state = effective;
    await _prefs.setString(_currencyKey, effective ?? '');
  }

  /// Currently selected currency code, or null for system default.
  String? get selectedCurrencyCode => state;
}

final currencyControllerProvider =
    StateNotifierProvider<CurrencyController, String?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CurrencyController(prefs);
});
