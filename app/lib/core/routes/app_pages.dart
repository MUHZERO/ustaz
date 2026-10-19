import 'package:get/get.dart';
import 'app_routes.dart';
import '../../modules/auth/device_pending/device_pending_binding.dart';
import '../../modules/auth/device_pending/device_pending_view.dart';
import '../../modules/auth/login/login_binding.dart';
import '../../modules/auth/login/login_view.dart';
import '../../modules/auth/register/register_binding.dart';
import '../../modules/auth/register/register_view.dart';
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
  ];
}
