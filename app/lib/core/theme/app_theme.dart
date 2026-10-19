import 'package:flutter/material.dart';
import '../config/app_config.dart';

class AppTheme {
  const AppTheme._();
  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: AppConfig.primaryColor),
    useMaterial3: true,
  );
  static ThemeData get dark => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppConfig.primaryColor,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: AppConfig.darkColor,
    useMaterial3: true,
  );
}
