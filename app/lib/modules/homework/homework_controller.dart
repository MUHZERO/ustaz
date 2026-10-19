import 'package:get/get.dart';
import '../../core/base/paged_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../data/models/attempt.dart';
import '../../data/models/homework.dart';
import '../../data/models/paged.dart';
import '../../data/repositories/assessment_repository.dart';

/// `/me/homework` is not paginated: it is served as a single page.
class HomeworkController extends PagedController<Homework> {
  HomeworkController(this._repository);
  final AssessmentRepository _repository;

  @override
  Future<Paged<Homework>> fetch(int page) async =>
      Paged.single(await _repository.myHomework());

  /// Done homework opens its result; anything else opens the player.
  Future<void> open(Homework homework) async {
    if (homework.status == HomeworkStatus.done) {
      await Get.toNamed(
        AppRoutes.assessmentResult,
        arguments: {
          'attemptId': homework.attemptId,
          'kind': AssessmentKind.homework,
        },
      );
      return;
    }
    await Get.toNamed(AppRoutes.assessment, arguments: homework.assessmentId);
    await reload();
  }
}
