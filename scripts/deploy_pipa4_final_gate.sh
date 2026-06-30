#!/usr/bin/env bash
# Deploy PIPA4 FINAL GATE: wrapper pipa4_gate.sh + direktif wajib-di-final (loop ARSI Iterasi).
# Nutup loop produksi->gate->iterasi buat deliverable akademik FINAL (PDF/DOCX).
# PIPA4 engine BERAT (~300s council) -> gate ini SCOPED ke final akademik, BUKAN tiap artefak (anti-over-engineering).
# Idempotent + backup. No restart (direktif aktif di /new; helper dipanggil on-demand).
set -uo pipefail
SC="$HOME/.hermes/scripts"
UM="$HOME/.hermes/memories/USER.md"
ts="$(date +%Y%m%d_%H%M%S)"

echo "=== [1] deploy helper pipa4_gate.sh ==="
mkdir -p "$SC"
cp -f ~/jarvis/scripts/pipa4_gate.sh "$SC/pipa4_gate.sh"; chmod +x "$SC/pipa4_gate.sh"
ls -la "$SC/pipa4_gate.sh"

echo "=== [2] bash-syntax check ==="
bash -n "$SC/pipa4_gate.sh" && echo "SYNTAX_OK"

echo "=== [3] SMOKE-TEST: jalanin gate di sample PDF (bukti wrapper parse + verdict + exit code) ==="
SAMP="$HOME/.hermes/pipelines/pipa4/phase5c/Mini_Book_PKn_Nurjali_Sangadji.pdf"
CONS="$HOME/.hermes/pipelines/pipa4/phase5c/constraint_mini_book_pkn.json"
if [ -f "$SAMP" ] && [ -f "$CONS" ]; then
  bash "$SC/pipa4_gate.sh" "$SAMP" "$CONS" | tail -6
  echo "(exit code wrapper: $? -> 1=NEEDS_WORK wajar utk sample ini, 0=PASS)"
else
  echo "(sample tidak ada, skip smoke-test)"
fi

echo "=== [4] wire direktif PIPA4 FINAL GATE ke USER.md (idempotent + backup) ==="
if [ ! -f "$UM" ]; then echo "RESULT_WIRE: FAIL (USER.md tidak ada)"; else
  MARK="PIPA4 FINAL GATE"
  if grep -q "$MARK" "$UM"; then
    echo "RESULT_WIRE: SKIP (sudah ada)"
  else
    cp "$UM" "$UM.bak.$ts"; echo "BACKUP: $UM.bak.$ts"
    cat >> "$UM" <<'TXT'
PIPA4 FINAL GATE (always, untuk deliverable akademik FINAL berupa file PDF/DOCX: makalah, laporan, skripsi, mini-book, atau PPT sidang yang diekspor PDF): SEBELUM klaim DONE/READY, WAJIB jalanin gate: bash ~/.hermes/scripts/pipa4_gate.sh <artifact_path> <constraint.json> (constraint: ~/.hermes/pipelines/pipa4/constraints/academic_book.json atau yang paling sesuai). Baca VERDICT. PASS (final_status READY_FOR_HUMAN_REVIEW & false_READY_count 0) -> boleh deliver. NEEDS_WORK -> baca report PIPA4 di run_dir, PERBAIKI yang di-flag (placeholder/struktur/teks/evidence/sumber), lalu RE-GATE; ULANGI loop ini (ARSI Iterasi: produksi->gate->perbaiki->re-gate) sampai PASS. JANGAN pernah deklarasi DONE/READY untuk deliverable akademik FINAL tanpa gate PASS (anti-False-READY; catatan: production_ready memang selalu False/hardcoded -> pakai final_status sebagai sinyal lolos). SCOPED: cuma untuk FINAL PDF/DOCX akademik, BUKAN draft/spec/markdown antara, BUKAN artefak ringan non-akademik (PIPA4 berat ~300s, jangan dipakai di tiap output).
TXT
    echo "RESULT_WIRE: SUCCESS"
  fi
fi

echo "=== PROOF ==="
grep -n "PIPA4 FINAL GATE" "$UM" | head
echo "=== CATATAN ==="
echo "- Direktif aktif di SESSION BARU (/new). Helper on-demand, TIDAK perlu restart."
echo "- ROLLBACK: cp $UM.bak.$ts $UM ; rm -f $SC/pipa4_gate.sh"
