#!/usr/bin/env python3
"""
GATE HOOK -- shim integrasi action-gate ke tool_executor hermes-agent.
Taksonomi & fase SELARAS dgn guardian_gate v0 (command-plane-v0): shadow | mock | live.
MODE (env ACTION_GATE_MODE), default 'shadow':
  off    -> bypass total (kill-switch).
  shadow -> classify + LOG, SELALU allow (zero-risk observe). [= fase v0 lo]
  mock   -> classify + LOG + tandai would_block (boundary test), TAPI masih allow.
  live   -> REFUSE/NEEDS_APPROVAL beneran ngeblok.
Dipanggil dari tool_executor SEBELUM eksekusi: gate_tool(function_name, function_args) -> (allow: bool, decision: dict)
"""
import os, json, time

try:
    from action_gate import classify_tool, to_unified
except Exception:
    import sys, os as _os
    sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
    from action_gate import classify_tool, to_unified

DEFAULT_MODE = os.environ.get("ACTION_GATE_MODE", "shadow").lower()
LOG = os.path.expanduser("~/.hermes/action_gate/decisions.jsonl")

def _log(rec):
    try:
        os.makedirs(os.path.dirname(LOG), exist_ok=True)
        with open(LOG, "a") as f:
            f.write(json.dumps(rec, ensure_ascii=False) + "\n")
    except Exception:
        pass  # gate gagal log JANGAN ganggu agent (fail-open)

def gate_tool(function_name, function_args):
    mode = os.environ.get("ACTION_GATE_MODE", DEFAULT_MODE).lower()
    if mode == "off":
        return True, {"verdict": "AUTO_OK", "action_class": "SAFE", "decision_mode": "off"}
    try:
        raw = classify_tool(function_name, function_args)
    except Exception as e:
        rec = {"timestamp": time.time(), "gate_version": "v1_action", "decision_mode": mode,
               "tool": function_name, "verdict": "INBOUND_FAIL", "action_class": "INBOUND_FAIL",
               "reason": repr(e), "allow_execution": True}
        _log(rec)
        return True, rec  # fail-open: jangan matiin agent gara2 gate error
    cmd = (function_args or {}).get("command") if isinstance(function_args, dict) else None
    dec = to_unified(raw, decision_mode=mode, tool=function_name, command=cmd)
    _log(dec)
    if mode in ("shadow", "mock"):
        return True, dec                       # observe only, gak pernah blokir
    # live
    return bool(dec["allow_execution"]), dec   # block kalau REFUSE/NEEDS_APPROVAL

if __name__ == "__main__":
    import sys
    fn = sys.argv[1] if len(sys.argv) > 1 else "terminal"
    args = json.loads(sys.argv[2]) if len(sys.argv) > 2 else {"command": "ls -la"}
    print(json.dumps(gate_tool(fn, args)[1], ensure_ascii=False, indent=2))
