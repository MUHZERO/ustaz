import 'package:get/get.dart';

class ShellController extends GetxController {
  final selectedIndex = 0.obs;
  void select(int index) => selectedIndex.value = index;
}
