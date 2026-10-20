import 'package:get/get.dart';
import '../../core/base/base_controller.dart';
import '../../data/models/student.dart';
import '../../data/repositories/content_repository.dart';

class HomeController extends BaseController {
  HomeController(this._repository, {Rxn<Student>? student})
    : student = student ?? Rxn<Student>();
  final ContentRepository _repository;
  final data = Rxn<HomeData>();

  /// The signed-in student, for the greeting.
  final Rxn<Student> student;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() => run(() async => data.value = await _repository.home());
}
