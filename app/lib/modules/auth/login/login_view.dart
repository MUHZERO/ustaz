import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/auth_layout.dart';
import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Obx(
      () => Form(
        key: controller.formKey,
        child: AuthLayout(
          title: 'auth.welcome_title'.tr,
          subtitle: 'auth.welcome_body'.tr,
          fields: [
            AppTextField(
              controller: controller.phone,
              label: 'auth.phone'.tr,
              icon: Icons.phone_iphone_rounded,
              validator: Validators.phone,
              errorText: controller.fieldErrors['phone'],
              keyboardType: TextInputType.phone,
            ),
            AppTextField(
              controller: controller.password,
              label: 'auth.password'.tr,
              icon: Icons.lock_outline_rounded,
              validator: Validators.password,
              errorText: controller.fieldErrors['password'],
              obscureText: true,
            ),
          ],
          actions: [
            AppButton(label: 'auth.login'.tr, onPressed: controller.login),
            AuthSwitchLink(
              question: 'auth.no_account'.tr,
              action: 'auth.register'.tr,
              onPressed: () => Get.toNamed(AppRoutes.register),
            ),
          ],
        ),
      ),
    ),
  );
}
