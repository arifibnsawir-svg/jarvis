#!/usr/bin/env bash
# Tune council timeout: naikkan guardian_router COMBO_TIMEOUTS jarvis-reason 150->240.
# Reviewer A di council sering timeout (150s tidak cukup buat reasoning model).
# SOFT layer: edit guardian_router.py, backup, restart guardian service.
# Idempotent: skip kalau udah >=240.
# Run ON THE ACER SERVER.
set -euo pipefail

GR="$HOME/.hermes/scripts/guardian_router.py"
[ -f "$GR" ] || { echo "ERROR: guardian_router.py tidak ada di $GR" >&2; exit 2; }

CURRENT=$(grep -oP '"jarvis-reason":\s*\K\d+' "$GR" | head -1)
echo "Current jarvis-reason timeout: ${CURRENT:-?}"

if [ -n "$CURRENT" ] && [ "$CURRENT" -ge 240 ]; then
  echo "SKIP: timeout sudah >=240 (${CURRENT})."
  exit 0
fi

TS=$(date +%Y%m%d_%H%M%S)
cp "$GR" "$GR.bak.$TS"
echo "BACKUP: $GR.bak.$TS"

sed -i 's/"jarvis-reason": 150/"jarvis-reason": 240/g' "$GR"
NEW=$(grep -oP '"jarvis-reason":\s*\K\d+' "$GR" | head -1)
echo "New jarvis-reason timeout: ${NEW:-?}"

python3 -c "import py_compile; py_compile.compile('$GR', doraise=True)" 2>&1 && echo "SYNTAX: OK"

echo "Restarting hermes-guardian..."
systemctl --user restart hermes-guardian.service 2>&1
echo "Restart triggered."

echo "=== PROOF ==="
grep "jarvis-reason" "$GR" | head -3
echo "Rollback: cp $GR.bak.$TS $GR && systemctl --user restart hermes-guardian.service"
