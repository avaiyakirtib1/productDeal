import 'package:flutter/material.dart';

/// Single source of truth for supported languages in the app.
/// Must match backend [Product-Deal-Backend/src/config/translation.config.ts]
/// (sourceLanguage + targetLanguages).
///
/// Used for:
/// - App locale (first launch, language selection)
/// - Content creation (Product, Deal, Banner, Category source language dropdown)
/// - MaterialApp supportedLocales
/// - AppLocalizations delegate isSupported
class AppLanguages {
  AppLanguages._();

  /// Supported language codes. Add new codes here and to [AppLanguage] enum.
  static const List<String> supportedCodes = [
    'en',
    'de',
    'tr',
    'ar',
    'ur',
    'hi',
    'ru',
  ];

  /// Default language when system locale does not match any supported language.
  static const String defaultLanguageCode = 'de';

  /// Display names for dropdowns (Product, Deal, Banner, Category creation).
  static const Map<String, String> displayNames = {
    'en': 'English',
    'de': 'German',
    'tr': 'Turkish',
    'ar': 'Arabic',
    'ur': 'Urdu',
    'hi': 'Hindi',
    'ru': 'Russian',
  };

  /// Locales for MaterialApp.supportedLocales.
  static List<Locale> get supportedLocales =>
      supportedCodes.map((c) => Locale(c)).toList();

  /// Content source languages for Create Product, Deal, Banner, Category.
  /// Same as [supportedCodes] - user selects the language they enter content in.
  static const List<String> contentSourceLanguages = supportedCodes;

  /// Display names for content source language (alias for [displayNames]).
  static const Map<String, String> contentLanguageNames = displayNames;

  static bool isSupported(String languageCode) =>
      supportedCodes.contains(languageCode);
}

/// App language enum for language selection screen.
/// Must stay in sync with [AppLanguages.supportedCodes].
enum AppLanguage {
  english('en', 'English'),
  german('de', 'Deutsch'),
  turkish('tr', 'Turkish'),
  arabic('ar', 'Arabic'),
  urdu('ur', 'Urdu'),
  hindi('hi', 'Hindi'),
  russian('ru', 'Russian');

  final String code;
  final String displayName;
  const AppLanguage(this.code, this.displayName);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}
