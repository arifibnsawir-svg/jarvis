#!/usr/bin/env bash
# FASE 1: daftarin combo 'jarvis-reason' ke guardian_router (COMBO_MODEL_MAP + TIMEOUTS + MAX_TOKENS).
# Aman: backup, insert by-anchor (idempotent), py_compile, auto-restore kalau syntax error.
# TIDAK menyentuh file council. TIDAK restart Guardian (itu langkah terpisah, butuh approval).
set -uo pipefail

python3 - <<'PYEOF'
import pathlib, shutil, time, subprocess, sys
gr = pathlib.Path.home()/".hermes/scripts/guardian_router.py"
src = gr.read_text()

have = src.count('"jarvis-reason"')
if have >= 3:
    print("RESULT: SKIP (jarvis-reason sudah terdaftar di guardian_router, count=%d)" % have)
    sys.exit(0)

anchors = {
    '"DeepFix": "DeepFix_v121",': '    "jarvis-reason": "jarvis-reason",',
    '"DeepFix": 240,':            '    "jarvis-reason": 150,',
    '"DeepFix": 4000,':           '    "jarvis-reason": 3000,',
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
total = newsrc.count('"jarvis-reason"')
if total != 3:
    print("RESULT: ABORT (anchor meleset; jarvis-reason hasil=%d, harusnya 3). File TIDAK diubah." % total)
    sys.exit(0)

ts = time.strftime("%Y%m%d_%H%M%S")
bak = pathlib.Path(str(gr)+".bak."+ts)
shutil.copy(gr, bak); print("BACKUP:", bak)
gr.write_text(newsrc)

r = subprocess.run([sys.executable, "-m", "py_compile", str(gr)],
                   capture_output=True, text=True)
if r.returncode != 0:
    shutil.copy(bak, gr)
    print("RESULT: FAILED_RESTORED (py_compile error) ->", r.stderr.strip()[:200])
else:
    print("RESULT: SUCCESS (guardian_router: jarvis-reason terdaftar di 3 dict)")
PYEOF

echo "=== PROOF: jarvis-reason di guardian_router ==="
grep -n "jarvis-reason" ~/.hermes/scripts/guardian_router.py || echo "(tidak ada)"
echo "=== INFO RESTART GUARDIAN (buat langkah berikut) ==="
echo "-- proses guardian_router yang jalan --"
pgrep -af guardian_router 2>/dev/null || echo "(pgrep kosong)"
echo "-- systemd unit terkait --"
systemctl --user list-units --type=service 2>/dev/null | grep -iE "guardian|9router|router" || echo "(gak ada unit cocok)"
ls ~/.config/systemd/user/ 2>/dev/null | grep -iE "guardian|router" || echo "(gak ada file unit cocok)"
