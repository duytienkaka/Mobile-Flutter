import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static final ThemeController instance = ThemeController._();
  static const _storageKey = 'theme_mode';

  ThemeMode _mode = ThemeMode.light;

  ThemeController._();

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    switch (raw) {
      case 'dark':
        _mode = ThemeMode.dark;
        break;
      case 'light':
        _mode = ThemeMode.light;
        break;
      case 'system':
        _mode = ThemeMode.system;
        break;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_storageKey, value);
  }

  Future<void> toggle() {
    return setMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}
