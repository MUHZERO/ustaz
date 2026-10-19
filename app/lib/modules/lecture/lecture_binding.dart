import 'package:get/get.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/content_repository.dart';
import 'lecture_controller.dart';

class LectureBinding extends Bindings {
  @override
  void dependencies() {
    final arguments = Get.arguments;
    final id = arguments is Map ? arguments['id'] as int : arguments as int;
    Get.lazyPut(
      () => LectureController(
        Get.find<ContentRepository>(),
        id,
        studentForWatermark: () => Get.find<AuthRepository>().me(),
      ),
    );
  }
}
