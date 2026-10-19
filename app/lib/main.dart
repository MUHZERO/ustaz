import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'core/config/app_config.dart';
import 'core/i18n/translations.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(const UstazApp());
}

class UstazApp extends StatelessWidget {
  const UstazApp({super.key});

  @override
  Widget build(BuildContext context) => GetMaterialApp(
    title: AppConfig.appName,
    translations: AppTranslations(),
    locale: const Locale('ar'),
    fallbackLocale: const Locale('ar'),
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: ThemeMode.system,
    initialRoute: AppRoutes.splash,
    getPages: AppPages.routes,
  );
}
