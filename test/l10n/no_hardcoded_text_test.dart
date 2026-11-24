// Guards the English / Afrikaans translation:
//  1. No user-facing English typed straight into the app code — every text
//     must come from lib/l10n/app_en.arb (with its Afrikaans in app_af.arb).
//  2. Both languages have exactly the same texts and placeholders.
//
// A line that is genuinely not user-facing (a log message, a Firestore field,
// a brand name) can be marked with `// l10n-ignore: <reason>`.
//
// While the translation is in progress, files not yet done are listed in
// test/l10n/not_yet_translated.txt. The list may only shrink: a listed file
// that is clean fails the test (remove it from the list), and any other file
// with hard-coded text fails too. Same rules as tool/l10n_scan.py.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _exempt = [
  'l10n/', // the translations themselves
  'firebase_options.dart',
  'videoAnimation.dart', // marketing video stage, never shown to users
];

final _skipLine = RegExp(r"^\s*(import|export|part)\s|print\(|debugPrint\(|"
    r"developer\.log|\blog\(|assert\(|RegExp\(|l10n-ignore|"
    r"\.collection\(|\.doc\(|\.where\(|\.orderBy\(|@pragma|"
    r"^\s*//|^\s*\*|^\s*///");

final _logCall = RegExp(r'\b(?:debugPrint|print|_tlog|_log|_dplog)\(');

final _datePattern = RegExp(r'DateFormat(?:\.\w+)?\(\s*$');

final _literal = RegExp(
    r"""(?<![A-Za-z0-9_])r?('(?:[^'\\\n]|\\.)*'|"(?:[^"\\\n]|\\.)*")""");

bool looksLikeUiText(String lit) {
  var s = lit.substring(1, lit.length - 1);
  s = s.replaceAll(RegExp(r'\$\{[^}]*\}|\$[A-Za-z_][A-Za-z0-9_.]*'), 'X');
  s = s.replaceAll(r'\n', ' ').trim();
  bool full(String p) => RegExp('^(?:$p)\$').hasMatch(s);
  if (!RegExp(r'[A-Za-z]{2,}').hasMatch(s)) return false;
  if (RegExp(r'^(https?:|mailto:|tel:|assets/|package:|dart:)').hasMatch(s)) {
    return false;
  }
  if (full(r'[a-z][A-Za-z0-9_]*')) return false; // identifiers
  if (full(r'[A-Z0-9_]+')) return false; // ENUM_VALUES, IPW
  if (full(r'[\w./\-]+\.(dart|png|jpg|webp|svg|json|pdf|csv|xlsx|ttf|otf)')) {
    return false;
  }
  if (full(r'[a-z0-9_]+(/[a-z0-9_{}\-]+)+')) return false; // paths
  if (full(r'/[\w\-/]*')) return false; // routes
  if (s.contains(' ') && RegExp(r'[A-Za-z]{2,}').hasMatch(s)) return true;
  if (full(r'[A-Z][a-z]+[A-Za-z]*[.!?:…]?')) return true;
  if (RegExp(r'[A-Za-z]{2,}[.!?:…]$').hasMatch(s)) return true;
  return false;
}

Map<String, List<String>> scanLib() {
  final found = <String, List<String>>{};
  for (final f in Directory('lib').listSync(recursive: true)) {
    if (f is! File || !f.path.endsWith('.dart')) continue;
    final rel = f.path.replaceAll(r'\', '/').substring('lib/'.length);
    if (_exempt.any((e) => rel.startsWith(e) || rel.endsWith(e))) continue;
    final lines = f.readAsLinesSync();
    var logDepth = 0; // inside a print( / debugPrint( spanning lines
    int parens(String s) => '('.allMatches(s).length - ')'.allMatches(s).length;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final code = line.replaceAll(_literal, "''");
      if (logDepth > 0) {
        logDepth += parens(code);
        continue;
      }
      final log = _logCall.firstMatch(code);
      if (log != null) {
        final depth = 1 + parens(code.substring(log.end));
        if (depth > 0) logDepth = depth;
        continue;
      }
      if (_skipLine.hasMatch(line)) continue;
      for (final m in _literal.allMatches(line)) {
        // Date patterns, e.g. DateFormat('d MMM yyyy').
        if (_datePattern.hasMatch(line.substring(0, m.start))) continue;
        if (looksLikeUiText(m.group(1)!)) {
          found.putIfAbsent(rel, () => []).add('${i + 1}: ${m.group(1)}');
        }
      }
    }
  }
  return found;
}

void main() {
  test('no hard-coded user-facing text outside the translations', () {
    final pending = File('test/l10n/not_yet_translated.txt')
        .readAsLinesSync()
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('#'))
        .toSet();
    final found = scanLib();
    final unexpected = {
      for (final e in found.entries)
        if (!pending.contains(e.key)) e.key: e.value,
    };
    final nowClean = pending.where((f) => !found.containsKey(f)).toList();
    expect(unexpected, isEmpty,
        reason: 'Move these texts into lib/l10n/app_en.arb + app_af.arb:\n'
            '${unexpected.entries.map((e) => '${e.key}\n  ${e.value.join('\n  ')}').join('\n')}');
    expect(nowClean, isEmpty,
        reason: 'These files are fully translated — remove them from '
            'test/l10n/not_yet_translated.txt: $nowClean');
  });

  test('English and Afrikaans have the same texts and placeholders', () {
    Map<String, dynamic> load(String p) =>
        jsonDecode(File(p).readAsStringSync()) as Map<String, dynamic>;
    final en = load('lib/l10n/app_en.arb');
    final af = load('lib/l10n/app_af.arb');
    final enKeys = en.keys.where((k) => !k.startsWith('@')).toSet();
    final afKeys = af.keys.where((k) => !k.startsWith('@')).toSet();
    expect(enKeys.difference(afKeys), isEmpty, reason: 'Missing in Afrikaans');
    expect(afKeys.difference(enKeys), isEmpty, reason: 'Missing in English');

    Set<String> holes(String s) => RegExp(r'\{(\w+)[,}]')
        .allMatches(s)
        .map((m) => m.group(1)!)
        .toSet();
    for (final k in enKeys) {
      expect(holes(af[k] as String), holes(en[k] as String),
          reason: 'Placeholders differ for "$k"');
      expect((af[k] as String).trim(), isNotEmpty, reason: '"$k" is empty');
    }
  });
}
