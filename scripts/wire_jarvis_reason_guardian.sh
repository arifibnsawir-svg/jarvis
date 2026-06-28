#!/usr/bin/env bash
# FASE 1: daftarin combo 'jarvis-reason' ke guardian_router (COMBO_MODEL_MAP + TIMEOUTS + MAX_TOKENS).
# Aman: backup, insert by-anchor (idempotent), py_compile, auto-restore kalau syntax error.
# Verifikasi cek 3 ENTRY spesifik (bukan count occurrence -> map line punya "jarvis-reason" 2x).
# TIDAK menyentuh file council. TIDAK restart Guardian (langkah terpisah, butuh approval).
set -uo pipefail

python3 - <<'PYEOF'
import pathlib, shutil, time, subprocess, sys
gr = pathlib.Path.home()/".hermes/scripts/guardian_router.py"
src = gr.read_text()

E_MAP = '"jarvis-reason": "jarvis-reason",'
E_TO  = '"jarvis-reason": 150,'
E_MT  = '"jarvis-reason": 3000,'

if E_MAP in src and E_TO in src and E_MT in src:
    print("RESULT: SKIP (3 entry jarvis-reason sudah ada)")
    sys.exit(0)

anchors = {
    '"DeepFix": "DeepFix_v121",': '    ' + E_MAP,
    '"DeepFix": 240,':            '    ' + E_TO,
    '"DeepFix": 4000,':           '    ' + E_MT,
}
lines = src.split("\n")
out = []
for i, line in enumerate(lines):
    out.append(line)
    for a, newline in anchors.items():
        if a in line:
            nxt = lines[i+1] if i+1 < len(lines) else ""
            if '"jarvis-reason"' not in nxt:
                out.append(newline)
newsrc = "\n".join(out)

ok_map, ok_to, ok_mt = (E_MAP in newsrc), (E_TO in newsrc), (E_MT in newsrc)
if not (ok_map and ok_to and ok_mt):
    print("RESULT: ABORT (anchor meleset -> map=%s timeout=%s maxtok=%s). File TIDAK diubah." % (ok_map, ok_to, ok_mt))
    sys.exit(0)

ts = time.strftime("%Y%m%d_%H%M%S")
bak = pathlib.Path(str(gr)+".bak."+ts)
shutil.copy(gr, bak); print("BACKUP:", bak)
gr.write_text(newsrc)

r = subprocess.run([sys.executable, "-m", "py_compile", str(gr)], capture_output=True, text=True)
if r.returncode != 0:
    shutil.copy(bak, gr)
    print("RESULT: FAILED_RESTORED (py_compile error) ->", r.stderr.strip()[:200])
else:
    print("RESULT: SUCCESS (jarvis-reason terdaftar: map+timeout+maxtokens)")
PYEOF

echo "=== PROOF: 3 entry jarvis-reason ==="
grep -n "jarvis-reason" ~/.hermes/scripts/guardian_router.py || echo "(tidak ada)"
