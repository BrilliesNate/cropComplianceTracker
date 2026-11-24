"""After hard-coded text is replaced by context.l10n.x, widgets that were
`const` no longer can be. This runs the analyzer on the given files and removes
the nearest `const` enclosing each "invalid constant" error, repeating until
none are left.

Usage: python tool/fix_const.py lib/views/a.dart lib/views/b.dart ...
"""
import os
import re
import subprocess
import sys

ROOT = os.path.join(os.path.dirname(__file__), '..')
CODES = ('invalid_constant', 'const_with_non_constant_argument',
         'non_constant_list_element', 'const_initialized_with_non_constant_value',
         'non_constant_map_element', 'const_constructor_param_type_mismatch',
         'non_constant_default_value')
ERR = re.compile(r'error - .* - (.+?\.dart):(\d+):(\d+) - (\w+)')
OPEN = {'(': ')', '[': ']', '{': '}'}


def enclosing_const(s, pos):
    for m in reversed(list(re.finditer(r'\bconst\s+', s[:pos]))):
        i = m.end()
        # skip the type / constructor name to the first bracket
        while i < len(s) and s[i] not in '([{;,':
            i += 1
        if i >= len(s) or s[i] not in OPEN:
            continue
        depth, j = 0, i
        while j < len(s):
            c = s[j]
            if c in '([{':
                depth += 1
            elif c in ')]}':
                depth -= 1
                if depth == 0:
                    break
            elif c in '\'"':
                q = c
                j += 1
                while j < len(s) and s[j] != q:
                    j += 2 if s[j] == '\\' else 1
            j += 1
        if j >= pos:
            return m
    return None


def run(files):
    for _ in range(40):
        out = subprocess.run(['flutter', 'analyze', '--no-pub', *files],
                             cwd=ROOT, capture_output=True, text=True,
                             shell=os.name == 'nt').stdout
        errs = [e for e in ERR.findall(out) if e[3] in CODES]
        if not errs:
            return out
        by_file = {}
        for path, line, col, _ in errs:
            by_file.setdefault(path.replace('\\', '/'), set()).add((int(line), int(col)))
        changed = False
        for path, spots in by_file.items():
            full = os.path.join(ROOT, path)
            with open(full, encoding='utf-8') as f:
                s = f.read()
            lines = s.split('\n')
            offsets = [0]
            for ln in lines:
                offsets.append(offsets[-1] + len(ln) + 1)
            cuts = set()
            for line, col in spots:
                pos = offsets[line - 1] + col - 1
                m = enclosing_const(s, pos)
                if m:
                    cuts.add((m.start(), m.end()))
            for a, b in sorted(cuts, reverse=True):
                s = s[:a] + s[b:]
                changed = True
            with open(full, 'w', encoding='utf-8', newline='') as f:
                f.write(s)
        if not changed:
            return out
    return out


if __name__ == '__main__':
    out = run(sys.argv[1:])
    errors = [l for l in out.splitlines() if l.strip().startswith('error')]
    print('\n'.join(errors) if errors else 'no errors')
