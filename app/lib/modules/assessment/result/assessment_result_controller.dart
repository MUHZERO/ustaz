import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/models/attempt.dart';
import '../../../data/models/result.dart';
import '../../../data/repositories/assessment_repository.dart';

class AssessmentResultController extends BaseController {
  AssessmentResultController(
    this._repository, {
    required this.attemptId,
    required this.kind,
    this.initial,
  });

  final AssessmentRepository _repository;
  final int attemptId;
  final AssessmentKind kind;
  final AssessmentResult? initial;
  final result = Rxn<AssessmentResult>();

  /// Review requests are for exams only, and once per attempt.
  bool get canRequestReview =>
      kind == AssessmentKind.exam &&
      result.value != null &&
      result.value!.reviewRequest == null;

  @override
  void onInit() {
    super.onInit();
    if (initial != null) {
      result.value = initial;
    } else {
      load();
    }
  }

  Future<void> load() =>
      run(() async => result.value = await _repository.result(attemptId));

  Future<void> requestReview(String note) => run(
    () async =>
        result.value = await _repository.requestReview(attemptId, note.trim()),
  );
}
