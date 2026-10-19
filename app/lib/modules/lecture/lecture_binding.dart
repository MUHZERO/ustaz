import 'package:get/get.dart';

import '../../services/auth_service.dart';
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
        studentForWatermark: () async {
          return Get.find<AuthService>().current.value ??
              (throw StateError('Current student is unavailable'));
        },
      ),
    );
  }
}
