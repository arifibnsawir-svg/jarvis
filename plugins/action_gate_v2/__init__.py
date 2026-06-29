"""
action_gate_v2 -- plugin Hermes yang nyolok action-gate ke hook ``pre_tool_call``.

KENAPA PLUGIN (bukan patch core): chokepoint ``pre_tool_call`` ke-dispatch dari SEMUA
jalur eksekusi tool -- concurrent (tool_executor.py), sequential (tool_executor.py),
dan invoke_tool (agent_runtime_helpers.py) -- lewat get_pre_tool_call_block_message().
Jadi satu plugin = coverage penuh, TANPA nyentuh source gateway (blast-radius kecil,
rollback = hapus folder plugin).

ALUR: tiap tool-call -> gate_tool(tool_name, args) (di ~/.hermes/action_gate/gate_hook.py).
  - shadow/mock (default): gate_tool SELALU allow + nge-LOG ke
    ~/.hermes/action_gate/decisions.jsonl. Handler return None -> observer-only,
    gak ngeblok apa pun (zero-risk observe).
  - live: kalau gate nolak (NEEDS_APPROVAL/REFUSE) -> return
    {"action": "block", "message": ...} -> get_pre_tool_call_block_message nangkep ->
    tool gak jalan, agent terima error JSON.

Mode di-set via env ACTION_GATE_MODE (off|shadow|mock|live); default shadow (gate_hook).
FAIL-OPEN: kalau import/gate error, JANGAN matiin agent -> return None (lolos).
Penegakan keras (fail-closed) di-handle gate_hook saat mode=live, bukan di sini.
"""
import os
import sys
import logging

logger = logging.getLogger("action_gate_v2")

_AG_DIR = os.path.expanduser("~/.hermes/action_gate")
if _AG_DIR not in sys.path:
    sys.path.insert(0, _AG_DIR)

try:
    from gate_hook import gate_tool as _gate_tool
except Exception as _e:  # pragma: no cover
    _gate_tool = None
    logger.warning("action_gate_v2: gagal import gate_tool (%r) -> plugin no-op (fail-open)", _e)


def pre_tool_call(tool_name=None, args=None, **kwargs):
    """Gate satu tool-call.

    Return None  -> lolos / observe-only (shadow/mock, atau verdict AUTO_OK* di live).
    Return dict  -> {"action": "block", "message": ...} hanya saat live + verdict nolak.
    """
    if _gate_tool is None:
        return None  # gate gak ke-load -> fail-open
    try:
        allow, dec = _gate_tool(tool_name, args)
    except Exception as e:
        # fail-open: jangan matiin agent gara-gara gate error
        logger.warning("action_gate_v2: gate_tool error (%r) -> allow", e)
        return None
    if allow:
        return None  # observe-only (shadow/mock) atau AUTO_OK/AUTO_OK_W_BACKUP (live)
    verdict = dec.get("verdict", "BLOCKED")
    reason = dec.get("reason", "")
    mode = dec.get("decision_mode", "live")
    return {
        "action": "block",
        "message": "ACTION-GATE {v}: {r} (mode={m})".format(v=verdict, r=reason, m=mode),
    }


def register(ctx):
    ctx.register_hook("pre_tool_call", pre_tool_call)
    logger.info("action_gate_v2 registered (pre_tool_call)")
