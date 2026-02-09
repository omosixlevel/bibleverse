import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Locale Provider
/// Manages app language (English/French) with persistence
class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  Locale _locale = const Locale('en');
  SharedPreferences? _prefs;

  LocaleProvider() {
    _loadLocale();
  }

  Locale get locale => _locale;
  bool get isFrench => _locale.languageCode == 'fr';

  Future<void> _loadLocale() async {
    _prefs = await SharedPreferences.getInstance();
    final languageCode = _prefs?.getString(_localeKey) ?? 'en';
    _locale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (!['en', 'fr'].contains(locale.languageCode)) return;

    _locale = locale;
    await _prefs?.setString(_localeKey, locale.languageCode);
    notifyListeners();
    print('🌍 Language changed to: ${locale.languageCode}');
  }

  // Helper to toggle between English and French
  Future<void> toggleLocale() async {
    final newLocale = _locale.languageCode == 'en'
        ? const Locale('fr')
        : const Locale('en');
    await setLocale(newLocale);
  }
}
