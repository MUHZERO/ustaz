import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ustaz/core/i18n/translations.dart';
import 'package:ustaz/modules/pdf/pdf_controller.dart';
import 'package:ustaz/modules/pdf/pdf_source.dart';
import 'package:ustaz/modules/pdf/pdf_view.dart';

const _signedUrl = 'https://cdn.test/papers/1.pdf?expires=1&signature=abc';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  testWidgets('opens pdf from signed url', (tester) async {
    final source = _FakeSource();
    await _pump(
      tester,
      PdfController(url: _signedUrl, title: 'Paper', source: source),
    );
    await tester.pumpAndSettle();

    expect(source.opened, Uri.parse(_signedUrl));
    expect(find.text('Paper'), findsOneWidget);
    expect(find.text('Page 1 of 3'), findsOneWidget);

    source.onPageChanged!(2);
    await tester.pump();
    expect(find.text('Page 2 of 3'), findsOneWidget);
  });

  testWidgets('shows retry on load error', (tester) async {
    final source = _FakeSource()..fail = true;
    await _pump(
      tester,
      PdfController(url: _signedUrl, title: 'Paper', source: source),
    );
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('pdf-page'), findsNothing);

    source.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('pdf-page'), findsOneWidget);
  });
}

Future<void> _pump(WidgetTester tester, PdfController controller) {
  Get.put(controller);
  return tester.pumpWidget(
    GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('en'),
      home: const PdfView(),
    ),
  );
}

class _FakeSource implements PdfSource {
  Uri? opened;
  bool fail = false;
  ValueChanged<int>? onPageChanged;

  @override
  Future<int> open(Uri uri) async {
    opened = uri;
    if (fail) throw Exception('load failed');
    return 3;
  }

  @override
  Widget view({required ValueChanged<int> onPageChanged}) {
    this.onPageChanged = onPageChanged;
    return const Text('pdf-page');
  }
}
