#!/usr/bin/env bash
# Always-on deploy for neuro-arc + arsi-doctrine.
# Mechanism (verified): Hermes injects ~/.hermes/memories/USER.md into the system prompt every turn.
# We append 2 behavioral directives (same pattern as existing always-on guards on USER.md lines 510/512/572),
# then revert the dead `enabled_default_skills` config key back to its original value.
# Safe: backs up every file it touches; idempotent; prints deterministic RESULT lines.
set -uo pipefail

python3 - <<'PYEOF'
import pathlib, shutil, time

home = pathlib.Path.home()
um   = home/".hermes/memories/USER.md"
cfg  = home/".hermes/config.yaml"
ts   = time.strftime("%Y%m%d_%H%M%S")

d_neuro = ('Use the neuro-arc skill by default for any task that produces an artifact or a risky '
           'decision: first structure the raw request into a TaskState via '
           'narasi->entitas->ukuran->relasi->output BEFORE reasoning or acting; derive measurable '
           'success criteria from "ukuran"; skip for trivial chat/greetings (adaptive depth).')
d_arsi  = ('Use the arsi-doctrine skill for artifact-producing or multi-step tasks: run '
           'Audit->Rancang->Sistemasi->Iterasi as a self-healing loop '
           '(produce->gate->read verdict->fix->re-gate until it passes or budget runs out); '
           'A.R.S.I is the rule and arsi engine is the runtime; NEVER self-declare '
           'DONE/PRODUCTION_READY -- only the deterministic gate (PIPA4) may, you can only propose '
           'AWAITING_GATE; reuse the evidence-claim-status-guard status vocabulary.')

# --- PART 1: append always-on directives to USER.md (idempotent) ---
if not um.exists():
    print("RESULT_USERMD: FAIL (USER.md not found at %s)" % um)
else:
    shutil.copy(um, str(um)+".bak."+ts)
    print("USER.md BACKUP:", str(um)+".bak."+ts)
    t = um.read_text(); added = []
    if "neuro-arc skill by default" not in t:
        t = t.rstrip()+"\n"+d_neuro+"\n"; added.append("neuro-arc")
    if "arsi-doctrine skill for artifact" not in t:
        t = t.rstrip()+"\n"+d_arsi+"\n"; added.append("arsi-doctrine")
    um.write_text(t)
    chk = um.read_text()
    ok1 = "neuro-arc skill by default" in chk
    ok2 = "arsi-doctrine skill for artifact" in chk
    print("ADDED:", added if added else "(already present)")
    print("VERIFY neuro-arc:", ok1, "| arsi-doctrine:", ok2)
    print("RESULT_USERMD:", "SUCCESS" if (ok1 and ok2) else "FAIL")

# --- PART 2: revert dead enabled_default_skills key (housekeeping) ---
cur  = "  enabled_default_skills: '[''smart-router'', ''neuro-arc'', ''arsi-doctrine'']'"
orig = "  enabled_default_skills: '[''smart-router'']'"
c = cfg.read_text()
if cur in c:
    shutil.copy(cfg, str(cfg)+".bak."+ts)
    cfg.write_text(c.replace(cur, orig))
    print("RESULT_CONFIG: REVERTED to smart-router only")
elif orig in c:
    print("RESULT_CONFIG: already smart-router only (skip)")
else:
    print("RESULT_CONFIG: skip (line differs, not touched)")
PYEOF

echo "=== PROOF: USER.md directives ==="
grep -n "neuro-arc skill by default\|arsi-doctrine skill for artifact" ~/.hermes/memories/USER.md || echo "(not found)"
echo "=== PROOF: config line ==="
grep -n "enabled_default_skills" ~/.hermes/config.yaml || echo "(not found)"
