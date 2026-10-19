import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';

class DevicePendingController extends GetxController {
  void retryLogin() => Get.offAllNamed(AppRoutes.login);
}
