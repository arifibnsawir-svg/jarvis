#!/usr/bin/env bash
# =============================================================================
# deploy_dream_cycle.sh
# -----------------------------------------------------------------------------
# Deploy Jarvis DREAM CYCLE — overnight cron for memory consolidation.
# This is the final piece of the Grand Design memory loop.
#
# What the dream cycle does every night:
#   1. Consolidate episodic → crystallized (pattern detection ≥2 sessions)
#   2. Surface decayed entries below 10% weight
#   3. Generate morning pulse report
#   4. Detect contradictions across entries
#
# SOFT layer: cron entry + USER.md directive. No restart.
# =============================================================================
set -euo pipefail

USER_MD="${HERMES_USER_MD:-$HOME/.hermes/memories/USER.md}"
SCRIPTS_DIR="$HOME/.hermes/scripts"
DREAM_SCRIPT="$SCRIPTS_DIR/dream_cycle.sh"
TS="$(date +%Y%m%d_%H%M%S)"

[ -f "$USER_MD" ] || { echo "ERROR: USER.md tidak ada di $USER_MD" >&2; exit 2; }
cp "$USER_MD" "${USER_MD}.bak.${TS}"
echo "backup: ${USER_MD}.bak.${TS}"

echo "=== [1] Install dream cycle script ==="
mkdir -p "$SCRIPTS_DIR"
cp -f ~/jarvis/scripts/dream_cycle.sh "$DREAM_SCRIPT"
chmod +x "$DREAM_SCRIPT"

echo "=== [2] Manual test ==="
bash "$DREAM_SCRIPT" 2>&1 | tail -20

echo "=== [3] Wire directive to USER.md ==="
M="## DREAM CYCLE — OVERNIGHT MEMORY CONSOLIDATION"
if grep -qF "$M" "$USER_MD"; then
  echo "SKIP: directive already exists: $M"
else
  cat >> "$USER_MD" <<'DIRECTIVE'

## DREAM CYCLE — OVERNIGHT MEMORY CONSOLIDATION
Setiap malam (atau saat diminta via /dream), jalankan siklus konsolidasi
memori untuk menjaga otak Jarvis tetap tajam:

  bash ~/.hermes/scripts/dream_cycle.sh

Yang dilakukan dream cycle:
1. Consolidation — deteksi pattern dari 2+ entri episodic → auto-promosi
   ke crystallized memory (permanen).
2. Decay pruning — identifikasi entri dengan bobot di bawah 10%.
3. Morning pulse — generate laporan singkat: apa yang baru, apa yang
   hampir hilang, pola apa yang terdeteksi.
4. Contradiction detection — cek apakah ada entri yang saling bertentangan.

Report disimpan di: ~/.hermes/memory/dream_cycle_report.md

Jalankan minimal 1x sehari. Ideal: sebagai cron job tiap jam 3 pagi.
Untuk memasang cron:
  crontab -e
  tambahkan: 0 3 * * * bash ~/.hermes/scripts/dream_cycle.sh

Dream cycle memastikan Jarvis "bangun lebih pintar setiap pagi" —
chaos terorganisir, pattern terkristalisasi, noise didecay.
DIRECTIVE
  echo "OK: directive appended"
fi

echo "=== [4] Cron suggestion ==="
echo "To auto-run nightly at 3am, add this to crontab:"
echo "  0 3 * * * bash $DREAM_SCRIPT"
echo ""
echo "=== DEPLOY COMPLETE ==="
echo "Dream cycle READY. Run manually: bash $DREAM_SCRIPT"
echo "Auto nightly: add to crontab as shown above."
echo "rollback: cp ${USER_MD}.bak.${TS} $USER_MD && rm -f $DREAM_SCRIPT"
