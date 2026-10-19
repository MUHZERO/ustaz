import 'package:get/get.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/network/token_store.dart';
import 'splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(
      SplashController(Get.find<TokenStore>(), Get.find<AuthRepository>()),
    );
  }
}
