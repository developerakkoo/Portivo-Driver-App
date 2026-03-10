import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'driver_provider.dart';

class LocaleProvider with ChangeNotifier {
  Locale? _locale;
  static const String _localeKey = 'app_locale';

  Locale? get currentLocale => _locale;

  LocaleProvider() {
    _loadLocaleFromStorage();
  }

  /// Load locale from SharedPreferences
  Future<void> _loadLocaleFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeCode = prefs.getString(_localeKey);
      if (localeCode != null) {
        _locale = Locale(localeCode);
        notifyListeners();
      }
    } catch (e) {
      // Default to English if error
      _locale = const Locale('en');
    }
  }

  /// Set locale and save to storage
  Future<void> setLocale(Locale locale) async {
    if (_locale?.languageCode == locale.languageCode) {
      return; // Already set
    }

    _locale = locale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
    } catch (e) {
      // Ignore storage errors, locale is still set
    }
  }

  /// Load locale from driver profile
  Future<void> loadLocaleFromProfile(DriverProvider driverProvider) async {
    final driver = driverProvider.driver;
    if (driver?.language != null) {
      final locale = _getLocaleFromLanguageCode(driver!.language!);
      if (locale != null && _locale?.languageCode != locale.languageCode) {
        await setLocale(locale);
      }
    } else {
      // Default to English if no language preference
      if (_locale == null || _locale!.languageCode != 'en') {
        await setLocale(const Locale('en'));
      }
    }
  }

  /// Convert language code from driver profile to Locale
  Locale? _getLocaleFromLanguageCode(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'en':
        return const Locale('en');
      case 'hi':
        return const Locale('hi');
      case 'mr':
        return const Locale('mr');
      default:
        return const Locale('en'); // Default to English
    }
  }

  /// Update locale when language changes in profile
  void updateLocaleFromLanguageCode(String languageCode) {
    final locale = _getLocaleFromLanguageCode(languageCode);
    if (locale != null) {
      setLocale(locale);
    }
  }
}
