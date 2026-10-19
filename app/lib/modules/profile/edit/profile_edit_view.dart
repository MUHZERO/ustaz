import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/form_error_text.dart';
import 'profile_edit_controller.dart';

class ProfileEditView extends GetView<ProfileEditController> {
  const ProfileEditView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('profile.edit'.tr)),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Obx(
          () => Form(
            key: controller.formKey,
            child: Column(
              children: [
                AppTextField(
                  controller: controller.name,
                  label: 'auth.name'.tr,
                  validator: Validators.required,
                  errorText: controller.fieldErrors['name'],
                ),
                AppTextField(
                  controller: controller.parentPhone,
                  label: 'auth.parent_phone'.tr,
                  validator: Validators.optionalPhone,
                  errorText: controller.fieldErrors['parent_phone'],
                  keyboardType: TextInputType.phone,
                ),
                FormErrorText(controller: controller),
                const SizedBox(height: 16),
                AppButton(
                  label: 'profile.save'.tr,
                  onPressed: controller.status.value == ViewStatus.loading
                      ? null
                      : controller.save,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
