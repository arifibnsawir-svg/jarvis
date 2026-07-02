#!/usr/bin/env bash
# =============================================================================
# deploy_routing_decision_table.sh
# -----------------------------------------------------------------------------
# GBrain-inspired routing decision table for Jarvis.
# Perkuat pipa-routing/SKILL.md dengan tabel keputusan eksplisit dan
# anti-patterns yang mencegah Jarvis salah pilih skill.
#
# SOFT layer: USER.md directive. No restart.
# =============================================================================
set -euo pipefail

USER_MD="${HERMES_USER_MD:-$HOME/.hermes/memories/USER.md}"
TS="$(date +%Y%m%d_%H%M%S)"

[ -f "$USER_MD" ] || { echo "ERROR: USER.md tidak ada di $USER_MD" >&2; exit 2; }
cp "$USER_MD" "${USER_MD}.bak.${TS}"
echo "backup: ${USER_MD}.bak.${TS}"

M="## ROUTING DECISION TABLE — Skill Selection & Anti-Patterns"
if grep -qF "$M" "$USER_MD"; then
  echo "SKIP: directive already exists: $M"
  exit 0
fi

cat >> "$USER_MD" <<'DIRECTIVE'

## ROUTING DECISION TABLE — Skill Selection & Anti-Patterns
Tabel keputusan ini MEMPERKUAT pipa-routing. Gunakan untuk memilih skill yang
TEPAT sebelum eksekusi. Jika tidak ada di tabel → shadow resolver akan mencatat.

### DECISION TABLE

| Intent | Skill | Jalur | Dilarang |
|--------|-------|-------|----------|
| Buat DOKUMEN (PDF/DOCX/PPTX) | jarvis-document-factory | SPEC blocks → validate_spec → run.py → gate | freehand python-docx, manual PDF, pptxgenjs (crash sharp) |
| Buat PPT akademik | render_deck.py via factory | SPEC → factory → PPTX renderer | powerpoint skill (pptxgenjs), academic-document-factory (DOCX-only) |
| Buat Word/makalah | academic-document-factory | SPEC DOCX → factory | office-academic-skill (redundan) |
| Cari sumber ilmiah | academic-search | multi-DB → relevance filter → verify DOI | ngarang sumber, Scholar-only tanpa verify |
| Cari web umum | ddgs via config | web_search tool | hallucinate URL |
| Edit file existing | office-document-ops | buka, konversi, merge, split | bikin dokumen baru (itu factory) |
| Deploy code/infra | scripts/deploy_*.sh | idempotent + backup + verify | edit config core tanpa approval |
| Audit dokumen | PIPA4 gate + council | pipa4_gate.sh | klaim PASS tanpa evidence |
| Debug infra | observe → verify → patch | terminal read-only dulu | restart service tanpa approval |
| Brainstorming | Mythos mode | bebas, no gate | publikasi tanpa crystallize |
| Deliverable final | Fable mode | factory → gate → council → crystallize | skip gate, klaim SIAP PAKAI |
| Memory/recall | temporal_tiered_memory.py retrieve | query → context → jawab | asumsi tanpa retrieve |

### ANTI-PATTERNS (JANGAN PERNAH)

1. ❌ User minta verifikasi → kamu bikin dokumen baru.
   ✅ Verifikasi = inspect existing artifact + raw terminal evidence.

2. ❌ User minta satu tugas → kamu kerjakan DUA tugas paralel.
   ✅ Selesaikan dulu yang diminta, baru tawarkan bantuan lain.

3. ❌ SPEC pakai "content": "string" — factory tidak bisa baca.
   ✅ SPEC wajib "blocks": [{"type": "paragraph", "text": "..."}].

4. ❌ Gate FAIL → kamu klaim "cukup untuk bisnis" dan kirim file.
   ✅ Gate FAIL → baca failed_checks → perbaiki SPEC → re-run (ARSI Iterasi).

5. ❌ Ada 2 skill untuk 1 task → kamu pilih salah satu secara acak.
   ✅ Cek tabel di atas. Kalau tidak ada → tanya Arif.

6. ❌ Background process tanpa monitor → klaim selesai tanpa bukti.
   ✅ Background process harus ada notify + raw log + exit code.

7. ❌ "Sudah jadi" / "SIAP PAKAI" / "DONE" tanpa gate PASS.
   ✅ Hanya gate yang memutuskan DONE. Kamu cuma bisa usul AWAITING_GATE.

### SHADOW RESOLVER
Setiap kali akan mengeksekusi tugas multi-step, jalankan shadow resolver:
  python3 ~/.hermes/scripts/jarvis_shadow_resolver.py --user "<permintaan>" --planned "<rencana>"
Jika mismatch=true → berhenti, baca issues, sesuaikan rencana.

Tabel ini MELENGKAPI pipa-routing/SKILL.md, bukan menggantikan.
DIRECTIVE

echo "=== PROOF ==="
grep -nF "$M" "$USER_MD"
echo "=== DEPLOY COMPLETE ==="
echo "Decision table active. Anti-patterns enforced. Shadow resolver integration."
echo "rollback: cp ${USER_MD}.bak.${TS} $USER_MD"
