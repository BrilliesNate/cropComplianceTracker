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

Future<void> openPdfInBrowser(Uint8List bytes) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
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
