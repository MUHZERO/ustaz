import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/app_button.dart';
import 'device_pending_controller.dart';

class DevicePendingView extends GetView<DevicePendingController> {
  const DevicePendingView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'auth.waiting_title'.tr,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text('auth.waiting_body'.tr, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            AppButton(
              label: 'auth.retry_login'.tr,
              onPressed: controller.retryLogin,
            ),
          ],
        ),
      ),
    ),
  );
}
