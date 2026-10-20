import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../base/paged_controller.dart';
import '../base/state_view.dart';
import '../theme/app_tokens.dart';

/// Pull to refresh, and the next page loads when the list end comes into view.
class PagedList<T> extends StatelessWidget {
  const PagedList({
    required this.controller,
    required this.itemBuilder,
    super.key,
  });
  final PagedController<T> controller;
  final Widget Function(BuildContext context, T item) itemBuilder;

  @override
  Widget build(BuildContext context) => StateView(
    controller: controller,
    onRetry: controller.reload,
    builder: (_) => RefreshIndicator(
      onRefresh: controller.reload,
      child: Obx(() {
        final items = controller.items.toList();
        final hasMore = controller.hasMore;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) => index < items.length
              ? itemBuilder(context, items[index])
              : _MoreIndicator(controller),
        );
      }),
    ),
  );
}

class _MoreIndicator extends StatelessWidget {
  const _MoreIndicator(this.controller);
  final PagedController<dynamic> controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    if (controller.loadMoreFailed.value) {
      return TextButton(
        onPressed: controller.loadMore,
        child: Text('retry'.tr),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.loadMore());
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  });
}
