import 'package:get/get.dart';

import '../../core/base/base_controller.dart';
import 'pdf_source.dart';

class PdfController extends BaseController {
  PdfController({required this.url, required this.title, PdfSource? source})
    : _sourceFactory = source == null ? PdfrxSource.new : (() => source);

  final String url;
  final String title;
  final PdfSource Function() _sourceFactory;
  final source = Rxn<PdfSource>();
  final page = 1.obs;
  final pageCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() => run(() async {
    final next = _sourceFactory();
    pageCount.value = await next.open(Uri.parse(url));
    page.value = 1;
    source.value = next;
  });
}
