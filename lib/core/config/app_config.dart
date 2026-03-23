import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
  });

  final String apiBaseUrl;

  static const String _defaultHost = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'https://product-deal-express.vercel.app');

  static const String defaultBaseUrl = '$_defaultHost/api/v1';

  /// Web push VAPID key (Chrome/Brave/Safari require this).
  /// Get from: Firebase Console → Project Settings → Cloud Messaging → Web Push certificates → Generate key pair
  /// Option 1: Set _vapidKeyOverride below (e.g. 'BGpdLRs...') - public key, safe to commit
  /// Option 2: flutter build web --dart-define=VAPID_KEY=YourKeyHere
  static const String _vapidKeyOverride = 'BJ-9lz9O7JXggUfNgbJrswaacnMr5cL41NaSstO0bcCGT-BmSuZgCh8wwtvi2WDzYWbxMnwaT2W73aHfY-jdhtU';
  static const String fcmWebVapidKey =
      _vapidKeyOverride != '' ? _vapidKeyOverride : String.fromEnvironment('VAPID_KEY', defaultValue: '');
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig(
    apiBaseUrl: AppConfig.defaultBaseUrl,
  ),
  name: 'AppConfigProvider',
);
