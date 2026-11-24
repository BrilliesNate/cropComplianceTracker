"""Prints each flagged line in full: python tool/l10n_show.py <path-filter>"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from l10n_scan import scan, ROOT
sys.stdout.reconfigure(encoding='utf-8', errors='replace')
for rel, items in sorted(scan(sys.argv[1]).items()):
    lines = open(os.path.join(ROOT, rel), encoding='utf-8').read().split('\n')
    print(f'== {rel}')
    for n in sorted({n for n, _ in items}):
        print(f'{n:5d}| {lines[n-1].rstrip()}')
