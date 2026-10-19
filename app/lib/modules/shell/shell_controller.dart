import 'package:get/get.dart';
import '../../services/push_service.dart';

class ShellController extends GetxController {
  ShellController(this._push);
  final PushService _push;
  final selectedIndex = 0.obs;
  void select(int index) => selectedIndex.value = index;

  @override
  void onReady() {
    super.onReady();
    _push.init();
  }
}
