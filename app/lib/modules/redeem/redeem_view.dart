import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/base/base_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/form_error_text.dart';
import 'redeem_controller.dart';

class RedeemView extends GetView<RedeemController> {
  const RedeemView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('redeem.title'.tr)),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Obx(() {
          final category = controller.category.value;
          if (category != null) {
            return Column(
              children: [
                const Icon(Icons.check_circle_outline, size: 64),
                const SizedBox(height: 16),
                Text(
                  'redeem.success'.trParams({'name': category.name}),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'redeem.open_category'.tr,
                  onPressed: () =>
                      Get.offNamed(AppRoutes.category, arguments: category.id),
                ),
              ],
            );
          }
          return Form(
            key: controller.formKey,
            child: Column(
              children: [
                AppTextField(
                  controller: controller.code,
                  label: 'redeem.code'.tr,
                  validator: Validators.required,
                  errorText: controller.fieldErrors['code'],
                ),
                FormErrorText(controller: controller),
                const SizedBox(height: 16),
                AppButton(
                  label: 'redeem.submit'.tr,
                  onPressed: controller.status.value == ViewStatus.loading
                      ? null
                      : controller.redeem,
                ),
              ],
            ),
          );
        }),
      ),
    ),
  );
}
