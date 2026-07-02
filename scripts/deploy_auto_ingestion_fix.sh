#!/usr/bin/env bash
# Deploy crystallize_gateway.sh + strengthen auto-ingestion directive
set -euo pipefail
USER_MD="${HERMES_USER_MD:-$HOME/.hermes/memories/USER.md}"
SCRIPTS_DIR="$HOME/.hermes/scripts"
GATEWAY_SCRIPT="$SCRIPTS_DIR/crystallize_gateway.sh"
TS="$(date +%Y%m%d_%H%M%S)"
[ -f "$USER_MD" ] || { echo "ERROR: USER.md tidak ada"; exit 2; }
cp "$USER_MD" "${USER_MD}.bak.${TS}"
echo "backup: ${USER_MD}.bak.${TS}"
echo "=== [1] Install Crystallization Gateway CLI ==="
mkdir -p "$SCRIPTS_DIR"
cp -f ~/jarvis/scripts/crystallize_gateway.sh "$GATEWAY_SCRIPT"
chmod +x "$GATEWAY_SCRIPT"
ls -la "$GATEWAY_SCRIPT"
M="## AUTO-INGESTION — MANDATORY AFTER EVERY TURN"
if grep -qF "$M" "$USER_MD"; then
  echo "SKIP: directive already exists"
else
  cat >> "$USER_MD" <<'DIRECTIVE'

## AUTO-INGESTION — MANDATORY AFTER EVERY TURN
Setelah SETIAP jawaban, jalankan auto-ingestion:
  /home/arif/.hermes/hermes-agent/venv/bin/python ~/.hermes/scripts/context_annotated_ingestion.py --text "<pesan user>" --session "<session_id>"
Trivial message auto-skip. Mythos speculation WAJIB masuk episodic.
Setelah ingestion: boost --topic "<topik>"
Zero Soul Loss: ide liar jam 2 pagi tidak hilang.
DIRECTIVE
  echo "OK: directive appended"
fi
echo "=== DEPLOY COMPLETE ==="
echo "rollback: cp ${USER_MD}.bak.${TS} $USER_MD"
