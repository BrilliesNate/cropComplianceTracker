import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

pw.ThemeData? _theme;

/// Fonts for every generated PDF. The PDF's built-in Helvetica has no dashes
/// (– —), curly apostrophes (’n) and other characters the translations use,
/// so those printed as blanks. Roboto (copied from the Flutter SDK,
/// Apache 2.0 — see assets/fonts/LICENSE-Roboto.txt) has them all.
Future<pw.ThemeData> pdfTheme() async {
  final cached = _theme;
  if (cached != null) return cached;
  final regular =
      pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
  final bold =
      pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
  return _theme = pw.ThemeData.withFont(
      base: regular, bold: bold, italic: regular, boldItalic: bold);
}
