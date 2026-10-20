import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_tokens.dart';
import 'base_controller.dart';

class StateView extends StatelessWidget {
  const StateView({
    required this.controller,
    required this.builder,
    this.onRetry,
    super.key,
  });
  final BaseController controller;
  final WidgetBuilder builder;
  final Future<void> Function()? onRetry;
  @override
  Widget build(BuildContext context) => Obx(() {
    switch (controller.status.value) {
      case ViewStatus.loading:
        return const _Skeleton();
      case ViewStatus.error:
        return _Message(
          icon: Icons.cloud_off_rounded,
          title: 'errors.title'.tr,
          body: controller.error ?? '',
          color: Theme.of(context).colorScheme.error,
          action: onRetry == null
              ? null
              : FilledButton.tonalIcon(
                  onPressed: () => onRetry!(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text('retry'.tr),
                ),
        );
      case ViewStatus.empty:
        return _Message(
          icon: Icons.inbox_rounded,
          title: 'empty'.tr,
          body: 'empty_body'.tr,
          color: Theme.of(context).colorScheme.primary,
        );
      case ViewStatus.idle:
      case ViewStatus.success:
        return builder(context);
    }
  });
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    this.action,
  });
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: color),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: text.titleMedium, textAlign: TextAlign.center),
            if (body.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                body,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Grey blocks shaped like a list of cards, pulsing while the page loads.
class _Skeleton extends StatefulWidget {
  const _Skeleton();

  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget block(double height, {double? width}) => Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
    );
    Widget row() => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        children: [
          block(56, width: 56),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                block(14),
                const SizedBox(height: AppSpacing.sm),
                block(12, width: 120),
              ],
            ),
          ),
        ],
      ),
    );
    return FadeTransition(
      opacity: _pulse,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          block(150),
          const SizedBox(height: AppSpacing.xl),
          block(18, width: 140),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < 5; i++) row(),
        ],
      ),
    );
  }
}
