import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Language and theme chosen in the profile, kept across launches.
class SettingsService extends GetxService {
  SettingsService(this._storage);
  static const _languageKey = 'language';
  static const _themeKey = 'theme_mode';
  static const languages = ['ar', 'en'];
  final GetStorage _storage;

  Locale get locale => Locale(_storage.read<String>(_languageKey) ?? 'ar');

  ThemeMode get themeMode => ThemeMode.values.firstWhere(
    (mode) => mode.name == _storage.read<String>(_themeKey),
    orElse: () => ThemeMode.system,
  );

  /// Rebuilds the whole app from its first route so every translated string
  /// and the text direction follow. `Get.updateLocale` reassembles instead,
  /// which never settles under widget tests.
  void setLanguage(String code) {
    _storage.write(_languageKey, code);
    Get.locale = Locale(code);
    Get.rootController.restartApp();
  }

  void setThemeMode(ThemeMode mode) {
    _storage.write(_themeKey, mode.name);
    Get.changeThemeMode(mode);
  }
}
