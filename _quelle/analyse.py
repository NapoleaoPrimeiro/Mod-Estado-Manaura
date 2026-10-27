# France Rework - Analyse der Quelldaten (Zahlen, Fokuszeiten, Routen-Zeitplan, Boni)
# Aufruf: python analyse.py  -> schreibt ANALYSE.md neben den Mod-Ordner (France_Rework/ANALYSE.md)
import re, os, datetime, collections
SRC = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(SRC)
txt = open(os.path.join(SRC, 'fokus_daten.txt'), encoding='utf-8').read()

F = collections.OrderedDict()
cur = None
for line in txt.splitlines():
    if line.startswith('F '):
        p = line[2:].split('|')
        cur = dict(id=p[0], x=int(p[1]), y=int(p[2]), days=int(p[3]), icon=p[4], branch=p[5], path=p[6], filter=p[7],
                   pre=[], mx=[], avail=[], eff=[], name='')
        F[cur['id']] = cur
    elif cur is None:
        continue
    elif line.startswith('N '): cur['name'] = line[2:].strip()
    elif line.startswith('P '): cur['pre'].append(line[2:].split())
    elif line.startswith('X '): cur['mx'] += line[2:].split()
    elif line.startswith('A '): cur['avail'].append(line[2:])
    elif line.startswith('E '): cur['eff'].append(line[2:])

START = datetime.date(1936, 1, 1)
memo = {}
def closure(fid, stack=()):
    """cheapest set of focuses needed to complete fid (OR groups: cheapest option)."""
    if fid in memo: return memo[fid]
    f = F[fid]; need = {fid}
    for grp in f['pre']:
        best = None
        for g in grp:
            if g not in F or g in stack: continue
            c = closure(g, stack + (fid,))
            if best is None or sum(F[x]['days'] for x in c) < sum(F[x]['days'] for x in best): best = c
        if best: need |= best
    memo[fid] = need
    return need

def date_gate(fid):
    d = START
    for a in F[fid]['avail']:
        for m in re.finditer(r'date > (\d{4})\.(\d+)\.(\d+)', a):
            d = max(d, datetime.date(int(m.group(1)), int(m.group(2)), int(m.group(3))))
    return d

def earliest(fid):
    need = closure(fid)
    # order: respect date gates roughly -> total days, but never before the latest gate in the chain
    days = sum(F[x]['days'] for x in need)
    gate = max(date_gate(x) for x in need)
    d = START + datetime.timedelta(days=days)
    return max(d, gate + datetime.timedelta(days=F[fid]['days'])), days, len(need)

MILE = re.compile(r'wargoal|demand |union |vassal |declare_war|FRW_form_|create_wargoal|annex')
rows = []
for fid, f in F.items():
    effs = ' '.join(f['eff'])
    if MILE.search(effs):
        d, days, n = earliest(fid)
        kind = 'Formable' if 'FRW_form_' in effs else 'Krieg/Annexion'
        rows.append((f['path'], d, fid, f['name'], kind, n, days))
rows.sort(key=lambda r: (r[0], r[1]))

# bonuses
def macro_sum(fs, m):
    s = 0
    for f in fs:
        for e in f['eff']:
            p = e.split()
            if p[0] == m:
                try: s += int(p[1])
                except (IndexError, ValueError): s += 1
            if m in ('civ', 'mil', 'dock') and p[0] == 'build':
                t = {'civ': 'industrial_complex', 'mil': 'arms_factory', 'dock': 'dockyard'}[m]
                if len(p) > 3 and p[2] == t: s += int(p[3])
    return s

paths = collections.OrderedDict()
for f in F.values(): paths.setdefault((f['branch'], f['path']), []).append(f)
dur = collections.Counter(f['days'] for f in F.values())

out = []
out.append('# France Rework – Analyse der Quelldaten\n')
out.append(f'_Automatisch erzeugt von `_quelle/analyse.py` aus `_quelle/fokus_daten.txt`. Nicht von Hand bearbeiten._\n')
out.append(f'**Fokusse gesamt: {len(F)}** · Dauern: ' + ', '.join(f'{k} Tage: {v}' for k, v in sorted(dur.items())) + '\n')
out.append('## Fokusse je Ast und Pfad\n')
out.append('| Ast | Pfad | Fokusse | 35 T | 50 T | 70 T | 120 T | +Zivil | +Mil | +Werften | +Forschungsplätze |')
out.append('|---|---|---|---|---|---|---|---|---|---|---|')
for (b, p), fs in paths.items():
    c = collections.Counter(f['days'] for f in fs)
    out.append(f'| {b} | {p} | {len(fs)} | {c[35]} | {c[50]} | {c[70]} | {c[120]} | {macro_sum(fs,"civ")} | {macro_sum(fs,"mil")} | {macro_sum(fs,"dock")} | {macro_sum(fs,"rslot")} |')
shared = [f for f in F.values() if f['path'] == 'Alle' and f['branch'] not in ('Exil',)]
out.append(f'\n**Gemeinsame Äste (ohne Exil):** +{macro_sum(shared,"civ")} Zivil, +{macro_sum(shared,"mil")} Militär, +{macro_sum(shared,"dock")} Werften, +{macro_sum(shared,"rslot")} Forschungsplätze (inkl. Bau-Effekte in bestimmten Staaten).\n')
out.append('## Frühestmögliche Meilensteine je Route\n')
out.append('Annahme: Start 1.1.1936, keine Leerlaufzeit, nur die nötigen Vorgänger (bei ODER der billigste Weg), Datumsbedingungen berücksichtigt. In der Praxis kommen andere Äste dazwischen – die Werte sind eine Untergrenze.\n')
out.append('| Pfad | frühestens | Fokus | Art | nötige Fokusse | Tage |')
out.append('|---|---|---|---|---|---|')
for p, d, fid, n, kind, cnt, days in rows:
    out.append(f'| {p} | {d.isoformat()} | {n} (`{fid}`) | {kind} | {cnt} | {days} |')
open(os.path.join(ROOT, 'ANALYSE.md'), 'w', encoding='utf-8').write('\n'.join(out) + '\n')
print('Fokusse', len(F), dict(dur), 'Meilensteine', len(rows))

# ---- Spielstil je Pfad: Armee-/Marine-/Luftboni und Forschungsboni aus Ideen und Fokus-Makros
ideas = {}
cur = None
for line in open(os.path.join(SRC, 'ideen_daten.txt'), encoding='utf-8'):
    m = re.match(r'^I (\S+)\|(\S+)\|(.+)$', line)
    if m: cur = m.group(1); ideas[cur] = (m.group(3).strip(), [])
    elif line.startswith('M ') and cur: ideas[cur][1].append(line[2:].strip())
MIL = re.compile(r'^(army_|breakthrough|naval_|navy_|air_|experience_gain|land_|special_forces|max_dig|recon|planning|attrition|org)')
RES = re.compile(r'research')
out2 = ['\n## Spielstil je Pfad (Militär- und Forschungsboni)\n',
        'Aus den Nationalgeistern (`E idea/timed/swap`) und Forschungs-Makros (`E tech/doct`) der Fokusse des Pfads.\n',
        '| Pfad | Militär-Modifikatoren (Summe) | Forschung |', '|---|---|---|']
for (b, p), fs in paths.items():
    if b != 'Politik' and b != 'Exil': continue
    mil = collections.Counter(); res = []
    for f in fs:
        for e in f['eff']:
            a = e.split()
            cand = a[1:] if a[0] in ('idea', 'swap') else (a[1:2] if a[0] == 'timed' else [])
            for iid in [c for c in cand if c in ideas][-1:]:
                for mm in ideas[iid][1]:
                    k, _, v = mm.partition('=')
                    k = k.strip()
                    try: v = float(v)
                    except ValueError: continue
                    if MIL.search(k): mil[k] += v
                    elif RES.search(k): res.append(f'{k} {v:+g}')
            if a[0] in ('tech', 'doct'): res.append(f'{a[0]} {a[1]} {a[2] if len(a) > 2 else ""}x{a[3] if len(a) > 3 else 1}')
    ms = ', '.join(f'{k} {v:+.2f}' for k, v in mil.most_common()) or '–'
    out2.append(f'| {p} | {ms} | {"; ".join(res) or "–"} |')
with open(os.path.join(ROOT, 'ANALYSE.md'), 'a', encoding='utf-8') as fh:
    fh.write('\n'.join(out2) + '\n')
