import 'package:get/get.dart';
import '../../core/base/paged_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../data/models/paged.dart';
import '../../data/models/result.dart';
import '../../data/repositories/assessment_repository.dart';

class ResultsController extends PagedController<ResultEntry> {
  ResultsController(this._repository);
  final AssessmentRepository _repository;

  @override
  Future<Paged<ResultEntry>> fetch(int page) => _repository.myResults(page);

  void open(ResultEntry entry) => Get.toNamed(
    AppRoutes.assessmentResult,
    arguments: {
      'attemptId': entry.result.attemptId,
      'kind': entry.kind,
      'result': entry.result,
    },
  );
}
