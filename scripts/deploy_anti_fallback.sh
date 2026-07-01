#!/usr/bin/env bash
# =============================================================================
# deploy_anti_fallback.sh
# -----------------------------------------------------------------------------
# Direktif ANTI-FALLBACK untuk skill jarvis-document-factory. Menegakkan 1
# direktif di ~/.hermes/memories/USER.md supaya, saat run.py GAGAL
# (AWAITING_GATE / error / crash), Jarvis TIDAK kabur ke freehand (python-docx /
# render_deck.py langsung / tulis file biner manual) melainkan memperbaiki SPEC
# dan mengulang lewat pipeline factory yang ber-gate.
#
# Kenapa perlu: pola gagal berulang (checkpoint 12.21/12.24/12.30) = LLM
# meninggalkan pipeline ber-gate begitu run.py error, lalu menghasilkan file
# manual tanpa gate -> False-READY. Direktif ini menutup celah itu dan
# mengarahkan ke validate_spec.py + iterasi SPEC.
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

M1="## DOCUMENT FACTORY ANTI-FALLBACK"
if grep -qF "$M1" "$USER_MD"; then
  echo "SKIP: '$M1' sudah ada."
else
  cat >> "$USER_MD" <<'DIRECTIVE'

## DOCUMENT FACTORY ANTI-FALLBACK
Berlaku untuk semua deliverable dokumen (PPTX/DOCX/PDF) lewat
jarvis-document-factory. Kalau run.py GAGAL (exit non-zero / AWAITING_GATE /
SpecValidationError / crash), DILARANG beralih ke jalur freehand: python-docx
manual, memanggil render_deck.py langsung sebagai langkah final, atau menulis
file biner dengan tangan. Fallback semacam itu = pelanggaran dan sudah terbukti
jadi pola gagal (False-READY).

Langkah WAJIB saat run.py gagal:
1. Jalankan validator pra-render untuk membaca masalah SPEC dengan jelas:
   /home/arif/.hermes/hermes-agent/venv/bin/python \
   ~/.hermes/skills/productivity/jarvis-document-factory/validate_spec.py <spec.json>
2. Baca failed_checks dari output run.py + hasil validate_spec.py, lalu PERBAIKI
   SPEC (bukan bikin file manual).
3. Jalankan ulang run.py. Ulangi maksimal 5 iterasi.
4. Kalau setelah 5 iterasi masih gagal: BERHENTI. Minta bantuan Arif dan
   lampirkan SPEC terakhir, output run.py, dan output validate_spec.py. JANGAN
   sebut selesai/berhasil/delivered.

Acuan struktur: examples/makalah_4bab_spec.json (Kata Pengantar, Daftar Isi,
BAB I-IV, Daftar Pustaka). Gate deterministik factory tetap SATU-SATUNYA penentu
DONE; tidak ada jalan pintas.
DIRECTIVE
  echo "OK: ANTI-FALLBACK ditambahkan."
fi

echo "--- verifikasi marker ---"
grep -nF "$M1" "$USER_MD"
echo "== DONE. Aktif di sesi BARU (/new), tanpa restart. ROLLBACK: cp ${USER_MD}.bak.${TS} $USER_MD =="
