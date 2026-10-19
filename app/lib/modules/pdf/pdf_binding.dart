import 'package:get/get.dart';

import 'pdf_controller.dart';

class PdfBinding extends Bindings {
  @override
  void dependencies() {
    final arguments = Get.arguments as Map;
    Get.lazyPut(
      () => PdfController(
        url: arguments['url'] as String,
        title: arguments['title'] as String,
      ),
    );
  }
}
