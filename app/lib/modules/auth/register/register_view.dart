import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import 'register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('auth.register'.tr)),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Obx(
          () => Form(
            key: controller.formKey,
            child: ListView(
              children: [
                AppTextField(
                  controller: controller.name,
                  label: 'auth.name'.tr,
                  validator: Validators.required,
                  errorText: controller.fieldErrors['name'],
                ),
                AppTextField(
                  controller: controller.phone,
                  label: 'auth.phone'.tr,
                  validator: Validators.phone,
                  errorText: controller.fieldErrors['phone'],
                  keyboardType: TextInputType.phone,
                ),
                AppTextField(
                  controller: controller.parentPhone,
                  label: 'auth.parent_phone'.tr,
                  errorText: controller.fieldErrors['parent_phone'],
                  keyboardType: TextInputType.phone,
                ),
                AppTextField(
                  controller: controller.password,
                  label: 'auth.password'.tr,
                  validator: Validators.password,
                  errorText: controller.fieldErrors['password'],
                  obscureText: true,
                ),
                AppTextField(
                  controller: controller.passwordConfirmation,
                  label: 'auth.password_confirmation'.tr,
                  validator: (value) => value == controller.password.text
                      ? null
                      : 'validation.password_confirmation'.tr,
                  errorText: controller.fieldErrors['password_confirmation'],
                  obscureText: true,
                ),
                DropdownButtonFormField<int>(
                  initialValue: controller.selectedLevelId.value,
                  decoration: InputDecoration(
                    labelText: 'auth.level'.tr,
                    errorText: controller.fieldErrors['level_id'],
                  ),
                  items: controller.levels
                      .map(
                        (level) => DropdownMenuItem(
                          value: level.id,
                          child: Text(level.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      controller.selectedLevelId.value = value,
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'auth.register'.tr,
                  onPressed: controller.register,
                ),
                TextButton(
                  onPressed: Get.back,
                  child: Text('auth.have_account'.tr),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
