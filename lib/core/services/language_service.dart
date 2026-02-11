import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🌍 LanguageService handles app localization state and persistence.
/// It allows switching between English, Sinhala, and Tamil dynamically
/// without restarting the app.
class LanguageService with ChangeNotifier {
  static const String _languageCodeKey = 'languageCode';
  Locale _locale = const Locale('en'); // Default to English

  Locale get locale => _locale;

  LanguageService() {
    _loadLocale(); // Automatically load saved locale on service creation
  }

  /// 🔹 Loads saved locale from persistent storage
  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageCodeKey);

      if (languageCode != null && languageCode.isNotEmpty) {
        _locale = Locale(languageCode);
        notifyListeners(); // Trigger rebuild when loaded
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load saved locale: $e');
    }
  }

  /// 🔹 Public method for main.dart (used before runApp)
  Future<void> loadLocale() async => await _loadLocale();

  /// 🔹 Updates and persists a new locale
  Future<void> setLocale(String languageCode) async {
    if (languageCode.isEmpty) {
      return;
    }

    try {
      _locale = Locale(languageCode);
      notifyListeners(); // 🔄 Instantly update UI

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageCodeKey, languageCode);
    } catch (e) {
      debugPrint('⚠️ Failed to save locale: $e');
    }
  }

  /// 🔹 Optionally reset to default (English)
  Future<void> resetToDefault() async {
    _locale = const Locale('en');
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_languageCodeKey);
  }
}
