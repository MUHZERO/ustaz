import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/base/base_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/tinted_icon.dart';
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Obx(() {
          final category = controller.category.value;
          if (category != null) {
            return Column(
              children: [
                const SizedBox(height: AppSpacing.xxl),
                const TintedIcon(
                  icon: Icons.verified_rounded,
                  color: AppColors.success,
                  size: 96,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'redeem.success'.trParams({'name': category.name}),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
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
                const SizedBox(height: AppSpacing.xl),
                TintedIcon(
                  icon: Icons.vpn_key_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 88,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'category.locked_message'.tr,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  controller: controller.code,
                  label: 'redeem.code'.tr,
                  icon: Icons.confirmation_number_outlined,
                  validator: Validators.required,
                  errorText: controller.fieldErrors['code'],
                ),
                FormErrorText(controller: controller),
                const SizedBox(height: AppSpacing.lg),
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
