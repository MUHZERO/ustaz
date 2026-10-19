import 'package:get/get.dart';

import '../../data/repositories/content_repository.dart';
import 'category_controller.dart';

class CategoryBinding extends Bindings {
  @override
  void dependencies() {
    final id = Get.arguments as int;
    Get.lazyPut(() => CategoryController(Get.find<ContentRepository>(), id));
  }
}
