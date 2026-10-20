import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/auth_layout.dart';
import 'register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: SafeArea(
      top: false,
      child: Obx(
        () => Form(
          key: controller.formKey,
          child: AuthLayout(
            title: 'auth.register_title'.tr,
            subtitle: 'auth.register_body'.tr,
            fields: [
              AppTextField(
                controller: controller.name,
                label: 'auth.name'.tr,
                icon: Icons.person_outline_rounded,
                validator: Validators.required,
                errorText: controller.fieldErrors['name'],
              ),
              AppTextField(
                controller: controller.phone,
                label: 'auth.phone'.tr,
                icon: Icons.phone_iphone_rounded,
                validator: Validators.phone,
                errorText: controller.fieldErrors['phone'],
                keyboardType: TextInputType.phone,
              ),
              AppTextField(
                controller: controller.parentPhone,
                label: 'auth.parent_phone'.tr,
                icon: Icons.family_restroom_rounded,
                errorText: controller.fieldErrors['parent_phone'],
                keyboardType: TextInputType.phone,
              ),
              DropdownButtonFormField<int>(
                initialValue: controller.selectedLevelId.value,
                decoration: InputDecoration(
                  labelText: 'auth.level'.tr,
                  prefixIcon: const Icon(Icons.school_outlined),
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
                onChanged: (value) => controller.selectedLevelId.value = value,
              ),
              AppTextField(
                controller: controller.password,
                label: 'auth.password'.tr,
                icon: Icons.lock_outline_rounded,
                validator: Validators.password,
                errorText: controller.fieldErrors['password'],
                obscureText: true,
              ),
              AppTextField(
                controller: controller.passwordConfirmation,
                label: 'auth.password_confirmation'.tr,
                icon: Icons.lock_outline_rounded,
                validator: (value) => value == controller.password.text
                    ? null
                    : 'validation.password_confirmation'.tr,
                errorText: controller.fieldErrors['password_confirmation'],
                obscureText: true,
              ),
            ],
            actions: [
              AppButton(
                label: 'auth.register'.tr,
                onPressed: controller.register,
              ),
              AuthSwitchLink(
                question: 'auth.have_account'.tr,
                action: 'auth.login'.tr,
                onPressed: Get.back,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
