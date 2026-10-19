import 'package:get/get.dart';

import '../../../data/models/attempt.dart';
import '../../../data/models/result.dart';
import '../../../data/repositories/assessment_repository.dart';
import 'assessment_result_controller.dart';

class AssessmentResultBinding extends Bindings {
  @override
  void dependencies() {
    final arguments = Get.arguments as Map;
    Get.lazyPut(
      () => AssessmentResultController(
        Get.find<AssessmentRepository>(),
        attemptId: arguments['attemptId'] as int,
        kind: arguments['kind'] as AssessmentKind,
        initial: arguments['result'] as AssessmentResult?,
      ),
    );
  }
}
