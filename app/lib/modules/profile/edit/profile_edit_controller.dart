import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../../core/base/base_controller.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../services/auth_service.dart';

class ProfileEditController extends BaseController {
  ProfileEditController(this._repository, this._auth);
  final AuthRepository _repository;
  final AuthService _auth;
  final formKey = GlobalKey<FormState>();
  late final name = TextEditingController(text: _auth.current.value?.name);
  late final parentPhone = TextEditingController(
    text: _auth.current.value?.parentPhone,
  );

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    await run(() async {
      _auth.setCurrent(
        await _repository.updateProfile(
          name: name.text.trim(),
          parentPhone: parentPhone.text.trim(),
        ),
      );
      Get.back();
    });
  }

  @override
  void onClose() {
    name.dispose();
    parentPhone.dispose();
    super.onClose();
  }
}
