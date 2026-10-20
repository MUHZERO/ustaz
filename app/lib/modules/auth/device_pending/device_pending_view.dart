import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import 'device_pending_controller.dart';

class DevicePendingView extends GetView<DevicePendingController> {
  const DevicePendingView({super.key});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 168,
                  height: 168,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.primary.withValues(alpha: 0.08),
                        ),
                      ),
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.primary.withValues(alpha: 0.14),
                        ),
                      ),
                      Icon(
                        Icons.phone_android_rounded,
                        size: 64,
                        color: colors.primary,
                      ),
                      PositionedDirectional(
                        end: 28,
                        bottom: 30,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.secondary,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 4,
                            ),
                          ),
                          child: Icon(
                            Icons.hourglass_top_rounded,
                            size: 22,
                            color: colors.onSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'auth.waiting_title'.tr,
                  style: text.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'auth.waiting_body'.tr,
                  textAlign: TextAlign.center,
                  style: text.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppButton(
                  label: 'auth.retry_login'.tr,
                  icon: Icons.refresh_rounded,
                  onPressed: controller.retryLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
