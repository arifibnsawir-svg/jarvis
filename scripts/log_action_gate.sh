#!/usr/bin/env bash
# Catat milestone action-gate v1 ke event log Jarvis (idempotent).
set -uo pipefail
LOG="$HOME/.hermes/state/ARIF_STACK_EVENT_LOG.md"
MARKER="EVENT_20260629_ACTION_GATE_V1"
mkdir -p "$(dirname "$LOG")"; [ -f "$LOG" ] || printf '# ARIF STACK EVENT LOG\n' > "$LOG"
if grep -q "$MARKER" "$LOG" 2>/dev/null; then
  echo "RESULT: SKIP ($MARKER sudah ada)"
else
  cat >> "$LOG" <<'ENTRY'

---
## [2026-06-29] EVENT_20260629_ACTION_GATE_V1 — Action-Gate v1 + Mistake-Memory LIVE
- Jarvis jadi AUTO-AGENT terkendali. Gate: ~/.hermes/action_gate/action_gate.py (vonis AUTO_OK/AUTO_OK_W_BACKUP/NEEDS_APPROVAL/REFUSE).
- Aturan tunable di action_gate_rules.json. git push main=AUTO; force-push=approval; restart svc=AUTO+backup+healthcheck+rollback; rm protected/exfil secret=REFUSE.
- Mistake-memory: gagal/refuse/rollback/koreksi -> auto-log ke ~/.hermes/memories/LESSONS.md (recall sebelum task sejenis). Promosi jadi aturan = review Arif.
- Direktif always-on di USER.md (action-gate-routing + mistake-memory). Self-test 10/10 PASS.
- ENFORCEMENT v1 = advisory via direktif. v2 (belum) = wire ke lapis eksekusi hermes-agent.
- Deploy: cd ~/jarvis && git pull && bash scripts/deploy_action_gate.sh
ENTRY
  echo "RESULT: APPENDED to $LOG"
fi
grep -n "$MARKER" "$LOG" || echo "(marker not found)"
