import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/base/state_view.dart';
import '../../core/formatters.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/tinted_icon.dart';
import '../../data/models/app_notification.dart';
import 'notifications_controller.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) => StateView(
    controller: controller,
    onRetry: controller.load,
    builder: (_) => RefreshIndicator(
      onRefresh: controller.load,
      child: Obx(
        () => ListView.separated(
          key: const Key('notifications-list'),
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: controller.items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm + 2),
          itemBuilder: (context, index) {
            final item = controller.items[index];
            return _NotificationCard(
              item,
              key: ValueKey(item.id),
              onTap: () => controller.open(item),
            );
          },
        ),
      ),
    ),
  );
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard(this.item, {required this.onTap, super.key});
  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final (icon, color) = switch (item.data['route']) {
      'lecture' => (Icons.play_circle_rounded, colors.primary),
      'category' => (Icons.menu_book_rounded, AppColors.success),
      'result' || 'results' => (Icons.insights_rounded, AppColors.warning),
      _ => (Icons.notifications_rounded, colors.primary),
    };
    return Card(
      color: item.isRead
          ? null
          : colors.primaryContainer.withValues(alpha: 0.5),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TintedIcon(icon: icon, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: text.titleSmall?.copyWith(
                              fontWeight: item.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          Formatters.relative(item.createdAt),
                          style: text.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (item.body.isNotEmpty)
                      Text(
                        item.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (!item.isRead)
                Container(
                  key: const Key('unread-dot'),
                  width: 10,
                  height: 10,
                  margin: const EdgeInsetsDirectional.only(
                    start: AppSpacing.sm,
                    top: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
