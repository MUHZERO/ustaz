import 'package:get/get.dart';
import 'homework_controller.dart';

class HomeworkBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => HomeworkController(Get.find()));
}
