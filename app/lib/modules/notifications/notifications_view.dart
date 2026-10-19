import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/base/state_view.dart';
import '../../core/formatters.dart';
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
          itemCount: controller.items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = controller.items[index];
            return ListTile(
              key: ValueKey(item.id),
              leading: Icon(
                item.isRead
                    ? Icons.notifications_none
                    : Icons.notifications_active,
                color: item.isRead
                    ? null
                    : Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                item.title,
                style: TextStyle(
                  fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Text(
                [
                  if (item.body.isNotEmpty) item.body,
                  Formatters.date(item.createdAt),
                ].join('\n'),
              ),
              onTap: () => controller.open(item),
            );
          },
        ),
      ),
    ),
  );
}
