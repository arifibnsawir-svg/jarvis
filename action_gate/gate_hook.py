#!/usr/bin/env python3
"""
GATE HOOK -- shim integrasi action-gate ke tool_executor hermes-agent.
MODE (env ACTION_GATE_MODE): off | shadow | enforce   (default: shadow = log-only, gak blokir)
  off     -> bypass total (kill-switch).
  shadow  -> klasifikasi + LOG tiap aksi, TAPI selalu allow (zero-risk observe).
  enforce -> REFUSE/NEEDS_APPROVAL beneran ngeblok.
Dipanggil dari tool_executor.py SEBELUM eksekusi: gate_tool(function_name, function_args) -> (allow: bool, decision: dict)
"""
import os, json, time

try:
    from action_gate import classify_tool
except Exception:
    import sys, os as _os
    sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
    from action_gate import classify_tool

MODE = os.environ.get("ACTION_GATE_MODE", "shadow").lower()
LOG = os.path.expanduser("~/.hermes/action_gate/decisions.log")

def _log(rec):
    try:
        os.makedirs(os.path.dirname(LOG), exist_ok=True)
        with open(LOG, "a") as f:
            f.write(json.dumps(rec, ensure_ascii=False) + "\n")
    except Exception:
        pass

def gate_tool(function_name, function_args):
    mode = os.environ.get("ACTION_GATE_MODE", MODE).lower()
    if mode == "off":
        return True, {"verdict": "AUTO_OK", "reason": "gate off", "mode": "off"}
    try:
        d = classify_tool(function_name, function_args)
    except Exception as e:
        # gagal klasifikasi -> JANGAN ganggu agent: allow + log (fail-open di shadow; fail-open aman krn cuma observe)
        _log({"ts": time.time(), "tool": function_name, "verdict": "ERROR", "reason": repr(e), "mode": mode})
        return True, {"verdict": "ERROR", "reason": repr(e)}
    rec = {"ts": time.time(), "tool": function_name, "verdict": d["verdict"],
           "reason": d.get("reason"), "requires": d.get("requires", []), "mode": mode}
    _log(rec)
    if mode == "shadow":
        return True, d            # observe only, never block
    # enforce
    if d["verdict"] in ("REFUSE", "NEEDS_APPROVAL"):
        return False, d
    return True, d

if __name__ == "__main__":
    import sys
    fn = sys.argv[1] if len(sys.argv) > 1 else "terminal"
    args = json.loads(sys.argv[2]) if len(sys.argv) > 2 else {"command": "ls -la"}
    print(gate_tool(fn, args))
