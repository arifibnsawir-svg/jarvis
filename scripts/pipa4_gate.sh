#!/usr/bin/env bash
# pipa4_gate.sh -- wrapper TIPIS buat PIPA4 final gate (dry-run audit + council).
# Pakai: bash pipa4_gate.sh <artifact.pdf|docx> <constraint.json>
# Output: jalanin PIPA4 -> parse final_status + false_READY_count -> verdict PASS/NEEDS_WORK + exit code.
#   exit 0 = PASS (final_status READY_FOR_HUMAN_REVIEW & false_READY_count 0)
#   exit 1 = NEEDS_WORK (ada flag -> harus diperbaiki lalu re-gate)
#   exit 2 = error (file/arg/engine)
# READ-ONLY terhadap artefak (PIPA4 copy ke run_dir, original NEVER diubah).
set -uo pipefail

ART="${1:-}"; CON="${2:-}"
F="$HOME/.hermes/pipelines/pipa4/phase7a/pipa4_review_local.py"
PY="$HOME/.hermes/hermes-agent/venv/bin/python"; [ -x "$PY" ] || PY="python3"

if [ -z "$ART" ] || [ -z "$CON" ]; then
  echo "PIPA4_GATE: ERROR usage: bash pipa4_gate.sh <artifact.pdf|docx> <constraint.json>"; exit 2
fi
[ -f "$ART" ] || { echo "PIPA4_GATE: ERROR artifact tidak ada: $ART"; exit 2; }
[ -f "$CON" ] || { echo "PIPA4_GATE: ERROR constraint tidak ada: $CON"; exit 2; }
[ -f "$F" ]   || { echo "PIPA4_GATE: ERROR engine tidak ada: $F"; exit 2; }

OUT="$("$PY" "$F" --artifact "$ART" --constraints "$CON" --mode dry_run 2>&1)"
echo "$OUT"

STATUS="$(printf '%s\n' "$OUT" | grep -oE 'final_status:[[:space:]]*[A-Z_]+' | head -1 | awk '{print $2}')"
FREADY="$(printf '%s\n' "$OUT" | grep -oE 'false_READY_count:[[:space:]]*[0-9]+' | head -1 | awk '{print $2}')"

echo "==================== PIPA4 GATE VERDICT ===================="
echo "final_status      : ${STATUS:-?}"
echo "false_READY_count : ${FREADY:-?}"
if [ "$STATUS" = "READY_FOR_HUMAN_REVIEW" ] && [ "${FREADY:-1}" = "0" ]; then
  echo "VERDICT: PASS -> boleh deliver (sudah READY_FOR_HUMAN_REVIEW, no false-READY)"; exit 0
elif [ -z "$STATUS" ]; then
  echo "VERDICT: ERROR -> gate gak ngasih final_status (cek engine/extract). JANGAN klaim DONE."; exit 2
else
  echo "VERDICT: NEEDS_WORK -> status '${STATUS}'. PERBAIKI yang di-flag (lihat report PIPA4) lalu RE-GATE. JANGAN klaim DONE."; exit 1
fi
