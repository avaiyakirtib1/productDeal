# Localization (i18n) Implementation

## Overview
The app now supports multiple languages with English and German as the initial languages. The language preference is persisted and the app defaults to the device language on first launch.

## Implementation Details

### 1. Core Localization Infrastructure

**Files Created:**
- `lib/core/localization/app_localizations.dart` - Main localization class with all translations
- `lib/core/localization/language_controller.dart` - Language state management with persistence

**Key Features:**
- Automatic device language detection on first launch
- Language preference persisted in SharedPreferences
- Easy to add new languages in the future
- Type-safe translation accessors

### 2. Language Selection

**Files Created:**
- `lib/features/options/presentation/screens/language_selection_screen.dart` - Language selection UI

**Features:**
- Accessible from Options screen
- Shows current language with checkmark
- Immediate language change on selection
- Available to all users (logged in or not)

### 3. Updated Screens

The following screens have been updated with translations:

1. **Options Screen** (`options_screen.dart`)
   - All menu items translated
   - Logout confirmation dialog translated
   - Language option added

2. **About Us Screen** (`about_us_screen.dart`)
   - All content translated

3. **FAQ Screen** (`faq_screen.dart`)
   - All questions and answers translated

4. **Banner Carousel** (`banner_carousel.dart`)
   - Advertisement text translated

5. **App** (`app.dart`)
   - Session expiry dialog translated

## Usage

### Accessing Translations

```dart
import 'package:your_app/core/localization/app_localizations.dart';

// In a widget
final l10n = AppLocalizations.of(context);
Text(l10n?.options ?? 'Options')  // Fallback to English if null
```

### Changing Language Programmatically

```dart
import 'package:your_app/core/localization/language_controller.dart';

// In a ConsumerWidget or ConsumerStatefulWidget
ref.read(languageControllerProvider.notifier).setLanguage(AppLanguage.german);
```

### Adding New Languages

1. Add language enum in `language_controller.dart`:
```dart
enum AppLanguage {
  english('en', 'English'),
  german('de', 'Deutsch'),
  french('fr', 'Français'),  // New language
}
```

2. Add translations in `app_localizations.dart`:
```dart
static final Map<String, Map<String, String>> _localizedValues = {
  'en': { ... },
  'de': { ... },
  'fr': { ... },  // New translations
};
```

3. Update `isSupported` method:
```dart
@override
bool isSupported(Locale locale) {
  return ['en', 'de', 'fr'].contains(locale.languageCode);
}
```

4. Update `supportedLocales` in `app.dart`:
```dart
supportedLocales: const [
  Locale('en'),
  Locale('de'),
  Locale('fr'),
],
```

5. Add language tile in `language_selection_screen.dart`

## Language Detection

The app follows this priority:
1. **User's saved preference** (from SharedPreferences)
2. **Device language** (if German, uses German; otherwise English)
3. **Default to English** (fallback)

## Translation Keys

All translation keys are defined in `app_localizations.dart`. Current categories:

- Options Screen
- Language Selection
- Common UI elements
- About Us content
- FAQ questions and answers
- Dashboard banners
- Order-related terms

## Future Enhancements

To add more translations to other screens:

1. Add translation keys to `_localizedValues` in `app_localizations.dart`
2. Add getter methods for easy access
3. Update the screen/widget to use `AppLocalizations.of(context)`
4. Provide fallback text using `??` operator

## Testing

1. **Test language switching:**
   - Go to Options → Language
   - Select different language
   - Verify all text changes immediately

2. **Test persistence:**
   - Change language
   - Close and reopen app
   - Verify language is maintained

3. **Test device language detection:**
   - Clear app data
   - Set device language to German
   - Open app
   - Verify German is selected

## Notes

- All translations use null-safe access with fallbacks
- Missing translations fall back to English
- Language changes take effect immediately without app restart
- The language controller is a Riverpod StateNotifier for reactive updates
