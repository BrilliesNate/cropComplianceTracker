import 'package:cropCompliance/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// English | Afrikaans switch. [compact] shows "EN | AF" for top bars.
class LanguageToggle extends StatelessWidget {
  final bool compact;

  /// Colours for use on a dark (green) bar.
  final bool onDark;

  const LanguageToggle({super.key, this.compact = false, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LocaleProvider>(context);
    final l10n = context.l10n;
    final selectedBg = onDark ? Colors.white : const Color(0xFF2E7D32);
    final selectedFg = onDark ? const Color(0xFF2E7D32) : Colors.white;
    final idleFg = onDark ? Colors.white : const Color(0xFF2E7D32);

    Widget option(String code, String label, String full) {
      final selected = lang.code == code;
      return Semantics(
        selected: selected,
        button: true,
        label: full,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: selected ? null : () => lang.setLanguage(code),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 16, vertical: compact ? 5 : 9),
            decoration: BoxDecoration(
              color: selected ? selectedBg : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.w700,
                    color: selected ? selectedFg : idleFg)),
          ),
        ),
      );
    }

    return Tooltip(
      message: l10n.language,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: idleFg.withValues(alpha: 0.6)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          option('en', compact ? 'EN' : l10n.languageEnglish,
              l10n.languageEnglish),
          option('af', compact ? 'AF' : l10n.languageAfrikaans,
              l10n.languageAfrikaans),
        ]),
      ),
    );
  }
}
