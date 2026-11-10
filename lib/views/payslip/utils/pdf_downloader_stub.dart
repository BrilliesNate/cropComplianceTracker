import 'dart:typed_data';

/// No-op fallback for unsupported platforms.
Future<void> triggerPdfDownload(Uint8List bytes, String name) async {}
Future<void> openPdfInBrowser(Uint8List bytes) async {}
Future<void> triggerFileDownload(
    Uint8List bytes, String name, String mime) async {}
