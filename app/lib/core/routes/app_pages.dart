import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_routes.dart';
import '../../modules/auth/device_pending/device_pending_binding.dart';
import '../../modules/auth/device_pending/device_pending_view.dart';
import '../../modules/auth/login/login_binding.dart';
import '../../modules/auth/login/login_view.dart';
import '../../modules/auth/register/register_binding.dart';
import '../../modules/auth/register/register_view.dart';
import '../../modules/category/category_binding.dart';
import '../../modules/category/category_view.dart';
import '../../modules/lecture/lecture_binding.dart';
import '../../modules/lecture/lecture_view.dart';
import '../../modules/notifications/notifications_binding.dart';
import '../../modules/notifications/notifications_view.dart';
import '../../modules/player/player_binding.dart';
import '../../modules/player/player_view.dart';
import '../../modules/profile/edit/profile_edit_binding.dart';
import '../../modules/profile/edit/profile_edit_view.dart';
import '../../modules/redeem/redeem_binding.dart';
import '../../modules/redeem/redeem_view.dart';
import '../../modules/splash/splash_binding.dart';
import '../../modules/splash/splash_view.dart';
import '../../modules/shell/shell_binding.dart';
import '../../modules/shell/shell_view.dart';

class AppPages {
  const AppPages._();
  static final routes = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.splash,
      page: SplashView.new,
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: LoginView.new,
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: RegisterView.new,
      binding: RegisterBinding(),
    ),
    GetPage(
      name: AppRoutes.devicePending,
      page: DevicePendingView.new,
      binding: DevicePendingBinding(),
    ),
    GetPage(name: AppRoutes.home, page: ShellView.new, binding: ShellBinding()),
    GetPage(
      name: AppRoutes.category,
      page: CategoryView.new,
      binding: CategoryBinding(),
    ),
    GetPage(
      name: AppRoutes.lecture,
      page: LectureView.new,
      binding: LectureBinding(),
    ),
    GetPage(
      name: AppRoutes.player,
      page: PlayerView.new,
      binding: PlayerBinding(),
    ),
    GetPage(
      name: AppRoutes.redeem,
      page: RedeemView.new,
      binding: RedeemBinding(),
    ),
    GetPage(
      name: AppRoutes.profileEdit,
      page: ProfileEditView.new,
      binding: ProfileEditBinding(),
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => Scaffold(
        appBar: AppBar(title: Text('shell.notifications'.tr)),
        body: const NotificationsView(),
      ),
      binding: NotificationsBinding(),
    ),
  ];
}
