import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'core/config/app_config.dart';
import 'app_bootstrap.dart';
import 'core/i18n/translations.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  bootstrapDependencies();
  runApp(const UstazApp());
}

class UstazApp extends StatelessWidget {
  const UstazApp({super.key});

  @override
  Widget build(BuildContext context) => GetMaterialApp(
    title: AppConfig.appName,
    debugShowCheckedModeBanner: false,
    translations: AppTranslations(),
    locale: Get.find<SettingsService>().locale,
    fallbackLocale: const Locale('ar'),
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: Get.find<SettingsService>().themeMode,
    initialRoute: AppRoutes.splash,
    getPages: AppPages.routes,
  );
}
