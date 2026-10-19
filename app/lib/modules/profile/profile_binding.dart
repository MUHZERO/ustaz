import 'package:get/get.dart';
import 'profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(
    () => ProfileController(Get.find(), Get.find(), Get.find(), Get.find()),
  );
}
