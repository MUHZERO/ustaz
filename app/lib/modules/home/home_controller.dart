import 'package:get/get.dart';
import '../../core/base/base_controller.dart';
import '../../data/repositories/content_repository.dart';

class HomeController extends BaseController {
  HomeController(this._repository);
  final ContentRepository _repository;
  final data = Rxn<HomeData>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() => run(() async => data.value = await _repository.home());
}
