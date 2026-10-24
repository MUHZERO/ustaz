import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';

class DevicePendingController extends GetxController {
  /// Back to the login screen underneath, phone still filled in. Opening a new
  /// login route instead would reuse its LoginController while the old route's
  /// disposal closes that controller's text fields.
  void retryLogin() =>
      Get.until((route) => route.settings.name == AppRoutes.login);
}
