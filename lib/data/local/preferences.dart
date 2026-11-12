import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias persistentes: idioma, narración y ambiente.
class AppPreferences extends ChangeNotifier {
  AppPreferences._(this._store, this._deviceLanguage);

  static const String _kLanguage = 'language';
  static const String _kNarration = 'narrationEnabled';
  static const String _kAmbience = 'ambienceEnabled';
  static const List<String> supportedLanguages = ['es', 'en'];

  final SharedPreferences _store;
  final String _deviceLanguage;

  /// [deviceLocale] es el idioma del dispositivo en la primera apertura.
  static Future<AppPreferences> load({required Locale deviceLocale}) async {
    final store = await SharedPreferences.getInstance();
    return AppPreferences._(store, deviceLocale.languageCode);
  }

  /// Idioma elegido; si no hay elección, el del dispositivo cuando es
  /// español o inglés, y español para los demás.
  String get languageCode {
    final saved = _store.getString(_kLanguage);
    if (saved != null && supportedLanguages.contains(saved)) return saved;
    return _deviceLanguage == 'en' ? 'en' : 'es';
  }

  bool get narrationEnabled => _store.getBool(_kNarration) ?? true;
  bool get ambienceEnabled => _store.getBool(_kAmbience) ?? true;

  Future<void> setLanguage(String code) async {
    assert(supportedLanguages.contains(code));
    if (code == languageCode && _store.containsKey(_kLanguage)) return;
    await _store.setString(_kLanguage, code);
    notifyListeners();
  }

  Future<void> setNarrationEnabled(bool value) async {
    await _store.setBool(_kNarration, value);
    notifyListeners();
  }

  Future<void> setAmbienceEnabled(bool value) async {
    await _store.setBool(_kAmbience, value);
    notifyListeners();
  }
}
