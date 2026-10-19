import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('auth.login'.tr)),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Obx(
          () => Form(
            key: controller.formKey,
            child: Column(
              children: [
                AppTextField(
                  controller: controller.phone,
                  label: 'auth.phone'.tr,
                  validator: Validators.phone,
                  errorText: controller.fieldErrors['phone'],
                  keyboardType: TextInputType.phone,
                ),
                AppTextField(
                  controller: controller.password,
                  label: 'auth.password'.tr,
                  validator: Validators.password,
                  errorText: controller.fieldErrors['password'],
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                AppButton(label: 'auth.login'.tr, onPressed: controller.login),
                TextButton(
                  onPressed: () => Get.toNamed('/register'),
                  child: Text('auth.no_account'.tr),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
