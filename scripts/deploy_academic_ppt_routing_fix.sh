#!/usr/bin/env bash
# FIX routing akademik: pisahkan akademik-WORD (DOCX) dari akademik-PPT (slides).
# Akar masalah (terbukti via inspect Acer): USER.md L624 nge-rute "defense/seminar PPT" ke
# academic-document-factory, PADAHAL skill itu DOCX-ONLY (zero pipeline PPT; grep pptx/slide/deck=kosong).
# Akibat: PPT akademik nyasar (ke academic-document-factory yg gak bisa slide, ATAU ke powerpoint+pptxgenjs yg CRASH sharp).
# Fix: append 1 direktif presedensi (idempotent + backup, NO restart). Aktif di sesi /new.
set -uo pipefail
UM="$HOME/.hermes/memories/USER.md"
ts="$(date +%Y%m%d_%H%M%S)"
MARK="ACADEMIC ROUTING PRECEDENCE"

if [ ! -f "$UM" ]; then echo "RESULT: FAIL (USER.md tidak ada: $UM)"; exit 1; fi

if grep -q "$MARK" "$UM"; then
  echo "RESULT: SKIP (direktif '$MARK' sudah ada, idempotent)"
else
  cp "$UM" "$UM.bak.$ts"
  echo "BACKUP: $UM.bak.$ts"
  cat >> "$UM" <<'TXT'
ACADEMIC ROUTING PRECEDENCE (menyelesaikan konflik L624 vs L626 untuk PPT akademik): academic-document-factory itu DOCX-ONLY (mini book, makalah, laporan, DOCX/PDF) dan TIDAK punya pipeline slide/PPT sama sekali. Maka: (1) akademik WORD/dokumen-panjang (makalah, laporan, mini-book, laporan-baca PDF->Word, DOCX) -> academic-document-factory (+ office-document-ops). (2) akademik PPT/slides (sidang, seminar, presentasi) -> render_deck.py lewat Structure-Before-Render (preset academic); kalau versi polished DAN editable dua-duanya berguna, ikut DUAL-OUTPUT (claude-design HTML->PDF + render_deck.py PPTX). JANGAN pernah merutekan PPT akademik ke academic-document-factory (tak punya kapabilitas PPT), dan JANGAN pakai powerpoint+pptxgenjs atau paket sharp untuk PPT akademik (pptxgenjs/sharp crash Illegal instruction di CPU ini). (3) SELALU jalankan humanizer (lihat aturan humanizer-default) sebagai pass prosa terakhir pada SETIAP artefak akademik, PPT maupun DOCX, sebelum klaim READY.
TXT
  if grep -q "$MARK" "$UM"; then echo "RESULT: SUCCESS"; else echo "RESULT: FAIL (append gagal)"; fi
fi

echo "=== PROOF (baris direktif baru) ==="
grep -n "ACADEMIC ROUTING PRECEDENCE" "$UM"
echo "=== CATATAN ==="
echo "- Aktif di SESSION BARU (/new). TIDAK perlu restart gateway."
echo "- ROLLBACK: cp $UM.bak.<ts> $UM"
