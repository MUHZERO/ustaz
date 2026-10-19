import 'package:get/get.dart';
import '../home/home_binding.dart';
import '../notifications/notifications_binding.dart';
import '../profile/profile_binding.dart';
import 'shell_controller.dart';

class ShellBinding extends Bindings {
  @override
  void dependencies() {
    HomeBinding().dependencies();
    ProfileBinding().dependencies();
    NotificationsBinding().dependencies();
    Get.lazyPut(() => ShellController(Get.find()));
  }
}
