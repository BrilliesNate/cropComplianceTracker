"""Removes fully translated files from test/l10n/not_yet_translated.txt."""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from l10n_scan import scan
p = os.path.join(os.path.dirname(__file__), '..', 'test', 'l10n', 'not_yet_translated.txt')
lines = open(p, encoding='utf-8').read().splitlines()
found = scan()
keep = [l for l in lines if l.startswith('#') or not l.strip() or l.strip() in found]
removed = [l for l in lines if l not in keep]
open(p, 'w', encoding='utf-8', newline='\n').write('\n'.join(keep) + '\n')
print('done:', ', '.join(removed) or '-')
print('left:', len([l for l in keep if l.strip() and not l.startswith('#')]), 'files,',
      sum(len(v) for v in found.values()), 'texts')
