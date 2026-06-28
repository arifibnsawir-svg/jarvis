#!/usr/bin/env bash
# Catat hasil swap council -> jarvis-reason ke event log Jarvis (idempotent).
set -uo pipefail
LOG="$HOME/.hermes/state/ARIF_STACK_EVENT_LOG.md"
MARKER="EVENT_20260629_COUNCIL_SWAP_JARVIS_REASON"
mkdir -p "$(dirname "$LOG")"; [ -f "$LOG" ] || printf '# ARIF STACK EVENT LOG\n' > "$LOG"
if grep -q "$MARKER" "$LOG" 2>/dev/null; then
  echo "RESULT: SKIP ($MARKER sudah ada)"
else
  cat >> "$LOG" <<'ENTRY'

---
## [2026-06-29] EVENT_20260629_COUNCIL_SWAP_JARVIS_REASON — PIPA4 council pakai jarvis-reason (DONE)
- Council PIPA4 (lapis ADVISORY) di-swap DailyFree -> jarvis-reason. Gate deterministik TIDAK berubah.
- guardian_router: jarvis-reason didaftarin di COMBO_MODEL_MAP + TIMEOUTS(150) + MAX_TOKENS(3000). Guardian di-restart. Backup guardian_router.py.bak.20260629_005231.
- 5 titik council di-swap (phase6a/6c/6d + phase7a). Backup *.bak.20260629_013417.
- VERIFIED: jarvis-reason via Guardian 20129 -> "43"; call_llm_via_guardian -> ERR None, OUT 43.
- enabled_default_skills = DEAD (jangan dipakai). DailyFree = 50-model RR gacha (jangan dipakai buat audit).
- ROLLBACK: cp *.bak.20260629_013417 (4 file council) ; cp guardian_router.py.bak.20260629_005231 + restart hermes-guardian.service.
- OPEN: kualitas council baru blm diuji di artefak nyata; cek model mati di combo jarvis-reason.
ENTRY
  echo "RESULT: APPENDED to $LOG"
fi
echo "=== PROOF ==="; grep -n "$MARKER" "$LOG" || echo "(marker not found)"
