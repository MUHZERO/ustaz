import 'package:get/get.dart';
import 'device_pending_controller.dart';

class DevicePendingBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(DevicePendingController.new);
}
