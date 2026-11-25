import 'dart:html' as html;
import 'dart:typed_data';

/// Web implementation — uses dart:html blob + anchor download.
Future<void> triggerPdfDownload(Uint8List bytes, String name) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', name)
    ..style.display = 'none';
  html.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  Future.delayed(
      const Duration(seconds: 30), () => html.Url.revokeObjectUrl(url));
}

/// Opens the PDF in a new tab. Browsers often block that tab (the PDF is
/// built first, so it isn't a direct click any more) — then it downloads
/// instead, so the button never silently does nothing.
Future<void> openPdfInBrowser(Uint8List bytes, [String? name]) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  var opened = false;
  try {
    final w = html.window.open(url, '_blank');
    opened = w.closed != true;
  } catch (_) {
    opened = false;
  }
  if (!opened) {
    html.Url.revokeObjectUrl(url);
    await triggerPdfDownload(bytes, name ?? 'payslip.pdf'); // l10n-ignore: file name fallback
    return;
  }
  Future.delayed(
      const Duration(minutes: 2), () => html.Url.revokeObjectUrl(url));
}

/// Generic byte download with an explicit MIME type (ZIP, XLSX, …).
Future<void> triggerFileDownload(
    Uint8List bytes, String name, String mime) async {
  final blob = html.Blob([bytes], mime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', name)
    ..style.display = 'none';
  html.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  Future.delayed(
      const Duration(seconds: 30), () => html.Url.revokeObjectUrl(url));
}
