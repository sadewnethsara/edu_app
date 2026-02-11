import 'package:flutter/material.dart';

class ThemeService with ChangeNotifier {
  // Default to system theme
  ThemeMode _themeMode = ThemeMode.system;

  // Getter
  ThemeMode get themeMode => _themeMode;

  // Toggler
  void toggleTheme() {
    // We'll toggle between light and dark, ignoring 'system' for simplicity
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }
}
