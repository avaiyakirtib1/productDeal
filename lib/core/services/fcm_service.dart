import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase_options.dart';
import '../config/app_config.dart';
import '../localization/app_localizations.dart';
import '../constants/app_languages.dart';
import '../../features/dashboard/presentation/controllers/story_view_state.dart';
import '../networking/api_client.dart';
import 'notification_helper.dart';

// Initialize local notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Top-level function for handling background messages
/// This runs in a separate isolate when app is in background/terminated
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('📱 Background message received: ${message.messageId}');
  debugPrint('📱 Background message data: ${message.data}');

  // We use data-only messages (for localization), so we must display local notifications here.
  if (kIsWeb) return;

  try {
    // Ensure plugin is initialized in this isolate.
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await flutterLocalNotificationsPlugin.initialize(initSettings);

    final prefs = await SharedPreferences.getInstance();
    final languageCode =
        prefs.getString('application_language') ?? AppLanguages.defaultLanguageCode;
    final l10n = AppLocalizations(Locale(languageCode));

    final data = Map<String, dynamic>.from(message.data);
    final titleKey = data['titleLocKey'] as String?;
    final bodyKey = data['bodyLocKey'] as String?;
    final titleArgs = _parseArgs(data['titleLocArgs']);
    final bodyArgs = _parseArgs(data['bodyLocArgs']);

    final title = titleKey != null ? l10n.translateWithArgs(titleKey, titleArgs) : '';
    final body = bodyKey != null ? l10n.translateWithArgs(bodyKey, bodyArgs) : '';

    if (title.isEmpty && body.isEmpty) return;
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data.toString(),
    );
  } catch (e) {
    debugPrint('❌ Background notification display failed: $e');
  }
}

/// Callback for notification data (type + payload) so app can invalidate providers etc.
typedef NotificationDataHandler = void Function(String type, Map<String, dynamic> data);

/// Deduplicate foreground messages - same messageId can be delivered twice in edge cases
final _recentMessageIds = <String>{};
const _dedupeWindowMs = 10000; // 10 seconds

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final Dio _dio;
  final SharedPreferences _prefs;
  StreamSubscription<String>? _tokenSubscription;
  NotificationDataHandler? _notificationDataHandler;

  FCMService(this._dio, this._prefs);

  Locale _currentLocale() {
    final code = _prefs.getString('application_language') ??
        AppLanguages.defaultLanguageCode;
    return Locale(code);
  }

  /// Set handler for notification data (e.g. deal_closed). Called for foreground messages and on tap.
  void setNotificationDataHandler(NotificationDataHandler? handler) {
    _notificationDataHandler = handler;
  }

  /// Initialize local notifications for foreground messages
  Future<void> _initializeLocalNotifications() async {
    if (kIsWeb) {
      // Web notifications are handled by the service worker
      // No need to initialize local notifications for web
      return;
    }

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    if (Platform.isIOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Local notification tapped: ${response.payload}');
        // Handle notification tap - can navigate to specific screen
      },
    );

    // Create Android notification channel (required for Android 8.0+)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // Same as in AndroidManifest.xml
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Initialize FCM service
  Future<void> initialize() async {
    try {
      // Check if Firebase is initialized
      try {
        Firebase.app();
      } catch (e) {
        debugPrint('Firebase not initialized, skipping FCM setup: $e');
        return;
      }

      // Request permission for notifications
      final settings = await _requestPermission();
      debugPrint('FCM Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Initialize local notifications for foreground messages
        await _initializeLocalNotifications();

        // Set up background message handler (must be called before other handlers)
        FirebaseMessaging.onBackgroundMessage(
            firebaseMessagingBackgroundHandler);

        // Handle foreground messages (when app is open)
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle notification taps (when app is in background/terminated)
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

        // Check if app was opened from a notification (when app was terminated)
        final initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }

        // Get and register FCM token
        // On iOS, this will ensure APNs token is available first
        await _registerToken();

        // Listen for token refresh (works on Android, iOS, and Web)
        _tokenSubscription = _messaging.onTokenRefresh.listen((newToken) {
          debugPrint('🔄 FCM Token refreshed: $newToken');
          _registerTokenWithBackend(newToken);
        });

        debugPrint('✅ FCM service initialized successfully');
      } else {
        debugPrint('⚠️ FCM Permission denied');
      }
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
    }
  }

  /// Request notification permissions
  Future<NotificationSettings> _requestPermission() async {
    if (kIsWeb) {
      // Web permissions
      return await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    } else {
      // Mobile permissions (Android/iOS)
      return await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    }
  }

  /// Register FCM token with backend
  /// Works on all platforms: Android, iOS, and Web
  Future<void> _registerToken() async {
    try {
      // On iOS, ensure APNs token is available before getting FCM token
      if (!kIsWeb && Platform.isIOS) {
        // Get APNs token first (required for iOS)
        String? apnsToken = await _messaging.getAPNSToken();

        if (apnsToken == null) {
          debugPrint('⏳ APNs token not yet available, waiting...');
          // Wait a bit and retry (APNs token might be available after a short delay)
          await Future.delayed(const Duration(seconds: 2));
          apnsToken = await _messaging.getAPNSToken();
        }

        if (apnsToken != null) {
          debugPrint('✅ APNs token obtained: ${apnsToken.substring(0, 20)}...');
        } else {
          debugPrint(
              '⚠️ APNs token still not available. FCM token might not be generated.');
          debugPrint('   This can happen if:');
          debugPrint(
              '   - Push Notifications capability is not enabled in Xcode');
          debugPrint('   - App is not properly signed');
          debugPrint(
              '   - Running on simulator (APNs requires physical device)');
        }
      }

      // Get FCM token (works cross-platform)
      // Web: vapidKey is REQUIRED for Chrome/Brave/Safari - set in app_config or --dart-define
      final vapidKey = AppConfig.fcmWebVapidKey;
      if (kIsWeb && vapidKey.isEmpty) {
        debugPrint('⚠️ Web VAPID key not set - push will fail on Chrome/Brave. See PUSH_NOTIFICATIONS_TROUBLESHOOTING.md');
      }
      final token = await _messaging.getToken(
        vapidKey: vapidKey.isNotEmpty ? vapidKey : null,
      );
      if (token != null && token.isNotEmpty) {
        debugPrint('📱 FCM Token obtained: ${token.substring(0, 20)}...');
        await _registerTokenWithBackend(token);
      } else {
        debugPrint('⚠️ FCM Token is null');
        if (!kIsWeb && Platform.isIOS) {
          debugPrint(
              '   On iOS, this usually means APNs token is not available.');
        }
      }
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      // On iOS, this might fail if:
      // - APNs certificate not configured in Firebase
      // - Push Notifications capability not enabled
      // - App not properly signed
      // - APNs token not available
    }
  }

  /// Register token with backend API
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      await _dio.post(
        '/notifications/register-token',
        data: {'fcmToken': token},
      );
      debugPrint('FCM token registered with backend');
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }

  /// Handle foreground messages (when app is open)
  /// - iOS: setForegroundNotificationPresentationOptions(alert:true) means the
  ///   system already displays the notification. Do NOT show local notification
  ///   to avoid duplicate.
  /// - Android: FCM does not auto-display when in foreground. Show local
  ///   notification so user sees it.
  /// - Web: Browser handles display.
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Deduplicate: same messageId can be delivered twice (FCM/Stream edge case)
    final msgId = message.messageId ?? '${message.data.hashCode}';
    if (_recentMessageIds.contains(msgId)) {
      debugPrint('📬 Skipping duplicate foreground message: $msgId');
      return;
    }
    _recentMessageIds.add(msgId);
    Future.delayed(const Duration(milliseconds: _dedupeWindowMs), () {
      _recentMessageIds.remove(msgId);
    });

    debugPrint('📬 Foreground message received: $msgId');
    debugPrint('📬 Message data: ${message.data}');

    final data = Map<String, dynamic>.from(message.data);
    final type = data['type'] as String? ?? '';
    _notificationDataHandler?.call(type, data);

    final locale = _currentLocale();
    final l10n = AppLocalizations(locale);

    final titleKey = data['titleLocKey'] as String?;
    final bodyKey = data['bodyLocKey'] as String?;
    final titleArgs = _parseArgs(data['titleLocArgs']);
    final bodyArgs = _parseArgs(data['bodyLocArgs']);

    final title = titleKey != null
        ? l10n.translateWithArgs(titleKey, titleArgs)
        : (message.notification?.title ?? '');
    final body = bodyKey != null
        ? l10n.translateWithArgs(bodyKey, bodyArgs)
        : (message.notification?.body ?? '');

    if (title.isEmpty && body.isEmpty) return;

    // iOS: system shows foreground notifications (alert:true). Avoid duplicates.
    if (!kIsWeb && Platform.isIOS) return;

    if (kIsWeb) {
      showWebForegroundNotification(title, body);
    } else {
      await _showLocalNotification(
        title: title,
        body: body,
        payload: message.data.toString(),
      );
    }
  }

  /// Show local notification (for foreground messages)
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) {
      // Web notifications are handled by the browser/service worker
      // FCM automatically shows them
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance_channel', // Same channel ID as in AndroidManifest
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/launcher_icon',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Handle notification tap (when app is in background/terminated)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.messageId}');
    debugPrint('Notification data: ${message.data}');

    final data = Map<String, dynamic>.from(message.data);
    final type = data['type'] as String? ?? '';
    _notificationDataHandler?.call(type, data);
  }

  /// Unregister token (call on logout)
  Future<void> unregisterToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        // Unregister from backend
        await _dio.post(
          '/notifications/unregister-token',
          data: {'fcmToken': token},
        );
        debugPrint('FCM token unregistered from backend');

        // Delete token from Firebase Messaging
        await _messaging.deleteToken();
        debugPrint('FCM token deleted from Firebase');
      }
    } catch (e) {
      debugPrint('Error unregistering FCM token: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _tokenSubscription?.cancel();
  }
}

/// Provider for FCM Service
final fcmServiceProvider = Provider<FCMService>((ref) {
  final dio = ref.watch(dioProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return FCMService(dio, prefs);
}, name: 'FCMServiceProvider');

List<String> _parseArgs(dynamic raw) {
  if (raw == null) return const [];
  if (raw is List) return raw.map((e) => e.toString()).toList();
  if (raw is String) {
    // Backend sends JSON array string.
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.map((e) => e.toString()).toList();
    } catch (_) {
      return const [];
    }
  }
  return const [];
}

/// Provider for FCM initialization
final fcmInitializedProvider = FutureProvider<void>((ref) async {
  final fcmService = ref.watch(fcmServiceProvider);
  await fcmService.initialize();
}, name: 'FCMInitializedProvider');
