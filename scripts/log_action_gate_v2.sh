#!/usr/bin/env bash
# Catat milestone action-gate v2 (wiring shadow) ke event log Jarvis (idempotent).
set -uo pipefail
LOG="$HOME/.hermes/state/ARIF_STACK_EVENT_LOG.md"
MARKER="EVENT_20260629_ACTION_GATE_V2_SHADOW"
mkdir -p "$(dirname "$LOG")"; [ -f "$LOG" ] || printf '# ARIF STACK EVENT LOG\n' > "$LOG"
if grep -q "$MARKER" "$LOG" 2>/dev/null; then
  echo "RESULT: SKIP ($MARKER sudah ada)"
else
  cat >> "$LOG" <<'ENTRY'

---
## [2026-06-29] EVENT_20260629_ACTION_GATE_V2_SHADOW — Action-Gate v2 WIRING LIVE di shadow
- Gate v2 ke-wire ke chokepoint eksekusi tool lewat PLUGIN `action_gate_v2` (hook pre_tool_call), BUKAN patch core.
  tool_executor.py di-restore ke clean (patch salah-tempat dicopot). Coverage penuh: pre_tool_call kena
  concurrent + sequential + invoke_tool (get_pre_tool_call_block_message).
- Plugin = adapter tipis -> ~/.hermes/action_gate/gate_hook.gate_tool. shadow/mock=observe(None); live=block NEEDS_APPROVAL/REFUSE. fail-open di shadow.
- Discovery OPT-IN: plugin WAJIB didaftarin di config.yaml plugins.enabled (root cause plugin gak load pertama kali).
- Ruleset final (teruji 21/21): READ-list util-baca -> AUTO_OK; redirect '>' ke protected ditutup; command MAJEMUK
  (;/&&/||/|/newline, hormati kutip, heredoc tak dipecah) -> verdict PALING KETAT menang (anti prefix-masking);
  interpreter (python3/bash/make/...) SENGAJA tetap NEEDS_APPROVAL (anti gate-bypass kode arbitrer).
- LIVE-PROOF (shadow): plugin registered di gateway PID 466207 (16:51); marker reason "[majemuk]" muncul di
  decisions.jsonl post-restart = bukti behavioral ruleset baru kepake di proses yg melayani.
- CATATAN VERIFY: port 9119 = proses DASHBOARD (beda proses); gate fire di proses GATEWAY (hermes_cli.main gateway run).
  Verify liveness gate via grep "[majemuk]" decisions.jsonl, JANGAN via PID listener 9119.
- STATUS: SHADOW, allow_execution:true semua (zero impact). BELUM enforce.
- NEXT (sebelum live): observe trafik ORGANIK bbrp hari -> whitelist data-driven -> keputusan interpreter -> ACTION_GATE_MODE=live + restart (GO Arif).
- KILL-SWITCH: ACTION_GATE_MODE=off. ROLLBACK plugin: rm -rf ~/.hermes/plugins/action_gate_v2 + restart gateway. Config: cp config.yaml.bak.<ts>.
- Repo: arifibnsawir-svg/jarvis, branch feat/action-gate-v2-plugin (PR #2). Checkpoint detail: HANDOFF_CHECKPOINT.md 12.14/12.15/12.16.
ENTRY
  echo "RESULT: APPENDED to $LOG"
fi
echo "=== PROOF ==="
grep -n "$MARKER" "$LOG" || echo "(marker not found)"
tail -n 6 "$LOG"
