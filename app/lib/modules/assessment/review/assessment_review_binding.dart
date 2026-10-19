import 'package:get/get.dart';

import '../../../data/repositories/assessment_repository.dart';
import 'assessment_review_controller.dart';

class AssessmentReviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => AssessmentReviewController(
        Get.find<AssessmentRepository>(),
        Get.arguments as int,
      ),
    );
  }
}
