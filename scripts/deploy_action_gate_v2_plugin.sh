#!/usr/bin/env bash
# DEPLOY action-gate v2 sebagai PLUGIN Hermes (hook pre_tool_call).
# Ini PENGGANTI pendekatan lama deploy_gate_v2.sh (yang nge-patch tool_executor.py).
# Keunggulan: core gateway TIDAK disentuh; coverage penuh (pre_tool_call kena concurrent+sequential+invoke_tool).
# Idempotent. py_compile + smoke-test. TIDAK restart gateway (rediscover plugin = langkah +GO terpisah).
# Mode default = shadow (gate_hook default) -> cuma LOG ke decisions.jsonl, GAK blokir.
set -uo pipefail

SRC_AG=~/jarvis/action_gate
DST_AG=~/.hermes/action_gate
SRC_PL=~/jarvis/plugins/action_gate_v2
DST_PL=~/.hermes/plugins/action_gate_v2

echo "=== [1] sinkron engine action_gate terbaru ==="
mkdir -p "$DST_AG"
cp -f "$SRC_AG/action_gate.py" "$SRC_AG/action_gate_rules.json" "$SRC_AG/lessons_logger.py" "$SRC_AG/gate_hook.py" "$DST_AG/"
ls -la "$DST_AG"

echo; echo "=== [2] deploy plugin action_gate_v2 ==="
mkdir -p "$DST_PL"
cp -f "$SRC_PL/plugin.yaml" "$SRC_PL/__init__.py" "$DST_PL/"
ls -la "$DST_PL"

echo; echo "=== [3] py_compile plugin + engine ==="
python3 -m py_compile "$DST_PL/__init__.py" "$DST_AG/gate_hook.py" "$DST_AG/action_gate.py" && echo "PY_OK"

echo; echo "=== [4] smoke-test: load plugin + panggil pre_tool_call (mode default shadow) ==="
python3 - <<'PY'
import os, sys, importlib.util
p = os.path.expanduser("~/.hermes/plugins/action_gate_v2/__init__.py")
spec = importlib.util.spec_from_file_location("ag_v2_smoke", p)
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
# shadow: dua-duanya WAJIB return None (observe-only, gak blokir) walau yg kedua DANGER
r1 = m.pre_tool_call(tool_name="read_file", args={"path": "/etc/hosts"})
r2 = m.pre_tool_call(tool_name="terminal", args={"command": "rm -rf ~/.hermes/config.yaml"})
print("read_file            ->", r1)
print("terminal rm config   ->", r2)
ok = (r1 is None and r2 is None)
print("RESULT:", "PASS (shadow: kedua None = observe-only)" if ok else "FAIL (shadow harusnya gak ngeblok)")
PY

echo; echo "=== [5] CATATAN (penting) ==="
echo "- Plugin ke-DISCOVER cuma setelah RESTART gateway (reload/SIGUSR1 gak rediscover plugin baru)."
echo "  Restart BUTUH GO Arif (~210s): systemctl --user restart hermes-gateway"
echo "- Verifikasi shadow setelah restart: kasih Jarvis tugas pakai tool/terminal ->"
echo "  tail -f ~/.hermes/action_gate/decisions.jsonl  (harus keisi; allow_execution:true walau action_class DANGER)"
echo "- Cek plugin ke-load: journalctl --user -u hermes-gateway | grep -i action_gate_v2  (cari 'registered')"
echo "- Naik LIVE (setelah observe shadow bersih): set ACTION_GATE_MODE=live di env gateway lalu restart."
echo "- KILL-SWITCH: ACTION_GATE_MODE=off. ROLLBACK: rm -rf $DST_PL ; systemctl --user restart hermes-gateway"
