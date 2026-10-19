import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/models/review_item.dart';
import '../../../data/repositories/assessment_repository.dart';

class AssessmentReviewController extends BaseController {
  AssessmentReviewController(this._repository, this.attemptId);

  final AssessmentRepository _repository;
  final int attemptId;
  final items = <ReviewItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() =>
      run(() async => items.assignAll(await _repository.review(attemptId)));
}
