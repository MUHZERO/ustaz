import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/base/base_controller.dart';
import '../../core/formatters.dart';
import '../../core/routes/app_routes.dart';
import '../../data/models/student.dart';
import '../../data/models/subscription.dart';
import '../../data/repositories/access_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../services/auth_service.dart';
import '../../services/settings_service.dart';

class ProfileController extends BaseController {
  ProfileController(this._auth, this._access, this._session, this.settings);
  final AuthRepository _auth;
  final AccessRepository _access;
  final AuthService _session;
  final SettingsService settings;
  final subscriptions = <Subscription>[].obs;
  late final language = settings.locale.languageCode.obs;
  late final themeMode = settings.themeMode.obs;

  Rxn<Student> get student => _session.current;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() => run(() async {
    final (me, items) = await (_auth.me(), _access.subscriptions()).wait;
    _session.setCurrent(me);
    subscriptions.assignAll(items);
  });

  static String endLabel(Subscription subscription) =>
      subscription.endsAt == null
      ? 'profile.lifetime'.tr
      : 'profile.ends_at'.trParams({
          'date': Formatters.date(subscription.endsAt!),
        });

  void setLanguage(String code) {
    language.value = code;
    settings.setLanguage(code);
  }

  void setDarkMode(bool dark) {
    themeMode.value = dark ? ThemeMode.dark : ThemeMode.light;
    settings.setThemeMode(themeMode.value);
  }

  Future<void> logout() async {
    try {
      await _auth.logout();
    } catch (_) {
      // The token is cleared locally even when the server call fails.
    }
    _session.clearCurrent();
    Get.offAllNamed(AppRoutes.login);
  }
}
