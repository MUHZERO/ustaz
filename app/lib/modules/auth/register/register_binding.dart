import 'package:get/get.dart';
import '../../../data/repositories/auth_repository.dart';
import 'register_controller.dart';

class RegisterBinding extends Bindings {
  @override
  void dependencies() =>
      Get.lazyPut(() => RegisterController(Get.find<AuthRepository>()));
}
