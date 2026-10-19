import 'package:get/get.dart';
import '../home/home_binding.dart';
import '../homework/homework_binding.dart';
import '../results/results_binding.dart';
import 'shell_controller.dart';

class ShellBinding extends Bindings {
  @override
  void dependencies() {
    HomeBinding().dependencies();
    ResultsBinding().dependencies();
    HomeworkBinding().dependencies();
    Get.lazyPut(ShellController.new);
  }
}
