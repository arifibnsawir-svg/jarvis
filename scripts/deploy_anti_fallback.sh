#!/usr/bin/env bash
# =============================================================================
# deploy_anti_fallback.sh
# -----------------------------------------------------------------------------
# Direktif ANTI-FALLBACK + ARSI ITERASI untuk skill jarvis-document-factory.
# Menegakkan 2 direktif di ~/.hermes/memories/USER.md:
#
#   1) ANTI-FALLBACK: saat run.py GAGAL, JANGAN kabur ke freehand.
#      Wajib validate_spec -> perbaiki SPEC -> re-run (max 5 iterasi).
#
#   2) ARSI ITERASI: gate = SATU-SATUNYA penentu DONE.
#      JANGAN klaim "SIAP PAKAI"/"DONE"/"DELIVERED"/"PRODUCTION-READY"
#      selama gate masih FAIL / status AWAITING_GATE. Ini mengatasi pola
#      False-READY di mana Jarvis skip iterasi dan klaim selesai padahal
#      gate belum PASS (terbukti di business report 2026-07-01).
#
# Lapis SOFT: append ke USER.md. Idempotent per-marker + auto-backup.
# TANPA restart (aktif di sesi baru /new).
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

M2="## ARSI ITERASI — JANGAN KLAIM DONE TANPA GATE PASS"
if grep -qF "$M2" "$USER_MD"; then
  echo "SKIP: '$M2' sudah ada."
else
  cat >> "$USER_MD" <<'DIRECTIVE'

## ARSI ITERASI — JANGAN KLAIM DONE TANPA GATE PASS
Ini menegaskan doktrin A.R.S.I (Iterasi = loop self-healing). Gate
deterministik (7 cek + no_truncated_text) adalah SATU-SATUNYA otoritas yang
menyatakan output DONE. LLM/Jarvis TIDAK PERNAH boleh mendeklarasikan:
  - "SIAP PAKAI"
  - "DONE"
  - "DELIVERED"
  - "PRODUCTION-READY"
  - "sudah jadi"
  - "bisa dipakai"
  - "CLEARED FOR PRODUCTION"
selama status run.py masih AWAITING_GATE / exit non-zero / gate FAIL.

Kalau gate FAIL:
1. Baca failed_checks — itu daftar masalah NYATA (bukan opini).
2. Perbaiki SPEC sesuai failed_checks.
3. Re-run. Ulangi sampai gate PASS (EXIT=0).
4. HANYA setelah gate PASS, boleh sebut "DONE" dan kirim file ke user.

Kalau ada failed_checks yang tidak dipahami: JANGAN berasumsi. Minta bantuan
Arif dengan melampirkan SPEC + output run.py.

Aturan ini berlaku untuk SEMUA jenis dokumen (akademik, bisnis, proposal, dll).
Tidak ada pengecualian "cukup untuk bisnis" atau "cukup untuk draft". Gate =
deterministik, bukan bisa ditawar.
DIRECTIVE
  echo "OK: ARSI ITERASI ditambahkan."
fi

echo "--- verifikasi marker ---"
grep -nF "$M1" "$USER_MD"
grep -nF "$M2" "$USER_MD"
echo "== DONE. Aktif di sesi BARU (/new), tanpa restart. ROLLBACK: cp ${USER_MD}.bak.${TS} $USER_MD =="
