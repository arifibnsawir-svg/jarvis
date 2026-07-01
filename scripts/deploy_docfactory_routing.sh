#!/usr/bin/env bash
# =============================================================================
# deploy_docfactory_routing.sh
# -----------------------------------------------------------------------------
# Routing fix untuk skill jarvis-document-factory (skill hidup di repo
# Joki-tugas-, ter-deploy di ~/.hermes/skills/productivity/jarvis-document-factory/).
# Menegakkan 2 direktif di ~/.hermes/memories/USER.md supaya Jarvis MENJALANKAN
# pipeline factory (run.py + gate deterministik), bukan freehand render_deck /
# skip gate.
#
# Kenapa perlu: skill ada + jalan, tapi tanpa direktif ini Jarvis cenderung
# freehand (pptx-slides-creation-guard / office-document-ops / panggil
# render_deck.py langsung) dan skip gate. Dua direktif:
#   1) PRECEDENCE      = permintaan bikin dokumen WAJIB lewat skill ini.
#   2) OPERATIONAL     = perintah eksplisit: jalankan run.py, DONE hanya kalau
#                        gate PASS (exit 0); larang freehand/skip gate.
#
# Lapis SOFT: append ke USER.md. Idempotent per-marker + auto-backup. TANPA
# restart (aktif di sesi baru /new). Jalankan ON THE ACER SERVER (host Jarvis).
# =============================================================================
set -euo pipefail

USER_MD="${HERMES_USER_MD:-$HOME/.hermes/memories/USER.md}"
[ -f "$USER_MD" ] || { echo "ERROR: USER.md tidak ada di $USER_MD" >&2; exit 2; }

TS="$(date +%Y%m%d_%H%M%S)"
cp "$USER_MD" "${USER_MD}.bak.${TS}"
echo "backup: ${USER_MD}.bak.${TS}"

M1="## DOCUMENT FACTORY ROUTING PRECEDENCE"
if grep -qF "$M1" "$USER_MD"; then
  echo "SKIP: '$M1' sudah ada."
else
  cat >> "$USER_MD" <<'DIRECTIVE'

## DOCUMENT FACTORY ROUTING PRECEDENCE
Permintaan MEMBUAT FILE dokumen jadi (PPTX, DOCX, atau PDF: laporan, makalah,
modul, mini-book, slide sidang, presentasi, deck) WAJIB lewat skill
jarvis-document-factory. Jalur utama: model keluarkan SPEC JSON, renderer
deterministik yang membuat file, gate deterministik penentu DONE.

JANGAN pakai jalur lain untuk MEMBUAT dokumen baru dari materi:
- pptx-slides-creation-guard: komplementer (mewajibkan PPTX lewat render_deck).
  Boleh jadi pengiring, tetapi eksekusi tetap via jarvis-document-factory.
  Jangan dijadikan jalur mandiri untuk request dokumen jadi.
- office-document-ops: HANYA untuk operasi file yang sudah ada (buka, konversi,
  merge, split, ekstrak). BUKAN untuk membuat dokumen baru.
- powerpoint / pptxgenjs: JANGAN untuk dokumen (native sharp crash di CPU Acer).
- academic-document-factory: panduan referensi DOCX. Boleh sebagai acuan
  pendekatan, tetapi produksi file tetap lewat jarvis-document-factory.

Untuk PDF dokumen (laporan/makalah/modul): render PDF via jarvis-document-factory
(WeasyPrint A4, Daftar Isi bernomor). JANGAN bikin PDF dokumen dengan cara
konversi slide PPTX ke PDF landscape.

Gate deterministik jarvis-document-factory adalah satu-satunya penentu DONE.
Jangan sebut selesai sebelum gate PASS. Kalau gate FAIL, perbaiki SPEC lalu
re-gate (loop Iterasi ARSI) sampai PASS. Humanizer dan cite-or-abstain tetap
pass terakhir.
DIRECTIVE
  echo "OK: PRECEDENCE ditambahkan."
fi

M2="## DOCUMENT FACTORY OPERATIONAL RULES"
if grep -qF "$M2" "$USER_MD"; then
  echo "SKIP: '$M2' sudah ada."
else
  cat >> "$USER_MD" <<'DIRECTIVE'

## DOCUMENT FACTORY OPERATIONAL RULES
Aturan ini menegaskan DOCUMENT FACTORY ROUTING PRECEDENCE dengan perintah
operasional. Untuk SEMUA deliverable dokumen (PPTX/DOCX/PDF), WAJIB lewat entry
point jarvis-document-factory (run.py). DILARANG memanggil render_deck.py
langsung sebagai langkah final, dan DILARANG konversi manual sebagai pengganti
gate.

Langkah wajib:
1. Susun SPEC JSON sesuai kontrak skill.
2. Jalankan entry point (contoh):
   HERMES_RENDER_DECK=~/.hermes/scripts/render_deck.py \
   /home/arif/.hermes/hermes-agent/venv/bin/python \
   ~/.hermes/skills/productivity/jarvis-document-factory/run.py \
   <spec.json> --out <dir> --basename <nama>
3. DONE hanya jika run.py exit 0 (gate PASS). Kalau exit non-zero
   (AWAITING_GATE), baca failed_checks, perbaiki SPEC, jalankan ulang sampai
   PASS. JANGAN sebut selesai/berhasil/delivered sebelum gate PASS.

Bentuk keluaran:
- DOKUMEN (laporan/makalah/modul/mini-book): run.py formats ["pdf","docx"] atau
  sesuai permintaan. PDF = A4 WeasyPrint dari factory. JANGAN bikin PDF dokumen
  dari konversi slide.
- PRESENTASI (slide/deck/PPT): run.py formats ["pptx"] supaya deck kena gate.
  Kalau butuh PDF presentasi, ekspor slide jadi PDF landscape via LibreOffice
  SETELAH gate PPTX PASS. Ekspor itu tambahan visual, BUKAN pengganti gate.

Larangan tegas:
- JANGAN panggil render_deck.py sebagai langkah final tanpa run.py + gate.
- JANGAN skip gate dengan alasan "constraint tidak ada". Gate factory berjalan
  otomatis di run.py dan tidak butuh constraint eksternal. pipa4_gate.sh itu
  untuk audit dokumen akademik, BEDA dari gate factory; jangan tertukar.
- JANGAN deklarasi BERHASIL/DONE/DELIVERED sebelum run.py exit 0.
DIRECTIVE
  echo "OK: OPERATIONAL RULES ditambahkan."
fi

echo "--- verifikasi marker ---"
grep -nF "$M1" "$USER_MD"
grep -nF "$M2" "$USER_MD"
echo "== DONE. Aktif di sesi BARU (/new), tanpa restart. ROLLBACK: cp ${USER_MD}.bak.${TS} $USER_MD =="
