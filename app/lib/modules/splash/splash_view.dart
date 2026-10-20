import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/brand_header.dart';
import 'splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BrandMark(size: 88),
          const SizedBox(height: AppSpacing.lg),
          Text('app_name'.tr, style: Theme.of(context).textTheme.headlineSmall),
          Text(
            'splash'.tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}
