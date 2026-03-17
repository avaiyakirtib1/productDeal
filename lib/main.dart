import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/dashboard/presentation/controllers/story_view_state.dart';
import 'firebase_options.dart';

void main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    // Ignore image loading errors (e.g. data: URIs passed to CachedNetworkImage)
    if (_isImageLoadingError(details.exception)) return;

    // Handles framework errors
    FlutterError.presentError(details);
    // Prevent crash
    Zone.current.handleUncaughtError(
        details.exception, details.stack ?? StackTrace.empty);
  };

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase initialized');
    } catch (e) {
      debugPrint('❌ Firebase initialization error: $e');
      // Continue anyway - FCM will handle gracefully
    }

    // Initialize SharedPreferences
    final sharedPreferences = await SharedPreferences.getInstance();

    runApp(
      Phoenix(
        child: ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          ],
          child: const ProductDealApp(),
        ),
      ),
    );
  }, (error, stack) {
    // Ignore image loading errors (e.g. data: URIs passed to CachedNetworkImage)
    if (_isImageLoadingError(error)) return;

    // Log only actual code errors
    debugPrint("Zoned Error: $error");
    debugPrint("Zoned Stack Trace: $stack");
  });
}

/// Returns true if the error is an image loading error that can be safely ignored.
bool _isImageLoadingError(Object error) {
  final msg = error.toString();
  // CachedNetworkImage/flutter_cache_manager fails when given data: URIs
  if (msg.contains('No host specified in URI') &&
      msg.contains('data:image')) {
    return true;
  }
  return false;
}
