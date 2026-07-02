#!/usr/bin/env bash
# =============================================================================
# deploy_main_loop_memory.sh
# -----------------------------------------------------------------------------
# WIRE ALL MEMORY COMPONENTS INTO JARVIS MAIN LOOP
#
# This is the final piece that makes the memory system work AUTOMATICALLY:
#
#   BEFORE each answer:
#     → temporal_tiered_memory.py retrieve --query "<topic>" --top 5
#     → Recall context, rules, past decisions, speculations
#
#   AFTER each answer:
#     → context_annotated_ingestion.py --text "<user message>"
#     → Auto-classify + ingest to episodic memory
#
#   END OF SESSION:
#     → temporal_tiered_memory.py stats
#     → temporal_tiered_memory.py consolidate --min-sessions 2
#     → Log to ARIF_STACK_EVENT_LOG.md following jarvis_filing_protocol.md
#
# SOFT layer: USER.md directive. No restart.
# Domain-agnostic: works for academic, business, infra, brainstorming, personal.
# =============================================================================
set -euo pipefail

USER_MD="${HERMES_USER_MD:-$HOME/.hermes/memories/USER.md}"
VENV="/home/arif/.hermes/hermes-agent/venv/bin/python"
TS="$(date +%Y%m%d_%H%M%S)"

[ -f "$USER_MD" ] || { echo "ERROR: USER.md tidak ada di $USER_MD" >&2; exit 2; }
cp "$USER_MD" "${USER_MD}.bak.${TS}"
echo "backup: ${USER_MD}.bak.${TS}"

M="## MAIN LOOP MEMORY INTEGRATION — BEFORE & AFTER EVERY TURN"
if grep -qF "$M" "$USER_MD"; then
  echo "SKIP: directive already exists: $M"
  exit 0
fi

cat >> "$USER_MD" <<'DIRECTIVE'

## MAIN LOOP MEMORY INTEGRATION — BEFORE & AFTER EVERY TURN
Ini adalah perintah WAJIB yang mengintegrasikan seluruh sistem memory ke dalam
perilaku harian Jarvis. Berlaku untuk SEMUA domain — akademik, bisnis, infra,
brainstorming, personal. Tidak ada pengecualian.

### SEBELUM MENJAWAB (RETRIEVE CONTEXT)
Sebelum merespons pesan user, recall konteks dari memory:

  /home/arif/.hermes/hermes-agent/venv/bin/python ~/.hermes/scripts/temporal_tiered_memory.py retrieve --query "<inti pesan user>" --top 5

Yang di-recall:
  - Aturan dosen/klien yang relevan (tag: rule)
  - Keputusan sebelumnya (tag: decision)
  - Insight dari sesi lampau (tag: insight)
  - Deliverable terkait (tag: deliverable, crystallized)
  - Spekulasi yang masih hidup (tag: speculation, weight > 0.3)

Jika hasil retrieval kosong: lanjut normal. Jika ada hasil: sebutkan konteks
yang relevan sebelum menjawab. Contoh: "Berdasarkan keputusan minggu lalu
tentang X, dan aturan Dosen A tentang format Y, ini rekomendasinya..."

### SETELAH MENJAWAB (AUTO-INGEST)
Setelah selesai merespons, klasifikasikan dan simpan pesan user:

  /home/arif/.hermes/hermes-agent/venv/bin/python ~/.hermes/scripts/context_annotated_ingestion.py --text "<pesan user>" --session "<session_id>"

Classifier otomatis menentukan content_type (speculation/decision/insight/rule/...)
dan tags (domain + entitas). Trivial message ("halo", "ok") otomatis di-skip.

### DI AKHIR SESI (CONSOLIDATION)
Setelah sesi selesai (user tidak lanjut), jalankan:

  /home/arif/.hermes/hermes-agent/venv/bin/python ~/.hermes/scripts/temporal_tiered_memory.py stats
  /home/arif/.hermes/hermes-agent/venv/bin/python ~/.hermes/scripts/temporal_tiered_memory.py consolidate --min-sessions 2

Kemudian catat ringkasan sesi ke ~/.hermes/state/ARIF_STACK_EVENT_LOG.md
mengikuti aturan di ~/jarvis/memory/jarvis_filing_protocol.md.

### SIGNAL BOOSTER (OTOMATIS)
Jika user menyebut topik yang sudah ada di memory, otomatis jalankan:

  /home/arif/.hermes/hermes-agent/venv/bin/python ~/.hermes/scripts/temporal_tiered_memory.py boost --topic "<topik>"

Ini mereset decay ke 1.0 — ide lama yang diungkit lagi jadi prioritas.

### CRYSTALLIZATION GATEWAY (MANUAL, oleh Arif)
Hanya Arif yang bisa mengkristalisasi spekulasi menjadi keputusan. Trigger:
perintah eksplisit "/crystallize" atau "lock ini jadi keputusan".
Saat itu terjadi, jalankan:

  /home/arif/.hermes/hermes-agent/venv/bin/python ~/.hermes/scripts/temporal_tiered_memory.py crystallize --id <entry_id>

### CONTOH ALUR LENGKAP

User: "bro, analisa bisnis saas gue dong, churn rate gede"

Jarvis:
  1. retrieve --query "saas churn rate" → nemu: spekulasi minggu lalu, keputusan pricing
  2. Jawab: "Minggu lalu lo spekulasiin subscription vs one-time.
     Data sekarang: churn rate X%. Berdasarkan spekulasi itu, rekomendasi gue: ..."
  3. Auto-ingest pesan user sebagai speculation + tags saas_venture,churn
  4. boost --topic "saas" → reset decay spekulasi minggu lalu

Jarvis:
  1. retrieve --query "format makalah" --tag-filter "dosen_slamet"
  2. Nemu: rule crystallized — margin 4/3/3/3, TNR 12, spasi 1.5, min 15 hal
  3. Jawab: "Aturan Dosen Slamet yang tersimpan: ..."
  4. Auto-ingest sebagai general (aturan sudah ada, tidak perlu entry baru)

### PRINSIP
- Memory bekerja di BACKGROUND. User tidak perlu perintah explicit.
- Retrieval memperkaya jawaban — bukan menggantikan reasoning.
- Auto-ingest menjaga Zero Soul Loss — ide liar jam 2 pagi tidak hilang.
- Consolidation mendeteksi pattern lintas sesi — otomatis.
- Crystallization tetap MANUAL — friction = quality.

Semua komponen memory (Temporal Tiered, Context-Annotated Ingestion, Filing
Protocol) sekarang bekerja sebagai SATU SISTEM TERINTEGRASI.
DIRECTIVE

echo "=== [2] Verify ==="
grep -nF "$M" "$USER_MD"
echo "---"
echo "=== DEPLOY COMPLETE ==="
echo "Main loop memory integration ACTIVE. Memory system now works AUTOMATICALLY."
echo "   BEFORE each answer: retrieve context"
echo "   AFTER each answer: auto-ingest"
echo "   END of session: consolidate"
echo "   Re-mention: signal booster"
echo "rollback: cp ${USER_MD}.bak.${TS} $USER_MD"
