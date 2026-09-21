import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = 'theme_mode'; // system | light | dark

final themeModeProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  return ThemeModeController();
});

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController() : super(ThemeMode.light) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final p = await SharedPreferences.getInstance();
      switch (p.getString(_kThemeModeKey)) {
        case 'dark':
          state = ThemeMode.dark;
        case 'system':
          state = ThemeMode.system;
        default:
          state = ThemeMode.light;
      }
    } catch (_) {}
  }

  Future<void> setDark(bool dark) async {
    state = dark ? ThemeMode.dark : ThemeMode.light;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kThemeModeKey, dark ? 'dark' : 'light');
    } catch (_) {}
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    try {
      final p = await SharedPreferences.getInstance();
      final v = switch (mode) {
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
      };
      await p.setString(_kThemeModeKey, v);
    } catch (_) {}
  }
}
