import 'package:get/get.dart';
import 'redeem_controller.dart';

class RedeemBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => RedeemController(Get.find()));
}
