import 'package:get/get.dart';

import '../../../data/repositories/assessment_repository.dart';
import 'assessment_player_controller.dart';
import 'attempt_store.dart';

class AssessmentPlayerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => AssessmentPlayerController(
        Get.find<AssessmentRepository>(),
        Get.find<AttemptStore>(),
        Get.arguments as int,
      ),
    );
  }
}
