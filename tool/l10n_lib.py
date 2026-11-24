"""Helpers used while moving hard-coded text into lib/l10n/app_*.arb.

    import sys; sys.path.insert(0, 'tool'); from l10n_lib import *
    add_keys({'commonCancel': ('Cancel', 'Kanselleer'),
              'filesWaiting': ('{count} files waiting', '{count} lêers wag',
                               {'count': 'int'})})
    edit('lib/views/x.dart', [("Text('Cancel')", "Text(context.l10n.commonCancel)")])
"""
import json
import os
import re
from collections import OrderedDict

ROOT = os.path.join(os.path.dirname(__file__), '..')
EN = os.path.join(ROOT, 'lib', 'l10n', 'app_en.arb')
AF = os.path.join(ROOT, 'lib', 'l10n', 'app_af.arb')


def _load(p):
    with open(p, encoding='utf-8') as f:
        return json.load(f, object_pairs_hook=OrderedDict)


def _save(p, d):
    with open(p, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(d, f, ensure_ascii=False, indent=2)
        f.write('\n')


def _placeholders(text):
    # Top-level {name} or {name, plural|select, ...}; ignore nested {…} text.
    names, depth, i = [], 0, 0
    while i < len(text):
        c = text[i]
        if c == '{':
            if depth == 0:
                m = re.match(r'\{(\w+)\s*(,|\})', text[i:])
                if m and m.group(1) not in names:
                    names.append(m.group(1))
            depth += 1
        elif c == '}':
            depth -= 1
        i += 1
    return names


INT_NAMES = {'count', 'n', 'total', 'done', 'days', 'pending',
             'number', 'percent', 'files', 'employees', 'farms', 'year'}


def add_keys(keys):
    en, af = _load(EN), _load(AF)
    for key, spec in keys.items():
        en_text, af_text = spec[0], spec[1]
        types = spec[2] if len(spec) > 2 else {}
        if key in en and en[key] != en_text:
            raise SystemExit(f'Key {key} exists with different English: '
                             f'{en[key]!r} vs {en_text!r}')
        en[key] = en_text
        af[key] = af_text
        ph = _placeholders(en_text)
        if set(ph) != set(_placeholders(af_text)):
            raise SystemExit(f'Placeholder mismatch in {key}: {en_text!r} / {af_text!r}')
        if ph:
            en['@' + key] = {'placeholders': {
                n: {'type': types.get(n, 'int' if n in INT_NAMES else 'String')}
                for n in ph}}
    _save(EN, en)
    _save(AF, af)


def edit(path, pairs, imports=("import 'package:cropCompliance/providers/locale_provider.dart';",)):
    full = os.path.join(ROOT, path)
    with open(full, encoding='utf-8') as f:
        s = f.read()
    for pair in pairs:
        old, new = pair[0], pair[1]
        count = pair[2] if len(pair) > 2 else 1
        found = s.count(old)
        if count == 'all':
            if found == 0:
                raise SystemExit(f'{path}: not found: {old!r}')
        elif found != count:
            raise SystemExit(f'{path}: expected {count}x, found {found}x: {old!r}')
        s = s.replace(old, new)
    for imp in imports:
        if imp and imp not in s:
            m = list(re.finditer(r'^import .*;\n', s, re.M))
            pos = m[-1].end() if m else 0
            s = s[:pos] + imp + '\n' + s[pos:]
    with open(full, 'w', encoding='utf-8', newline='') as f:
        f.write(s)
