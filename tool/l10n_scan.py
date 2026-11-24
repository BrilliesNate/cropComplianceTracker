"""Finds user-facing English typed straight into the app code (not yet moved
into lib/l10n/app_en.arb). Used while translating; the permanent guard is
test/l10n/no_hardcoded_text_test.dart, which applies the same rules.

Usage: python tool/l10n_scan.py [--list] [path-filter]
"""
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(__file__), '..', 'lib')

# Files that are not app UI.
EXEMPT_FILES = (
    'l10n/',                 # the translations themselves
    'firebase_options.dart',
    'videoAnimation.dart',   # marketing video stage, never shown to users
)

SKIP_LINE = re.compile(
    r"^\s*(import|export|part)\s|print\(|debugPrint\(|developer\.log|"
    r"\blog\(|assert\(|RegExp\(|l10n-ignore|"
    r"\.collection\(|\.doc\(|\.where\(|\.orderBy\(|@pragma|"
    r"^\s*//|^\s*\*|^\s*///")

LOG_CALL = re.compile(r"\b(?:debugPrint|print|_tlog|_log|_dplog)\(")
LITERAL = re.compile(r"""(?<![A-Za-z0-9_])(?:r)?('(?:[^'\\\n]|\\.)*'|"(?:[^"\\\n]|\\.)*")""")


def looks_like_ui_text(lit: str) -> bool:
    s = lit[1:-1]
    s = re.sub(r"\$\{[^}]*\}|\$[A-Za-z_][A-Za-z0-9_.]*", "X", s)
    s = s.replace('\\n', ' ').strip()
    if not re.search(r"[A-Za-z]{2,}", s):
        return False
    if re.match(r"^(https?:|mailto:|tel:|assets/|package:|dart:)", s):
        return False
    if re.fullmatch(r"[a-z][A-Za-z0-9_]*", s):          # identifiers: companyId
        return False
    if re.fullmatch(r"[A-Z0-9_]+", s):                   # ENUM_VALUES, IPW
        return False
    if re.fullmatch(r"[\w./\-]+\.(dart|png|jpg|webp|svg|json|pdf|csv|xlsx|ttf|otf)", s):
        return False
    if re.fullmatch(r"[a-z0-9_]+(/[a-z0-9_{}\-]+)+", s):   # paths
        return False
    if re.fullmatch(r"/[\w\-/]*", s):                     # routes
        return False
    # Words with a space, or a capitalised word: human text.
    if ' ' in s.strip() and re.search(r"[A-Za-z]{2,}", s):
        return True
    if re.fullmatch(r"[A-Z][a-z]+[A-Za-z]*[.!?:…]?", s):
        return True
    if re.search(r"[A-Za-z]{2,}[.!?:…]$", s):
        return True
    return False


def scan(filter_=''):
    found = {}
    for dirpath, _, files in os.walk(ROOT):
        for f in files:
            if not f.endswith('.dart'):
                continue
            full = os.path.join(dirpath, f)
            rel = os.path.relpath(full, ROOT).replace('\\', '/')
            if any(rel.startswith(e) or rel.endswith(e) for e in EXEMPT_FILES):
                continue
            if filter_ and filter_ not in rel:
                continue
            with open(full, encoding='utf-8') as fh:
                log_depth = 0  # inside a print( / debugPrint( spanning lines
                for n, line in enumerate(fh, 1):
                    code = LITERAL.sub("''", line)
                    if log_depth > 0:
                        log_depth += code.count('(') - code.count(')')
                        continue
                    m = LOG_CALL.search(code)
                    if m:
                        rest = code[m.end():]
                        depth = 1 + rest.count('(') - rest.count(')')
                        if depth > 0:
                            log_depth = depth
                        continue
                    if SKIP_LINE.search(line):
                        continue
                    for m in LITERAL.finditer(line):
                        # Date patterns, e.g. DateFormat('d MMM yyyy').
                        if re.search(r"DateFormat(?:\.\w+)?\(\s*$", line[:m.start()]):
                            continue
                        if looks_like_ui_text(m.group(1)):
                            found.setdefault(rel, []).append((n, m.group(1)))
    return found


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    found = scan(args[0] if args else '')
    total = sum(len(v) for v in found.values())
    for rel, items in sorted(found.items(), key=lambda kv: -len(kv[1])):
        print(f"{len(items):5d}  {rel}")
        if '--list' in sys.argv:
            for n, lit in items:
                print(f"         {n}: {lit}")
    print(f"TOTAL {total} in {len(found)} files")
