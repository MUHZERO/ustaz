import 'package:get/get.dart';

import '../../core/base/base_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../data/models/attempt.dart';
import '../../data/models/exam_card.dart';
import '../../data/repositories/content_repository.dart';

class CategoryController extends BaseController {
  CategoryController(this._repository, this.categoryId);

  final ContentRepository _repository;
  final int categoryId;
  final data = Rxn<CategoryDetail>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() =>
      run(() async => data.value = await _repository.category(categoryId));

  /// Submitted exam → its result; open exam → the assessment player.
  Future<void> openExam(ExamCard exam) async {
    final attempt = exam.attempt;
    if (attempt != null && attempt.status == 'submitted') {
      await Get.toNamed(
        AppRoutes.assessmentResult,
        arguments: {'attemptId': attempt.id, 'kind': AssessmentKind.exam},
      );
      return;
    }
    if (exam.isLocked || exam.state != ExamState.open) return;
    await Get.toNamed(AppRoutes.assessment, arguments: exam.id);
    await load();
  }
}
