"""
mistake_logger -- plugin Hermes: hook ``post_tool_call`` -> auto-log tool-call GAGAL ke LESSONS.md.

KENAPA INI (item C, mistake-memory deterministik): selama ini "Jarvis nyatat kesalahan"
cuma advisory (direktif + CLI lessons_logger). Jarvis bisa LUPA manggil. Plugin ini bikin
DETERMINISTIK: tiap tool-call yang error/blocked OTOMATIS ke-log -- tanpa andelin ingatan LLM.

ALUR: post_tool_call(**kwargs) -> kalau status error/blocked atau ada error_message ->
  lessons_logger.log_lesson(attempted, went_wrong, root_cause, next_time) ke
  ~/.hermes/memories/LESSONS.md. L1 auto-log = FAKTA saja (aman). Promosi jadi aturan
  always-on = WAJIB review Arif (BUKAN di sini -- anti skill-rot).

DESAIN AMAN:
- OBSERVER-ONLY: post_tool_call gak pernah ngeblok apa pun; selalu return None.
- FAIL-OPEN: error apa pun di plugin -> ditelan, agent gak keganggu.
- ANTI-SPAM: dedup in-memory (skip kalau (tool,error) identik udah ke-log di proses ini).
- KILL-SWITCH: env MISTAKE_LOGGER_OFF=1 -> plugin no-op.
"""
import os
import sys
import logging

logger = logging.getLogger("mistake_logger")

_AG_DIR = os.path.expanduser("~/.hermes/action_gate")
if _AG_DIR not in sys.path:
    sys.path.insert(0, _AG_DIR)

try:
    from lessons_logger import log_lesson as _log_lesson
except Exception as _e:  # pragma: no cover
    _log_lesson = None
    logger.warning("mistake_logger: gagal import lessons_logger (%r) -> no-op (fail-open)", _e)

# dedup in-memory (lifetime proses) biar LESSONS.md gak kebanjiran entri identik
_SEEN = set()
_FAIL_STATUS = {"error", "blocked", "failed", "failure", "timeout"}


def _truncate(s, n=300):
    s = str(s or "").strip().replace("\n", " ")
    return s[:n] + ("..." if len(s) > n else "")


def post_tool_call(**kwargs):
    """Observer: auto-log kalau tool-call gagal. SELALU return None (gak ngeblok)."""
    try:
        if os.environ.get("MISTAKE_LOGGER_OFF") == "1" or _log_lesson is None:
            return None

        status = str(kwargs.get("status") or "").lower()
        err_msg = kwargs.get("error_message") or kwargs.get("error") or ""
        err_type = kwargs.get("error_type") or ""
        name = kwargs.get("function_name") or kwargs.get("tool_name") or "?"
        args = kwargs.get("function_args") or kwargs.get("args") or {}

        is_fail = (status in _FAIL_STATUS) or bool(err_msg)
        if not is_fail:
            return None

        key = "{0}|{1}|{2}".format(name, err_type, _truncate(err_msg, 80))
        if key in _SEEN:
            return None
        _SEEN.add(key)

        # ringkas argumen (kunci aja, jangan nilai panjang)
        try:
            arg_keys = ",".join(list(args.keys())[:6]) if isinstance(args, dict) else ""
        except Exception:
            arg_keys = ""

        _log_lesson(
            attempted="tool {0}({1})".format(name, arg_keys),
            went_wrong=_truncate(err_msg) or "status={0}".format(status or "fail"),
            root_cause=str(err_type or "(unknown)"),
            corrective="(TBD - review Arif sebelum jadi aturan)",
        )
    except Exception as e:  # fail-open total
        logger.warning("mistake_logger: error saat log (%r) -> diabaikan", e)
    return None


def register(ctx):
    ctx.register_hook("post_tool_call", post_tool_call)
    logger.info("mistake_logger registered (post_tool_call)")
