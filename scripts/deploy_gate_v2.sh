#!/usr/bin/env bash
# DEPLOY action-gate v2: colok gate_hook ke tool_executor.py (chokepoint eksekusi tool).
# AMAN: backup + patch idempotent (anchor ASCII unik) + py_compile + AUTO-RESTORE kalau gagal.
# Mode default = SHADOW (gate_hook default) -> cuma LOG, GAK blokir. TIDAK restart gateway (itu langkah +GO terpisah).
# Naik ke LIVE nanti: set ACTION_GATE_MODE=live di env gateway, setelah verifikasi log shadow.
set -uo pipefail

TE=~/.hermes/hermes-agent/agent/tool_executor.py
SRC=~/jarvis/action_gate
DST=~/.hermes/action_gate

echo "=== [1] pastiin action_gate terbaru ter-deploy ==="
mkdir -p "$DST"
cp -f "$SRC/action_gate.py" "$SRC/action_gate_rules.json" "$SRC/lessons_logger.py" "$SRC/gate_hook.py" "$DST/"
ls "$DST"

echo; echo "=== [2] patch tool_executor.py (backup + insert + py_compile + auto-restore) ==="
python3 - "$TE" <<'PY'
import sys, pathlib, shutil, time
te = pathlib.Path(sys.argv[1])
src = te.read_text()
if "ACTION-GATE v2" in src:
    print("RESULT: SKIP (tool_executor sudah ke-patch)"); raise SystemExit(0)

ANCHOR = "Checkpoint preflight (only for tools that will execute)"
lines = src.split("\n")
idx = next((i for i, l in enumerate(lines) if ANCHOR in l), None)
if idx is None:
    print("RESULT: ABORT (anchor gak ketemu). File TIDAK diubah."); raise SystemExit(0)

ind = lines[idx][:len(lines[idx]) - len(lines[idx].lstrip())]   # indent baris anchor
i2 = ind + "    "; i3 = ind + "        "; i4 = ind + "            "
block = [
  ind + "# -- ACTION-GATE v2 (shadow|mock|live) --",
  ind + "if block_result is None:",
  i2 + "try:",
  i3 + "import sys as _agsys, os as _agos",
  i3 + "_agp = _agos.path.expanduser('~/.hermes/action_gate')",
  i3 + "if _agp not in _agsys.path: _agsys.path.insert(0, _agp)",
  i3 + "from gate_hook import gate_tool as _gate_tool",
  i3 + "_ag_allow, _ag_dec = _gate_tool(function_name, function_args)",
  i3 + "if not _ag_allow:",
  i4 + "try:",
  i4 + "    from agent.tool_guardrails import ToolGuardrailDecision as _AGD",
  i4 + "    _agm = 'ACTION-GATE ' + str(_ag_dec.get('action_class')) + ': ' + str(_ag_dec.get('reason'))",
  i4 + "    block_result = agent._guardrail_block_result(_AGD(action='block', message=_agm))",
  i4 + "except Exception:",
  i4 + "    block_result = 'BLOCKED by action-gate: ' + str(_ag_dec.get('reason'))",  # fail-CLOSED
  i4 + "blocked_by_guardrail = True",
  i4 + "_emit_terminal_post_tool_call(agent, function_name=function_name, function_args=function_args, result=block_result, effective_task_id=effective_task_id, tool_call_id=getattr(tool_call, 'id', '') or '', status='blocked', error_type='action_gate_block', error_message=str(_ag_dec.get('reason') or 'Blocked by action-gate'))",
  i2 + "except Exception:",
  i3 + "pass",
  "",
]
lines[idx:idx] = block
newsrc = "\n".join(lines)

bak = pathlib.Path(str(te) + ".bak." + time.strftime("%Y%m%d_%H%M%S"))
shutil.copy(te, bak); print("BACKUP:", bak)
te.write_text(newsrc)

import subprocess
r = subprocess.run([sys.executable, "-m", "py_compile", str(te)], capture_output=True, text=True)
if r.returncode != 0:
    shutil.copy(bak, te)
    print("RESULT: FAILED_RESTORED (py_compile error) ->", r.stderr.strip()[:200])
else:
    print("RESULT: SUCCESS (tool_executor ke-patch, py_compile OK). Mode=shadow (default).")
PY

echo; echo "=== [3] bukti insert ==="
grep -n "ACTION-GATE v2\|gate_tool(function_name" "$TE" | head

echo; echo "=== [4] CATATAN ==="
echo "Patch ke-load HANYA setelah RESTART GATEWAY. Mode default = shadow (log-only, gak blokir)."
echo "Restart (BUTUH GO Arif, nyangkut ~210s): systemctl --user restart hermes-gateway"
echo "Setelah restart + ada tool-call -> cek log: tail -f ~/.hermes/action_gate/decisions.jsonl"
echo "ROLLBACK: cp ${TE}.bak.<ts> ${TE} ; systemctl --user restart hermes-gateway"
