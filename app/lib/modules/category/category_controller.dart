import 'package:get/get.dart';

import '../../core/base/base_controller.dart';
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
}
