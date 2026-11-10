import 'dart:io';
import 'dart:typed_data';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

/// Mobile/desktop implementation — saves to temp dir then opens with system viewer.
Future<void> triggerPdfDownload(Uint8List bytes, String name) async {
  final dir = await getTemporaryDirectory();
  // Sanitise filename so it's safe on all platforms
  final safe = name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  final file = File('${dir.path}/$safe');
  await file.writeAsBytes(bytes);
  await OpenFile.open(file.path);
}

Future<void> openPdfInBrowser(Uint8List bytes) async {
  // No browser on mobile — fall back to same open-in-viewer behaviour.
  await triggerPdfDownload(bytes, 'payslip.pdf');
}

/// Generic byte download — saves to temp dir then opens with the system viewer.
Future<void> triggerFileDownload(
    Uint8List bytes, String name, String mime) async {
  final dir = await getTemporaryDirectory();
  final safe = name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  final file = File('${dir.path}/$safe');
  await file.writeAsBytes(bytes);
  await OpenFile.open(file.path);
}
