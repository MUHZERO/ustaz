import 'package:flutter/widgets.dart';
import 'package:pdfrx/pdfrx.dart';

/// Loads and renders one PDF; the seam lets tests run without the native engine.
abstract class PdfSource {
  /// Opens [uri] and returns the page count.
  Future<int> open(Uri uri);
  Widget view({required ValueChanged<int> onPageChanged});
}

class PdfrxSource implements PdfSource {
  PdfDocument? _document;

  @override
  Future<int> open(Uri uri) async {
    await pdfrxFlutterInitialize();
    final document = await PdfDocument.openUri(uri);
    _document = document;
    return document.pages.length;
  }

  @override
  Widget view({required ValueChanged<int> onPageChanged}) => PdfViewer(
    // The viewer owns the document from here and disposes it with itself.
    PdfDocumentRefDirect(_document!),
    params: PdfViewerParams(
      onPageChanged: (page) {
        if (page != null) onPageChanged(page);
      },
    ),
  );
}
