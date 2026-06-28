#!/usr/bin/env bash
# Append a dated session checkpoint to Jarvis's event log so context survives across sessions.
# Idempotent: skips if this session's marker already present. Creates the log if missing.
set -uo pipefail

LOG="$HOME/.hermes/state/ARIF_STACK_EVENT_LOG.md"
MARKER="SESSION_20260627_ALWAYSON_NEUROARC_ARSI"

mkdir -p "$(dirname "$LOG")"
[ -f "$LOG" ] || { printf '# ARIF STACK EVENT LOG\n' > "$LOG"; }

if grep -q "$MARKER" "$LOG" 2>/dev/null; then
  echo "RESULT: SKIP (entry $MARKER already logged)"
else
  cat >> "$LOG" <<'ENTRY'

---
## [2026-06-27] SESSION_20260627_ALWAYSON_NEUROARC_ARSI — neuro-arc + arsi-doctrine ALWAYS-ON; PIPA4 gate verified
Apa yang dilakukan (biar Jarvis gak lupa konteks):
- SKILL baru: `neuro-arc` (lapis berpikir/representasi, think-first: narasi->entitas->ukuran->relasi->output -> TaskState)
  dan `arsi-doctrine` (aturan eksekusi A.R.S.I: Audit->Rancang->Sistemasi->Iterasi, loop self-healing).
  Ditulis sbg Claude SKILL.md, deployed ke ~/.hermes/skills/, LOLOS _validate_frontmatter.
- ALWAYS-ON mekanismenya = direktif di ~/.hermes/memories/USER.md (L618 neuro-arc, L619 arsi-doctrine),
  di-inject ke system prompt tiap turn (pola sama dgn guard existing). KONFIRM aktif di session baru
  (quote test + behavioral: Jarvis struktur dulu, audit dulu, GAK self-declare DONE).
- PENTING: config `enabled_default_skills` = DEAD (0 referensi di kode .py) -> JANGAN dipakai buat always-on.
  Sudah di-revert ke ['smart-router'].
- BEDA ISTILAH (locked): A.R.S.I = ATURAN (doktrin), `arsi engine` = MESIN/runtime. NEURO-ARC = lapis representasi (sebelum eksekusi).
- PIPA4 GATE diaudit & TERBUKTI sehat: gate DETERMINISTIK = OTORITAS, LLM = advisory.
  synthesize_final: gate FAIL -> blokir READY (LLM di-OVERRIDDEN_BY_GATE, false_ready_risk HIGH);
  gate PASS -> LLM cuma boleh bikin lebih ketat (downgrade). production_ready hardcode False (selalu mentok human review).
  -> anti-False-READY SOLID. TIDAK perlu fix korektif.
- PENDING (opsional, langkah B): swap model council DailyFree -> jarvis-reason di
  phase6a/6c/6d + phase7a/pipa4_review_local.py:104 (naikin kualitas ADVISORY; gate authority TIDAK berubah).
  Syarat: verifikasi guardian_router nerima combo 'jarvis-reason' dulu.
- Repo: arifibnsawir-svg/jarvis, branch feat/skills-neuro-arc-arsi (PR #1).
- ROLLBACK always-on: cp ~/.hermes/memories/USER.md.bak.20260627_224419 ~/.hermes/memories/USER.md
ENTRY
  echo "RESULT: APPENDED to $LOG"
fi

echo "=== PROOF (entri terbaru) ==="
grep -n "$MARKER" "$LOG" || echo "(marker not found)"
tail -n 5 "$LOG"
