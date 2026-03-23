import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/networking/api_exception.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../../core/constants/app_languages.dart';
import '../../../../core/localization/language_controller.dart';
import '../../data/models/auth_models.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../orders/presentation/controllers/cart_controller.dart';

typedef AuthState = AsyncValue<AuthSession?>;

/// Reason why a logout happened. Helps us distinguish between a user clicking
/// "Sign out" and an automatic logout due to token expiry.
enum AuthLogoutReason {
  userInitiated,
  sessionExpired,
}

class AuthController extends AsyncNotifier<AuthSession?> {
  late final AuthRepository _repository = ref.read(authRepositoryProvider);
  late final SessionStorage _storage = ref.read(sessionStorageProvider);
  AuthLogoutReason? _lastLogoutReason;

  AuthLogoutReason? get lastLogoutReason => _lastLogoutReason;

  @override
  FutureOr<AuthSession?> build() async {
    return _storage.readSession();
  }

  Future<void> login(LoginPayload payload) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final session = await _repository.login(payload);
      await _storage.persistSession(session);

      // Initialize FCM after successful login
      // try {
      //   final fcmService = ref.read(fcmServiceProvider);
      //   await fcmService.initialize();
      // } catch (e) {
      //   debugPrint('Error initializing FCM after login: $e');
      // }

      return session;
    });
    state = result;

    // If login succeeded and user is admin/sub-admin, enforce German as the language
    final loggedInUser = result.valueOrNull?.user;
    if (loggedInUser != null &&
        (loggedInUser.role == UserRole.admin ||
            loggedInUser.role == UserRole.subAdmin)) {
      try {
        await ref
            .read(languageControllerProvider.notifier)
            .setLanguage(AppLanguage.german);
        debugPrint('🇩🇪 Admin login: language set to German');
      } catch (e) {
        debugPrint('⚠️ Failed to set German for admin: $e');
      }
    }

    // Rethrow so LoginFormController's AsyncValue.guard sees the error and shows error UI/snackbar
    result.whenOrNull(error: (err, _) => throw err);
  }

  Future<void> register(RegisterPayload payload) async {
    await AsyncValue.guard(() async {
      final session = await _repository.register(payload);
      // Registration still needs approval; tokens are stored for convenience.
      await _storage.persistSession(session);
      state = AsyncValue.data(session);
    });
  }

  Future<bool> refreshTokens() async {
    final currentSession = state.valueOrNull ?? await _storage.readSession();
    if (currentSession == null) {
      return false;
    }

    try {
      final tokens =
          await _repository.refresh(currentSession.tokens.refreshToken);
      final updatedSession =
          AuthSession(user: currentSession.user, tokens: tokens);
      await _storage.persistSession(updatedSession);
      state = AsyncData(updatedSession);
      return true;
    } catch (_) {
      await logout(reason: AuthLogoutReason.sessionExpired);
      return false;
    }
  }

  Future<void> refreshUser() async {
    final currentSession = state.valueOrNull ?? await _storage.readSession();
    if (currentSession == null) return;

    try {
      final updatedUser = await _repository.getCurrentUser();
      final updatedSession =
          AuthSession(user: updatedUser, tokens: currentSession.tokens);
      await _storage.persistSession(updatedSession);
      state = AsyncData(updatedSession);
    } catch (e) {
      // If refresh fails, keep current session
      debugPrint('Failed to refresh user: $e');
    }
  }

  Future<void> updateProfile(UpdateProfilePayload payload) async {
    final currentSession = state.valueOrNull ?? await _storage.readSession();
    if (currentSession == null) return;

    final updatedUser = await _repository.updateProfile(payload);
    final updatedSession =
        AuthSession(user: updatedUser, tokens: currentSession.tokens);
    await _storage.persistSession(updatedSession);
    state = AsyncData(updatedSession);
  }

  Future<void> logout(
      {AuthLogoutReason reason = AuthLogoutReason.userInitiated}) async {
    _lastLogoutReason = reason;

    // Clear all data - proceed even if any operation fails
    // 1. Tell the server to drop this device's FCM token (JWT still valid)
    try {
      final fcmService = ref.read(fcmServiceProvider);
      final fcmToken = await fcmService.resolveTokenForLogout();
      await _repository.logout(fcmToken: fcmToken);
      await fcmService.clearLocalPushRegistration();
    } catch (e) {
      debugPrint('Error FCM/server logout cleanup: $e');
    }

    // 2. Clear cart data (non-blocking)
    try {
      ref.read(cartControllerProvider.notifier).clear();
    } catch (e) {
      debugPrint('Error clearing cart on logout: $e');
      // Continue with logout even if cart clearing fails
    }

    // 3. Clear session storage (critical - must succeed)
    try {
      await _storage.clear();
    } catch (e) {
      debugPrint('Error clearing session storage on logout: $e');
      // Even if storage clear fails, we still set state to null to proceed with logout
    }

    // 4. Set auth state to null (this triggers router redirect to login)
    // This must always happen to ensure logout proceeds
    state = const AsyncData(null);
  }

  /// Clear the last logout reason once the UI has reacted to it.
  void clearLogoutReason() {
    _lastLogoutReason = null;
  }

  Future<void> hydrate() async {
    state = const AsyncLoading();
    final session = await _storage.readSession();
    state = AsyncData(session);
  }

  ApiException resolveError(Object error) {
    if (error is ApiException) return error;
    return ApiException(error.toString());
  }

  UserModel? get currentUser => state.valueOrNull?.user;
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(() => AuthController(),
        name: 'AuthControllerProvider');
/// Starts FCM when a session exists; [autoDispose] so each login re-runs token registration.
final fcmInitializedProvider = FutureProvider.autoDispose<void>((ref) async {
  final session = ref.watch(authControllerProvider).valueOrNull;
  if (session == null) return;

  final fcmService = ref.watch(fcmServiceProvider);
  await fcmService.initialize();
}, name: 'FCMInitializedProvider');