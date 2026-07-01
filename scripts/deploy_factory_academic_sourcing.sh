#!/usr/bin/env bash
# =============================================================================
# deploy_factory_academic_sourcing.sh
# -----------------------------------------------------------------------------
# Wiring academic-search -> jarvis-document-factory. Deliverable akademik yang
# butuh referensi WAJIB dapat sumber dari skill academic-search DULU (multi-DB,
# Indonesia-first, verify DOI resolve) sebelum bikin SPEC. Sumber terverifikasi
# masuk ke SPEC references (verified: true). Anti-halu: JANGAN nulis referensi
# dari ingatan / ngarang.
#
# Kenapa: test 2026-07-01 nunjukin Jarvis nulis referensi dari ingatan (tanpa
# academic-search) -> gate citation FAIL (benar, anti-halu bekerja). Fix akar =
# wajibkan sumber lewat academic-search dulu.
#
# Lapis SOFT: append 1 direktif ke ~/.hermes/memories/USER.md. Idempotent +
# auto-backup. TANPA restart (aktif di sesi baru /new). Jalankan di Acer.
# =============================================================================
set -euo pipefail

USER_MD="${HERMES_USER_MD:-$HOME/.hermes/memories/USER.md}"
[ -f "$USER_MD" ] || { echo "ERROR: USER.md tidak ada di $USER_MD" >&2; exit 2; }

MARKER="## FACTORY ACADEMIC SOURCING"
if grep -qF "$MARKER" "$USER_MD"; then
  echo "SKIP: '$MARKER' sudah ada di $USER_MD (idempotent)."
  grep -nF "$MARKER" "$USER_MD"
  exit 0
fi

TS="$(date +%Y%m%d_%H%M%S)"
cp "$USER_MD" "${USER_MD}.bak.${TS}"
echo "backup: ${USER_MD}.bak.${TS}"

cat >> "$USER_MD" <<'DIRECTIVE'

## FACTORY ACADEMIC SOURCING
Untuk deliverable akademik yang butuh referensi (makalah, laporan, PPT sidang,
skripsi, mini-book, apa pun ber-daftar-pustaka) yang diproduksi lewat
jarvis-document-factory: sumber WAJIB dari skill academic-search DULU, sebelum
menulis isi atau menyusun SPEC.

Alur wajib:
1. Panggil academic-search: multi-database, Indonesia-first (Garuda/SINTA/.ac.id,
   OpenAlex/Crossref filter Indonesia) dulu, baru internasional. Sertakan Google
   Scholar sebagai salah satu sumber (best-effort, jangan diandalkan sendirian).
2. VERIFY tiap sitasi (verify_citations.py: DOI resolve + URL kebuka). HANYA
   sumber yang LOLOS verify yang boleh dipakai.
3. Masukkan sumber terverifikasi ke SPEC references pakai skema factory:
   {"id", "apa": "<APA lengkap>", "url": "<DOI atau URL yang resolve>",
   "verified": true}. Sitasi in-text harus merujuk penulis yang sama dengan
   entri referensi.

Larangan (anti-halu):
- JANGAN tulis referensi/DOI/penulis/tahun/jurnal dari ingatan atau karangan.
- JANGAN masukkan sumber yang belum lolos verify sebagai referensi.
- Kalau academic-search tidak menemukan sumber terverifikasi: cite-or-abstain
  (bilang belum ada sumber terverifikasi), jangan dipaksa atau ngarang.

Prioritas selalu: sumber Indonesia dulu, baru internasional. Ini melengkapi
DOCUMENT FACTORY OPERATIONAL RULES (sumber terverifikasi -> SPEC -> run.py ->
gate deterministik).
DIRECTIVE

echo "OK: direktif FACTORY ACADEMIC SOURCING ditambahkan ke $USER_MD"
echo "--- verifikasi marker ---"
grep -nF "$MARKER" "$USER_MD"
echo "--- 30 baris terakhir ---"
tail -n 30 "$USER_MD"
echo
echo "== DONE. Aktif di sesi BARU (/new), tanpa restart. ROLLBACK: cp ${USER_MD}.bak.${TS} $USER_MD =="
