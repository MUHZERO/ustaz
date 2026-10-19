import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/level.dart';
import '../../../data/repositories/auth_repository.dart';

class RegisterController extends BaseController {
  RegisterController(this._repository);
  final AuthRepository _repository;
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final phone = TextEditingController();
  final parentPhone = TextEditingController();
  final password = TextEditingController();
  final passwordConfirmation = TextEditingController();
  final levels = <Level>[].obs;
  final selectedLevelId = RxnInt();

  @override
  void onInit() {
    super.onInit();
    loadLevels();
  }

  Future<void> loadLevels() => run(() async {
    levels.assignAll(await _repository.levels());
  });

  Future<void> register() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (selectedLevelId.value == null) {
      fieldErrors['level_id'] = 'validation.required'.tr;
      return;
    }
    await run(() async {
      await _repository.register(
        RegisterForm(
          name: name.text.trim(),
          phone: phone.text.trim(),
          parentPhone: parentPhone.text.trim(),
          password: password.text,
          passwordConfirmation: passwordConfirmation.text,
          levelId: selectedLevelId.value!,
        ),
      );
      Get.offAllNamed(AppRoutes.home);
    });
  }

  @override
  void onClose() {
    for (final field in [
      name,
      phone,
      parentPhone,
      password,
      passwordConfirmation,
    ]) {
      field.dispose();
    }
    super.onClose();
  }
}
