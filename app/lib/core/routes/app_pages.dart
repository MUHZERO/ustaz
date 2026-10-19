import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_routes.dart';

class AppPages {
  const AppPages._();
  static final routes = <GetPage<dynamic>>[
    GetPage(name: AppRoutes.splash, page: _SplashPlaceholder.new),
  ];
}

class _SplashPlaceholder extends StatelessWidget {
  const _SplashPlaceholder();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('...')));
}
