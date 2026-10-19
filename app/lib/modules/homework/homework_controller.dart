import 'package:get/get.dart';
import '../../core/base/paged_controller.dart';
import '../../core/routes/app_routes.dart';
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

  /// Submitted homework has no attempt id here, so only open ones are tappable.
  bool canOpen(Homework homework) => homework.status != HomeworkStatus.done;

  Future<void> open(Homework homework) async {
    await Get.toNamed(AppRoutes.assessment, arguments: homework.assessmentId);
    await reload();
  }
}
