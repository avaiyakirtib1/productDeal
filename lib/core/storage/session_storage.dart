import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/models/auth_models.dart';

const _sessionKey = 'auth_session';
const _kHasLaunchedBefore = 'session_has_launched_before';

/// On iOS, Keychain can persist after app uninstall. SharedPreferences does not.
/// So on first launch (e.g. after reinstall), we clear secure storage so the user starts fresh.
Future<void> _clearKeychainIfFirstLaunchAfterInstall(
    FlutterSecureStorage storage) async {
  final prefs = await SharedPreferences.getInstance();
  final hasLaunched = prefs.getBool(_kHasLaunchedBefore) ?? false;
  if (!hasLaunched) {
    await storage.delete(key: _sessionKey);
    await prefs.setBool(_kHasLaunchedBefore, true);
  }
}

class SessionStorage {
  SessionStorage(this._storage);

  final FlutterSecureStorage _storage;

  Future<void> persistSession(AuthSession session) async {
    await _storage.write(key: _sessionKey, value: jsonEncode(session.toJson()));
  }

  Future<AuthSession?> readSession() async {
    await _clearKeychainIfFirstLaunchAfterInstall(_storage);
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AuthSession.fromJson(json);
    } catch (_) {
      await _storage.delete(key: _sessionKey);
      return null;
    }
  }

  Future<void> clear() => _storage.delete(key: _sessionKey);
}

final sessionStorageProvider = Provider<SessionStorage>(
  (ref) => SessionStorage(const FlutterSecureStorage()),
  name: 'SessionStorageProvider',
);
