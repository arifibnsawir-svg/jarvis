#!/usr/bin/env bash
# =============================================================================
# deploy_context_ingestion.sh
# -----------------------------------------------------------------------------
# Deploy Context-Annotated Ingestion — auto-classify user messages and
# ingest into Temporal Tiered Memory without explicit commands.
#
# This closes the Grand Design item: "Context-Annotated Ingestion" —
# Jarvis automatically classifies your messages and stores them in the
# right memory layer with the right tags, content type, and context wrapper.
#
# SOFT layer: directive in USER.md. No restart needed.
# =============================================================================
set -euo pipefail

USER_MD="${HERMES_USER_MD:-$HOME/.hermes/memories/USER.md}"
SCRIPTS_DIR="$HOME/.hermes/scripts"
INGEST_SCRIPT="$SCRIPTS_DIR/context_annotated_ingestion.py"
VENV="${HERMES_VENV:-$HOME/.hermes/hermes-agent/venv/bin/python}"

[ -f "$USER_MD" ] || { echo "ERROR: USER.md tidak ada di $USER_MD" >&2; exit 2; }

TS="$(date +%Y%m%d_%H%M%S)"
cp "$USER_MD" "${USER_MD}.bak.${TS}"
echo "backup: ${USER_MD}.bak.${TS}"

echo "=== [1] Install ingestion engine ==="
mkdir -p "$SCRIPTS_DIR"
cp -f ~/jarvis/scripts/context_annotated_ingestion.py "$INGEST_SCRIPT"
chmod +x "$INGEST_SCRIPT"

echo "=== [2] Smoke test: classifier ==="
"$VENV" "$INGEST_SCRIPT" --text "bro, analisa bisnis saas gue dong, churn rate-nya gede banget" --classify-only --json 2>&1
echo "---"
"$VENV" "$INGEST_SCRIPT" --text "kita putusin margin kiri 4cm untuk tugas Dosen Slamet" --classify-only --json 2>&1
echo "---"
"$VENV" "$INGEST_SCRIPT" --text "gimana kalau kita pivot ke subscription model?" --classify-only --json 2>&1

echo "=== [3] Wire USER.md directive ==="
M="## CONTEXT-ANNOTATED INGESTION — AUTO-MEMORY"
if grep -qF "$M" "$USER_MD"; then
  echo "SKIP: directive already exists: $M"
else
  cat >> "$USER_MD" <<'DIRECTIVE'

## CONTEXT-ANNOTATED INGESTION — AUTO-MEMORY
Setiap kali user mengirim pesan, klasifikasikan otomatis menggunakan context_annotated_ingestion.py, lalu ingest ke Temporal Tiered Memory. Ini berjalan otomatis — user tidak perlu mengetik perintah explicit.

Command:
  /home/arif/.hermes/hermes-agent/venv/bin/python ~/.hermes/scripts/context_annotated_ingestion.py --text "<isi pesan user>" --session "<session_id>"

Klasifikasi otomatis:
  - speculation: pesan mengandung "mungkin", "gimana kalau", "coba", spekulasi
  - decision: pesan mengandung "putuskan", "final", "deal", kesimpulan
  - fact: pesan mengandung "berdasarkan data", "hasilnya", fakta
  - insight: pesan mengandung "insight", "ternyata", "learning"
  - rule: pesan mengandung "aturan", "dosen", "wajib", ketentuan
  - general: pesan trivial (sapaan, tanya fakta singkat) → SKIP ingestion

Tags otomatis diekstrak dari domain keywords (akademik, bisnis, infra, brainstorm) dan entitas (nama dosen, proyek, tools).

Kalau classifier salah: koreksi manual dengan:
  python3 ~/.hermes/scripts/temporal_tiered_memory.py ingest --text "..." --type <correct_type> --tags <correct_tags>

Kalau pesan trivial ("halo", "ok", "thank you") → JANGAN ingest. Classifier otomatis akan skip.

Auto-ingestion ini memastikan Zero Soul Loss: ide liar jam 2 pagi lo otomatis masuk episodic memory dengan decay 7 hari, keputusan final lo masuk dengan decay 30 hari.
DIRECTIVE
  echo "OK: directive appended"
fi

echo "=== [4] Verify ==="
ls -la "$INGEST_SCRIPT"
grep -cF "$M" "$USER_MD"
echo "=== DEPLOY COMPLETE ==="
echo "rollback: cp ${USER_MD}.bak.${TS} $USER_MD && rm -f $INGEST_SCRIPT"
