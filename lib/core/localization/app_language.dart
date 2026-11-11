import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_messages.g.dart';

class AppLanguage extends ChangeNotifier {
  static const preferenceKey = 'ff_app_language';
  static const english = Locale('en');
  static const urdu = Locale('ur');
  static const supportedLocales = [english, urdu];

  Locale? _selectedLocale;
  Locale get locale => _selectedLocale ??
      (WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'ur'
          ? urdu
          : english);

  Future<void> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      _selectedLocale = switch (preferences.getString(preferenceKey)) {
        'ur' => urdu,
        'en' => english,
        _ => null,
      };
    } catch (_) {
      _selectedLocale = null;
    }
    notifyListeners();
  }

  Future<void> select(Locale locale) async {
    if (!supportedLocales.contains(locale) || locale == _selectedLocale) return;
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setString(preferenceKey, locale.languageCode)) {
      throw StateError('Could not save language preference.');
    }
    _selectedLocale = locale;
    notifyListeners();
  }
}

extension AppTranslation on BuildContext {
  String tr(String text) {
    if (Localizations.maybeLocaleOf(this)?.languageCode != 'ur') return text;
    return urduMessages[text] ?? text;
  }
}
