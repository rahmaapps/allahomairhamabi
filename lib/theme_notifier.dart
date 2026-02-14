import 'package:flutter/material.dart';
import 'user_prefs.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  ThemeNotifier() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = UserPrefs();
    final mode = await prefs.getThemeMode();
    _themeMode = _mapMode(mode);
    notifyListeners();
  }

  ThemeMode _mapMode(String mode) {
    return switch (mode) {
      "light" => ThemeMode.light,
      "dark"  => ThemeMode.dark,
      _       => ThemeMode.system,
    };
  }

  Future<void> setTheme(String mode) async {
    final prefs = UserPrefs();
    await prefs.setThemeMode(mode);
    _themeMode = _mapMode(mode);
    notifyListeners(); // ➜ rebuild MaterialApp
  }
}