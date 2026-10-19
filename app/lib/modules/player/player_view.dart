import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/base/state_view.dart';
import '../../core/security/watermark.dart';
import 'player_controller.dart';

class PlayerView extends GetView<PlayerController> {
  const PlayerView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('player.title'.tr)),
    body: StateView(
      controller: controller,
      onRetry: controller.initialize,
      builder: (_) => Obx(() {
        final source = controller.source.value;
        if (source == null) return const SizedBox.shrink();
        final arguments = Get.arguments as Map;
        return Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Watermark(
              studentName: arguments['studentName'] as String? ?? '',
              studentPhone: arguments['studentPhone'] as String? ?? '',
              child: source.view(),
            ),
          ),
        );
      }),
    ),
  );
}
