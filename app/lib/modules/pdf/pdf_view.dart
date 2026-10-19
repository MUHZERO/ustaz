import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/base/state_view.dart';
import 'pdf_controller.dart';

class PdfView extends GetView<PdfController> {
  const PdfView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(controller.title)),
    body: StateView(
      controller: controller,
      onRetry: controller.load,
      builder: (_) => Obx(() {
        final source = controller.source.value;
        if (source == null) return const SizedBox.shrink();
        return Stack(
          children: [
            Positioned.fill(
              child: source.view(
                onPageChanged: (page) => controller.page.value = page,
              ),
            ),
            PositionedDirectional(
              bottom: 16,
              start: 0,
              end: 0,
              child: Center(
                child: Chip(
                  label: Obx(
                    () => Text(
                      'pdf.page_of'.trParams({
                        'page': '${controller.page.value}',
                        'count': '${controller.pageCount.value}',
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    ),
  );
}
