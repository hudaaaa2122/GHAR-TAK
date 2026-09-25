import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Session persistence via SharedPreferences.
/// Avoids flutter_secure_storage KeyStore hangs that freeze Android emulators on login.
class TokenStorage {
  TokenStorage();

  static const _access = 'access_token';
  static const _refresh = 'refresh_token';
  static const _userJson = 'user_json';
  static const introCompletedKey = 'intro_completed';

  SharedPreferences? _cached;

  Future<SharedPreferences> _prefs() async {
    if (_cached != null) return _cached!;
    // Longer timeout — cold start on some devices exceeds 2s.
    _cached = await SharedPreferences.getInstance().timeout(
      const Duration(seconds: 8),
      onTimeout: () => throw TimeoutException('SharedPreferences timeout'),
    );
    return _cached!;
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final p = await _prefs();
    await p.setString(_access, accessToken);
    await p.setString(_refresh, refreshToken);
  }

  Future<void> saveUserJson(String json) async {
    final p = await _prefs();
    await p.setString(_userJson, json);
  }

  Future<String?> get accessToken async {
    try {
      return (await _prefs()).getString(_access);
    } catch (_) {
      return null;
    }
  }

  Future<String?> get refreshToken async {
    try {
      return (await _prefs()).getString(_refresh);
    } catch (_) {
      return null;
    }
  }

  Future<String?> get userJson async {
    try {
      return (await _prefs()).getString(_userJson);
    } catch (_) {
      return null;
    }
  }

  Future<bool> get hasSession async {
    final token = await accessToken;
    return token != null && token.isNotEmpty;
  }

  Future<bool> get introCompleted async {
    try {
      return (await _prefs()).getBool(introCompletedKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setIntroCompleted(bool value) async {
    try {
      await (await _prefs()).setBool(introCompletedKey, value);
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      final p = await _prefs();
      await p.remove(_access);
      await p.remove(_refresh);
      await p.remove(_userJson);
    } catch (_) {}
  }
}
