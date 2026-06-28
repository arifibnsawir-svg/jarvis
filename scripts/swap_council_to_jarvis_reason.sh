#!/usr/bin/env bash
# FASE 3: swap model council DailyFree -> jarvis-reason di 5 titik (phase6a/6c/6d + phase7a).
# Targeted replace (cuma di arg model, bukan blanket), backup tiap file, py_compile, auto-restore kalau gagal.
# Idempotent: skip kalau udah jarvis-reason. Jalanin SETELAH guardian_router kenal jarvis-reason (Fase 1+2).
set -uo pipefail

python3 - <<'PYEOF'
import pathlib, shutil, time, subprocess, sys
home = pathlib.Path.home()
ts = time.strftime("%Y%m%d_%H%M%S")

targets = [
    ("pipelines/pipa4/phase6a/phase6a_llm_review_dryrun.py",
        [('model="DailyFree"', 'model="jarvis-reason"')]),
    ("pipelines/pipa4/phase6c/phase6c_council.py",
        [("model='DailyFree'", "model='jarvis-reason'")]),
    ("pipelines/pipa4/phase6d/pipa4_mini_council_review.py",
        [("model='DailyFree'", "model='jarvis-reason'"),
         ("default='DailyFree'", "default='jarvis-reason'")]),
    ("pipelines/pipa4/phase7a/pipa4_review_local.py",
        [("'--model', 'DailyFree'", "'--model', 'jarvis-reason'")]),
]

allok = True
for rel, pairs in targets:
    p = home/".hermes"/rel
    if not p.exists():
        print("MISSING:", p); allok = False; continue
    src = p.read_text(); newsrc = src; changed = 0; detail = []
    for old, new in pairs:
        c = newsrc.count(old)
        if c > 0:
            newsrc = newsrc.replace(old, new); changed += c
            detail.append("%r x%d -> swapped" % (old, c))
        elif new in newsrc:
            detail.append("%r already present (skip)" % new)
        else:
            detail.append("%r NOT FOUND" % old); allok = False
    if newsrc != src:
        bak = pathlib.Path(str(p)+".bak."+ts); shutil.copy(p, bak); p.write_text(newsrc)
        r = subprocess.run([sys.executable, "-m", "py_compile", str(p)], capture_output=True, text=True)
        if r.returncode != 0:
            shutil.copy(bak, p)
            print("FAIL_RESTORED:", rel, "->", r.stderr.strip()[:160]); allok = False
        else:
            print("OK:", rel, "(changed %d)" % changed, "backup", bak.name)
    else:
        print("NOCHANGE:", rel)
    for d in detail: print("    -", d)

print("RESULT:", "SUCCESS" if allok else "CHECK_NEEDED")
PYEOF

echo "=== PROOF: model arg di tiap file council ==="
grep -n "DailyFree\|jarvis-reason" \
  ~/.hermes/pipelines/pipa4/phase6a/phase6a_llm_review_dryrun.py \
  ~/.hermes/pipelines/pipa4/phase6c/phase6c_council.py \
  ~/.hermes/pipelines/pipa4/phase6d/pipa4_mini_council_review.py \
  ~/.hermes/pipelines/pipa4/phase7a/pipa4_review_local.py 2>/dev/null
