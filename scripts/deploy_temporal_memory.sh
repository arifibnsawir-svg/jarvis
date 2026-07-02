#!/usr/bin/env bash
# =============================================================================
# deploy_temporal_memory.sh
# -----------------------------------------------------------------------------
# Deploy Temporal Tiered Memory — the cognitive backbone of Monster Jarvis.
#
# This is the memory layer that supports:
#   - Crystallization Gateway (Mythos → Fable transition)
#   - Signal Booster (re-mention resets decay)
#   - Memory Consolidation (pattern detection across sessions)
#   - Context-Aware Retrieval (tags + content-type scoring)
#
# FLEXIBLE by design:
#   - Tags are arbitrary strings — academic, business, brainstorming, anything
#   - Content types are extensible (speculation, decision, fact, insight, rule, etc.)
#   - Decay profiles tunable per type
#   - No hardcoded domain — works for academic, business, personal, R&D
#
# SOFT layer: append directive to USER.md. No restart needed.
# =============================================================================
set -euo pipefail

USER_MD="${HERMES_USER_MD:-$HOME/.hermes/memories/USER.md}"
SCRIPTS_DIR="$HOME/.hermes/scripts"
MEMORY_SCRIPT="$SCRIPTS_DIR/temporal_tiered_memory.py"
MEMORY_DIR="$HOME/.hermes/memory"
VENV="${HERMES_VENV:-$HOME/.hermes/hermes-agent/venv/bin/python}"

[ -f "$USER_MD" ] || { echo "ERROR: USER.md tidak ada di $USER_MD" >&2; exit 2; }

TS="$(date +%Y%m%d_%H%M%S)"
cp "$USER_MD" "${USER_MD}.bak.${TS}"
echo "backup: ${USER_MD}.bak.${TS}"

echo "=== [1] Install memory engine ==="
mkdir -p "$SCRIPTS_DIR" "$MEMORY_DIR"
cp -f ~/jarvis/memory/temporal_tiered_memory.py "$MEMORY_SCRIPT"
chmod +x "$MEMORY_SCRIPT"

echo "=== [2] Smoke test ==="
"$VENV" "$MEMORY_SCRIPT" stats 2>&1
echo "EXIT=$?"

echo "=== [3] Wire directive to USER.md (idempotent) ==="
M="## TEMPORAL TIERED MEMORY — AUTOMATIC INGESTION"
if grep -qF "$M" "$USER_MD"; then
  echo "SKIP: directive already exists: $M"
else
  cat >> "$USER_MD" <<'DIRECTIVE'

## TEMPORAL TIERED MEMORY — AUTOMATIC INGESTION
Setiap keputusan, insight, aturan, spekulasi, fakta, atau deliverable final yang muncul dalam percakapan WAJIB dicatat ke Temporal Tiered Memory. Gunakan CLI:

  /home/arif/.hermes/hermes-agent/venv/bin/python ~/.hermes/scripts/temporal_tiered_memory.py

Perintah penting:
  ingest   --text "..." --type <type> --tags <tag1,tag2,...> [--layer working|episodic|crystallized]
  retrieve --query "..." [--top 5] [--type-filter <type>] [--tag-filter <tag>]
  boost    --topic "..."       ← Signal Booster: re-mention resets decay ke 1.0
  crystallize --id <id>         ← Crystallization Gateway: lock manual ke permanen
  consolidate --min-sessions 3  ← Deteksi pattern lintas 3+ sesi → auto-crystallize
  stats                         ← Lihat isi memory

ATURAN FLEKSIBEL (BERLAKU UNTUK SEMUA KONTEKS — AKADEMIK, BISNIS, PERSONAL, R&D):

1. Setiap KEPUTUSAN yang diambil dalam sesi ini → ingest --type decision
   Contoh: "Arif memutuskan pakai margin 4cm untuk tugas Dosen Slamet"
           --type decision --tags rule,dosen_slamet,format

2. Setiap ATURAN DOSEN/KLIEN baru → ingest --type rule --layer crystallized
   Contoh: "Dosen A: A4, TNR 12, spasi 1.5, minimal 15 hal"
           "Dosen B: A4, Arial 11, spasi 1.15, minimal 8 hal"
           "Klien X: deck 16:9, brand color #2563EB, no emoji"
   JANGAN generalisasi "semua dokumen" — tiap dosen/klien punya tag sendiri.

3. Setiap SPEKULASI LIAR (brainstorming) → ingest --type speculation
   Biarkan decay natural (7 hari). Kalau diungkit lagi → boost.

4. Setiap INSIGHT dari diskusi → ingest --type insight
   Contoh: "GBrain resolver adopted for Jarvis shadow routing"

5. Setiap DELIVERABLE FINAL → ingest --type deliverable --layer crystallized

6. Sebelum mulai tugas → retrieve untuk recall konteks:
   retrieve --query "<topik>" --tag-filter "<dosen/klien/proyek>"

7. Setiap selesai sesi → consolidate untuk deteksi pattern:
   consolidate --min-sessions 2

3 LAPIS MEMORY:
  - WORKING (1 sesi): data aktif yang baru di-ingest
  - EPISODIC (decay): spekulasi 7 hari, keputusan 30 hari, fakta 90 hari
  - CRYSTALLIZED (permanen): deliverable, aturan, pattern lintas sesi

Signal Booster: kalau topik yang sama diungkit lagi → otomatis reset decay.
Crystallization Gateway: kamu (Arif) yang mutusin mana spekulasi yang jadi keputusan.
Memory ini fondasi untuk Zero Soul Loss metric.
DIRECTIVE
  echo "OK: directive appended"
fi

echo "=== [4] Verify ==="
ls -la "$MEMORY_SCRIPT"
grep -cF "$M" "$USER_MD"
ls -la "$MEMORY_DIR/" 2>/dev/null || echo "(memory dir kosong — siap diisi)"

echo "=== DEPLOY COMPLETE ==="
echo "rollback: cp ${USER_MD}.bak.${TS} $USER_MD"
