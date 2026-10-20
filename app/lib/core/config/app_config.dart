import 'package:flutter/material.dart';
import 'env.dart';

/// Every client-specific value: rebranding the app starts here.
class AppConfig {
  const AppConfig._();
  static const appName = 'Ustaz';
  static const apiUrl = Env.apiUrl;
  static const fontFamily = 'Cairo';
  static const primaryColor = Color(0xFF4338CA);
  static const secondaryColor = Color(0xFFF59E0B);
  static const lightBackground = Color(0xFFF6F7FB);
  static const darkBackground = Color(0xFF0F1222);
}
