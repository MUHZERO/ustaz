import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../services/auth_service.dart';

class LoginController extends BaseController {
  LoginController(this._repository);
  final AuthRepository _repository;
  final formKey = GlobalKey<FormState>();
  final phone = TextEditingController();
  final password = TextEditingController();

  Future<void> login() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    await run(() async {
      try {
        final student = await _repository.login(
          phone.text.trim(),
          password.text,
        );
        Get.find<AuthService>().setCurrent(student);
        Get.offAllNamed(AppRoutes.home);
      } on ApiException catch (error) {
        if (error.code == 'device_pending') {
          Get.toNamed(AppRoutes.devicePending);
          return;
        }
        rethrow;
      }
    });
  }

  @override
  void onClose() {
    phone.dispose();
    password.dispose();
    super.onClose();
  }
}
