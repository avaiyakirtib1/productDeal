import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_languages.dart';
import '../../features/auth/data/models/auth_models.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/dashboard/presentation/controllers/story_view_state.dart';

class LanguageController extends StateNotifier<Locale> {
  LanguageController(this._prefs, this._ref)
      : super(const Locale(AppLanguages.defaultLanguageCode)) {
    _loadLanguage();
  }

  final SharedPreferences _prefs;
  final Ref _ref;
  static const String _languageKey = 'application_language';

  Future<void> _loadLanguage() async {
    final savedLanguageCode = _prefs.getString(_languageKey);
    if (savedLanguageCode != null) {
      state = Locale(savedLanguageCode);
    } else {
      // First-time launch: check system language against supported languages
      final deviceLocales =
          WidgetsBinding.instance.platformDispatcher.locales;

      String? detectedLanguage;
      for (final locale in deviceLocales) {
        if (AppLanguages.supportedCodes.contains(locale.languageCode)) {
          detectedLanguage = locale.languageCode;
          break;
        }
      }

      // Fallback to primary device locale if not in device locales list
      final languageCode = detectedLanguage ??
          (AppLanguages.supportedCodes.contains(
                WidgetsBinding.instance.platformDispatcher.locale.languageCode)
              ? WidgetsBinding.instance.platformDispatcher.locale.languageCode
              : AppLanguages.defaultLanguageCode);

      state = Locale(languageCode);
      await _prefs.setString(_languageKey, languageCode);
    }
  }

  Future<bool> setLanguage(AppLanguage language) async {
    final previousLanguage = state.languageCode;
    state = Locale(language.code);
    await _prefs.setString(_languageKey, language.code);

    // Sync language preference to server if user is logged in
    if (previousLanguage != language.code) {
      debugPrint(
          '🌐 Language changed from $previousLanguage to ${language.code}, invalidating data providers');

      // Sync to server if user is authenticated
      try {
        final authController = _ref.read(authControllerProvider.notifier);
        final currentUser = authController.currentUser;
        if (currentUser != null) {
          // Update user profile with new language preference
          await authController.updateProfile(
            UpdateProfilePayload(preferredLanguage: language.code),
          );
          debugPrint(
              '✅ Language preference synced to server: ${language.code}');
          return true; // Success - server sync completed
        } else {
          // User not logged in, language saved locally only
          return true; // Success - no server sync needed
        }
      } catch (e) {
        // If sync fails, language is still saved locally but return false
        debugPrint('⚠️ Failed to sync language preference to server: $e');
        return false; // Failed - server sync did not complete
      }
    } else {
      // Language didn't change
      return true;
    }
  }

  AppLanguage getCurrentLanguage() =>
      AppLanguage.fromCode(state.languageCode);
}

final languageControllerProvider =
    StateNotifierProvider<LanguageController, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LanguageController(prefs, ref);
});
