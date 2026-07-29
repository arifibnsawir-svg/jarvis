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

PHASE A2: NEEDS_APPROVAL bridge to Core Hermes approval.
- When verdict is NEEDS_APPROVAL and ACTION_GATE_ENFORCE is NOT 'refuse_only',
  route through existing Core Hermes _await_gateway_decision() for blocking approval.
- Core Hermes owns all state (queue, lock, Event, notify callback, Telegram UI).
- No new approval module or state store is introduced.
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

def _resolve_needs_approval_core(dec):
    """Route NEEDS_APPROVAL through Core Hermes blocking approval.

    Returns (allow: bool, decision: dict).
    On any failure (no session, no callback, import error) -> fail-closed (block).
    """
    try:
        from tools.approval import (
            _await_gateway_decision,
            _gateway_notify_cbs,
            get_current_session_key,
            _lock,
        )
    except ImportError:
        # Core approval not available (test environment, bare import)
        return False, {**dec, "core_approval": "unavailable_import"}

    session_key = get_current_session_key(default="")
    if not session_key:
        # No session key -> no way to route to Telegram -> fail-closed
        return False, {**dec, "core_approval": "no_session_key"}

    with _lock:
        notify_cb = _gateway_notify_cbs.get(session_key)

    if notify_cb is None:
        # No notify callback registered (non-gateway context, cron, etc.)
        # Fail-closed: cannot route to user -> block
        return False, {**dec, "core_approval": "no_notify_callback"}

    # Build approval_data compatible with Core Hermes format
    reason = dec.get("reason", "Action-Gate flagged this action")
    command = dec.get("command", "") or ""
    pattern_key = f"action_gate:{reason}"

    approval_data = {
        "command": command,
        "pattern_key": pattern_key,
        "pattern_keys": [pattern_key],
        "description": f"Action-Gate: {reason}",
    }

    try:
        decision = _await_gateway_decision(
            session_key, notify_cb, approval_data, surface="gateway"
        )
    except Exception as exc:
        return False, {**dec, "core_approval": f"exception:{exc}"}

    if decision.get("notify_failed"):
        return False, {**dec, "core_approval": "notify_failed"}

    resolved = decision.get("resolved", False)
    choice = decision.get("choice")

    if not resolved or choice is None or choice == "deny":
        # Timeout (not resolved), explicit deny, or no choice -> block
        outcome = "timeout" if not resolved else (choice or "no_choice")
        return False, {**dec, "core_approval": f"denied:{outcome}"}

    # Approved (once, session, always) -> allow execution
    return True, {**dec, "core_approval": f"approved:{choice}"}


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
    verdict = dec.get("verdict", "")
    enforce = os.environ.get("ACTION_GATE_ENFORCE", "refuse_only").lower()

    # REFUSE -> always block (existing behavior, no change)
    if verdict == "REFUSE":
        return False, dec

    # NEEDS_APPROVAL with enforce != refuse_only -> route through Core approval
    if verdict == "NEEDS_APPROVAL" and enforce != "refuse_only":
        return _resolve_needs_approval_core(dec)

    # NEEDS_APPROVAL with refuse_only -> pass through (current behavior, no change)
    # AUTO_OK / AUTO_OK_W_BACKUP -> always allow (no change)
    return bool(dec["allow_execution"]), dec


if __name__ == "__main__":
    import sys
    fn = sys.argv[1] if len(sys.argv) > 1 else "terminal"
    args = json.loads(sys.argv[2]) if len(sys.argv) > 2 else {"command": "ls -la"}
    print(json.dumps(gate_tool(fn, args)[1], ensure_ascii=False, indent=2))
