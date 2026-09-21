import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Session persistence via SharedPreferences.
/// Avoids flutter_secure_storage KeyStore hangs that freeze Android emulators on login.
class TokenStorage {
  TokenStorage();

  static const _access = 'access_token';
  static const _refresh = 'refresh_token';
  static const _userJson = 'user_json';

  SharedPreferences? _cached;

  Future<SharedPreferences> _prefs() async {
    return _cached ??= await SharedPreferences.getInstance().timeout(
      const Duration(seconds: 2),
      onTimeout: () => throw TimeoutException('SharedPreferences timeout'),
    );
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      final p = await _prefs();
      await p.setString(_access, accessToken);
      await p.setString(_refresh, refreshToken);
    } catch (_) {
      // Never block / crash sign-in if prefs fail on emulator.
    }
  }

  Future<void> saveUserJson(String json) async {
    try {
      final p = await _prefs();
      await p.setString(_userJson, json);
    } catch (_) {}
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

  Future<void> clear() async {
    try {
      final p = await _prefs();
      await p.remove(_access);
      await p.remove(_refresh);
      await p.remove(_userJson);
    } catch (_) {}
  }
}
