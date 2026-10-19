import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
        return const Center(child: CircularProgressIndicator());
      case ViewStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(controller.error ?? ''),
              if (onRetry != null)
                TextButton(
                  onPressed: () => onRetry!(),
                  child: Text('retry'.tr),
                ),
            ],
          ),
        );
      case ViewStatus.empty:
        return Center(child: Text('empty'.tr));
      case ViewStatus.idle:
      case ViewStatus.success:
        return builder(context);
    }
  });
}
