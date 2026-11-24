#!/usr/bin/env python3
"""FDN text check (card X4-23a). Run from anywhere: python tools/check_l10n.py

Checks the FDN text page 477605 against the md scripts:
  - t/0001-l044.xml and t/0001.xml exist, parse, are identical and hold page 477605
  - no duplicate ids, no empty text, no text starting or ending with a space
  - no unescaped ( or ) (a plain bracket starts a comment in X4 text files), no { or }
  - %1..%n numbered without gaps; a text that gets values has no plain % sign
  - every {477605,id} used in md/*.xml exists (missing ids), every id is used (unused ids)
  - each use passes as many values (.[a, b]) as the text has %n slots
  - no English text left in the converted files (md/fdn_options.xml, md/fdn_overview.xml),
    apart from ids, keys and the fdn.log lines, which stay English on purpose
Other md files are listed for information only (they are converted in later cards).
Exit code 0 = pass, 1 = fail. Uses only the Python standard library.
"""
import os, re, sys
import xml.etree.ElementTree as ET

PAGE = 477605
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TFILES = ['t/0001-l044.xml', 't/0001.xml']
CONVERTED = ['md/fdn_options.xml', 'md/fdn_overview.xml']

# Literals in the converted files that are not shown text. Each entry: (regex on the text before the
# literal, why). The literal is allowed when the text just before it matches.
CONTEXT_OK = [
    (r"\$(Key|id|type|category|font|halign|color|IdSuffix|event|Kind)\s*=\s*$", 'id, key, saved kind or style value'),
    (r'name="\$R" exact="$', 'rule id'),
    (r"indexof\.\{$", 'table key'),
    (r"(==|!=)\s*$", 'compared with a saved id'),
    (r'name="(Key|Rule|Source|Kind)" value="$', 'setting key, rule id or log suffix'),
    (r"\$Order\" exact=\"\[[^\]]*$", 'rule ids'),
    (r"\$ViewIds\" exact=\"\[[^\]]*$", 'view names for fdn.log (English on purpose)'),
    (r"\$Defaults\.\{$", 'setting key'),
]
LITERAL_OK = {
    'FDN': 'category text, not translated (decision D6)',
    ' Cr': 'credits unit, not translated (decision D6)',
    'no manager: FDN does not use this DC until a manager is assigned': 'reason text, converted with the reasons in X4-23b',
}
SKIP_LINE = [r'<debug_text ', r'<param name="Text" value=', r'<param name="Level" value=']

errors, notes = [], []

def err(m): errors.append(m)

def read(p):
    with open(os.path.join(ROOT, p), encoding='utf-8') as f:
        return f.read()

# ---------- t files ----------
texts = {}
raw = {}
for p in TFILES:
    full = os.path.join(ROOT, p)
    if not os.path.exists(full):
        err('%s: missing' % p); continue
    raw[p] = open(full, 'rb').read()
    try:
        root = ET.fromstring(raw[p])
    except ET.ParseError as e:
        err('%s: XML error %s' % (p, e)); continue
    pages = [pg for pg in root.iter('page') if pg.get('id') == str(PAGE)]
    if len(pages) != 1:
        err('%s: expected one page id %d, found %d' % (p, PAGE, len(pages))); continue
    seen = {}
    for t in pages[0].iter('t'):
        i = t.get('id')
        if i is None or not i.isdigit():
            err('%s: <t> with bad id %r' % (p, i)); continue
        i = int(i)
        if i in seen:
            err('%s: duplicate id %d' % (p, i))
        seen[i] = t.text or ''
    texts[p] = seen
if len(raw) == 2 and raw[TFILES[0]] != raw[TFILES[1]]:
    err('t/0001-l044.xml and t/0001.xml differ (they must be identical)')
E = texts.get(TFILES[0], {})

def slots(s):
    return sorted(set(int(n) for n in re.findall(r'%(\d+)', s)))

for i, s in sorted(E.items()):
    where = 'id %d' % i
    if s == '':
        err('%s: empty text' % where)
    if s != s.strip():
        err('%s: starts or ends with a space: %r' % (where, s))
    if re.search(r'(?<!\\)[()]', s):
        err('%s: unescaped bracket (write \\( and \\)): %r' % (where, s))
    if '{' in s or '}' in s:
        err('%s: contains { or }: %r' % (where, s))
    n = slots(s)
    if n and n != list(range(1, len(n) + 1)):
        err('%s: slots not numbered 1..n: %r' % (where, s))
    if n and re.search(r'%(?!\d)', s):
        err('%s: plain %% sign in a text that gets values: %r' % (where, s))

# ---------- md references ----------
def count_args(src, pos):
    """src[pos] is '[' after '.'; count top-level comma-separated values up to the matching ']'."""
    depth, q, args, empty = 0, False, 1, True
    for j in range(pos, len(src)):
        c = src[j]
        if q:
            if c == "'": q = False
            continue
        if c == "'":
            q = True; empty = False
        elif c in '[({':
            depth += 1
            if depth > 1: empty = False
        elif c in '])}':
            depth -= 1
            if depth == 0:
                return 0 if empty else args
        elif c == ',' and depth == 1:
            args += 1
        elif not c.isspace():
            empty = False
    return -1

used = {}
mdfiles = sorted(f for f in os.listdir(os.path.join(ROOT, 'md')) if f.endswith('.xml'))
REF = re.compile(r'\{\s*%d\s*,\s*(\d+)\s*\}' % PAGE)
for f in mdfiles:
    p = 'md/' + f
    src = read(p)
    try:
        ET.fromstring(src.encode('utf-8'))
    except ET.ParseError as e:
        err('%s: XML error %s' % (p, e))
    for m in REF.finditer(src):
        i = int(m.group(1))
        line = src.count('\n', 0, m.start()) + 1
        used.setdefault(i, []).append('%s:%d' % (p, line))
        if i not in E:
            err('%s:%d: id %d missing from the text file' % (p, line, i)); continue
        want = len(slots(E[i]))
        rest = src[m.end():]
        got = count_args(src, m.end() + 1) if rest.startswith('.[') else 0
        if got != want:
            err('%s:%d: id %d has %d slot(s) but gets %d value(s)' % (p, line, i, want, got))
for i in sorted(set(E) - set(used)):
    err('id %d is not used in md/ (unused id): %r' % (i, E[i]))

# ---------- English left in md ----------
LIT = re.compile(r"'((?:[^'\\]|\\.)*)'")
def leftovers(p):
    out = []
    in_comment = False
    for n, line in enumerate(read(p).split('\n'), 1):
        s = line
        if in_comment:
            if '-->' not in s: continue
            s = s.split('-->', 1)[1]; in_comment = False
        while '<!--' in s:
            a, b = s.split('<!--', 1)
            if '-->' in b:
                s = a + b.split('-->', 1)[1]
            else:
                s = a; in_comment = True
        if any(re.search(k, s) for k in SKIP_LINE):
            continue
        s = re.sub(r'\scomment="[^"]*"', '', s)
        for m in LIT.finditer(s):
            lit = m.group(1)
            if not re.search(r'[A-Za-z]{2,}', lit):
                continue
            before = s[:m.start()]
            if lit in LITERAL_OK or lit.startswith('Color.') or lit.startswith('fdn_'):
                continue
            if any(re.search(r, before) for r, _ in CONTEXT_OK):
                continue
            out.append((n, lit))
    return out

for p in CONVERTED:
    for n, lit in leftovers(p):
        err('%s:%d: English text not moved to page %d: %r' % (p, n, PAGE, lit))
info = []
for f in mdfiles:
    p = 'md/' + f
    if p in CONVERTED: continue
    info.append('  %-26s %3d quoted English strings outside log lines (later cards)' % (p, len(leftovers(p))))

# ---------- report ----------
def ranges(ids):
    out, start, prev = [], None, None
    for i in ids:
        if start is None:
            start = prev = i
        elif i == prev + 1:
            prev = i
        else:
            out.append((start, prev)); start = prev = i
    if start is not None:
        out.append((start, prev))
    return ', '.join('%d' % a if a == b else '%d-%d' % (a, b) for a, b in out)

print('FDN text check, page %d' % PAGE)
print('  text files : %s (identical: %s)' % (', '.join(TFILES), 'yes' if len(raw) == 2 and raw[TFILES[0]] == raw[TFILES[1]] else 'NO'))
print('  entries    : %d' % len(E))
print('  ids        : %s' % ranges(sorted(E)))
print('  references : %d in md/ (%d ids used)' % (sum(len(v) for v in used.values()), len(used)))
print('  converted  : %s' % ', '.join(CONVERTED))
print('Not converted yet (information only):')
for l in info:
    print(l)
if errors:
    print('FAIL: %d problem(s)' % len(errors))
    for e in errors:
        print('  ' + e)
    sys.exit(1)
print('PASS: no missing, unused or duplicate ids, no unescaped brackets, slots match, no English left in the converted files')
