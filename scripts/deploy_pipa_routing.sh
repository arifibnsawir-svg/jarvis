#!/usr/bin/env bash
# Deploy skill pipa-routing (always-on, soft). Pola sama deploy_alwayson.sh.
# 1) copy SKILL.md ke ~/.hermes/skills/pipa-routing/  2) inject 1 direktif ke USER.md (idempotent+backup).
# Always-on Hermes = direktif di ~/.hermes/memories/USER.md yg di-inject ke system prompt tiap turn.
# TIDAK restart, TIDAK ubah config core. Aktif di session baru (system prompt dibangun per-session).
set -uo pipefail

SRC=~/jarvis/skills/pipa-routing/SKILL.md
DST_DIR=~/.hermes/skills/pipa-routing

echo "=== [1] deploy SKILL.md ==="
mkdir -p "$DST_DIR"
cp -f "$SRC" "$DST_DIR/SKILL.md"
ls -la "$DST_DIR"
echo "wc:"; wc -c "$DST_DIR/SKILL.md"

echo; echo "=== [2] inject direktif always-on ke USER.md (idempotent) ==="
python3 - <<'PYEOF'
import pathlib, shutil, time
home = pathlib.Path.home()
um = home/".hermes/memories/USER.md"
ts = time.strftime("%Y%m%d_%H%M%S")
d_router = ('Use the pipa-routing skill FIRST on every incoming request as step zero (router; it NEVER '
            'blocks or refuses input): pick depth and approach before NEURO-ARC/ARSI run. Depth (adaptive): '
            'trivial chat/fact -> answer directly (no pipes); internal_research/brainstorm -> think freely '
            'with brand gate BYPASS (Mythos); artifact-producing or risky task -> NEURO-ARC -> ARSI -> PIPA4 '
            'gate (Fable, gate ON). Approach by artifact_type: code -> coding mindset; document/slide/sheet -> '
            'Structure-Before-Render (emit a structured spec then render via tool and verify, NEVER one-shot '
            'freehand); web/research -> cite-or-abstain (verify sources resolve, say "belum nemu" instead of '
            'inventing sources/numbers); audit/QA -> defer to the deterministic gate. Do not force the full '
            '4-pipa on light input; routing is behavioral and never vonis DONE.')
if not um.exists():
    print("RESULT_USERMD: FAIL (USER.md not found at %s)" % um); raise SystemExit
shutil.copy(um, str(um)+".bak."+ts)
print("USER.md BACKUP:", str(um)+".bak."+ts)
t = um.read_text()
if "pipa-routing skill FIRST" in t:
    print("ADDED: (already present)")
else:
    um.write_text(t.rstrip()+"\n"+d_router+"\n"); print("ADDED: pipa-routing")
print("VERIFY pipa-routing:", "pipa-routing skill FIRST" in um.read_text())
print("RESULT_USERMD:", "SUCCESS" if "pipa-routing skill FIRST" in um.read_text() else "FAIL")
PYEOF

echo; echo "=== [3] validasi frontmatter SKILL.md (YAML parse) ==="
python3 - <<'PYEOF'
import pathlib, yaml
p = pathlib.Path.home()/".hermes/skills/pipa-routing/SKILL.md"
txt = p.read_text()
assert txt.startswith("---"), "no frontmatter"
fm = txt.split("---",2)[1]
d = yaml.safe_load(fm)
need = ["name","description","category","version"]
miss = [k for k in need if k not in d]
print("frontmatter keys:", list(d.keys()))
print("RESULT_FRONTMATTER:", "OK" if not miss and d.get("name")=="pipa-routing" else f"FAIL missing={miss}")
PYEOF

echo; echo "=== [4] PROOF ==="
grep -n "pipa-routing skill FIRST" ~/.hermes/memories/USER.md || echo "(directive not found)"
echo "CATATAN: aktif di SESSION BARU (kirim /new ke Jarvis). Tidak perlu restart gateway."
echo "ROLLBACK: cp ~/.hermes/memories/USER.md.bak.<ts> USER.md ; rm -rf ~/.hermes/skills/pipa-routing"
