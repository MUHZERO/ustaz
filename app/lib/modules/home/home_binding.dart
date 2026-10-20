import 'package:get/get.dart';
import '../../services/auth_service.dart';
import 'home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(
    () => HomeController(Get.find(), student: Get.find<AuthService>().current),
  );
}
