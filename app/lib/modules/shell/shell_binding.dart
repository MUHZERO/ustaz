import 'package:get/get.dart';
import '../home/home_binding.dart';
import 'shell_controller.dart';

class ShellBinding extends Bindings {
  @override
  void dependencies() {
    HomeBinding().dependencies();
    Get.lazyPut(ShellController.new);
  }
}
