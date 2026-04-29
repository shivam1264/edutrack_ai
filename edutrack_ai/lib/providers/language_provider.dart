import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  static const String _prefKey = 'selected_language';

  Locale get locale => _locale;

  LanguageProvider() {
    _loadSelectedLanguage();
  }

  Future<void> _loadSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString(_prefKey);
    if (languageCode != null && ['en', 'hi', 'mr', 'gu'].contains(languageCode)) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!['en', 'hi', 'mr', 'gu'].contains(locale.languageCode)) return;
    
    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, locale.languageCode);
  }

  Future<void> resetToDefault() async {
    _locale = const Locale('en');
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }

  void clearLocale() async {
    _locale = const Locale('en');
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }
}
