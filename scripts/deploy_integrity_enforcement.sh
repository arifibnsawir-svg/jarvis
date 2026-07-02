#!/usr/bin/env bash
# =============================================================================
# deploy_integrity_enforcement.sh
# -----------------------------------------------------------------------------
# Anti-False-Claim Enforcement — Jarvis Integrity Guard.
#
# Problem (PROVEN 2026-07-02 06:44):
#   Jarvis claimed "background process completed, re-run done, gate PASS"
#   BUT both PDF files had identical SHA256 — no actual work happened.
#
# This directive REQUIRES raw evidence before any claim of completion.
#
# SOFT layer: USER.md directive. No restart.
# HARD layer (future): action-gate v2 LIVE enforcement.
# =============================================================================
set -euo pipefail

USER_MD="${HERMES_USER_MD:-$HOME/.hermes/memories/USER.md}"
SCRIPTS_DIR="$HOME/.hermes/scripts"
INTEGRITY_SCRIPT="$SCRIPTS_DIR/integrity_check.sh"
TS="$(date +%Y%m%d_%H%M%S)"

[ -f "$USER_MD" ] || { echo "ERROR: USER.md tidak ada di $USER_MD" >&2; exit 2; }
cp "$USER_MD" "${USER_MD}.bak.${TS}"
echo "backup: ${USER_MD}.bak.${TS}"

echo "=== [1] Install integrity check script ==="
mkdir -p "$SCRIPTS_DIR"
cp -f ~/jarvis/scripts/integrity_check.sh "$INTEGRITY_SCRIPT"
chmod +x "$INTEGRITY_SCRIPT"
ls -la "$INTEGRITY_SCRIPT"

echo "=== [2] Wire directive to USER.md ==="
M="## INTEGRITY ENFORCEMENT — NO CLAIM WITHOUT RAW EVIDENCE"
if grep -qF "$M" "$USER_MD"; then
  echo "SKIP: directive already exists: $M"
else
  cat >> "$USER_MD" <<'DIRECTIVE'

## INTEGRITY ENFORCEMENT — NO CLAIM WITHOUT RAW EVIDENCE
Ini adalah aturan ANTI-FALSE-CLAIM. Terbukti pada 2026-07-02 pukul 06:44:
Jarvis mengaku "background process selesai, file sudah di-render ulang,
gate PASS" padahal file sebelum dan sesudah memiliki SHA256 IDENTIK —
tidak ada pekerjaan nyata yang terjadi.

### ATURAN (MANDATORY, NO EXCEPTIONS)

1. SEBELUM mengklaim operasi selesai, WAJIB verifikasi dengan bukti mentah:
   - SHA256 file sebelum vs sesudah
   - Ukuran file (bytes) sebelum vs sesudah
   - Timestamp modifikasi
   - Exit code command yang dijalankan

2. Untuk BACKGROUND PROCESS, verifikasi wajib menggunakan:
   bash ~/.hermes/scripts/integrity_check.sh --before <file_sebelum> --after <file_sesudah>

3. Untuk RENDER ULANG dokumen:
   - Simpan SHA256 file SEBELUM render
   - Jalankan run.py
   - Bandingkan SHA256 file SESUDAH render
   - JIKA IDENTIK → operasi TIDAK menghasilkan perubahan → JANGAN klaim "done"

4. LAPORAN HARUS MENTAH — bukan ringkasan, bukan verdict:
   - "PASS" hanya jika SHA256 berbeda DAN exit code 0
   - "FAIL" jika SHA256 identik ATAU exit code non-zero
   - JANGAN PERNAH menulis "DONE" / "SELESAI" / "SIAP PAKAI" tanpa bukti di atas

5. KALAU RAGU: jangan klaim apa-apa. Minta Arif verifikasi manual.

### CONTOH BENAR
```
SHA256 sebelum: c1a43ef6... (43446 bytes)
SHA256 sesudah: d4e5f6a7... (44120 bytes)
Verdict: CHANGED — render ulang menghasilkan file berbeda ✅
Exit code run.py: 0
Status: DONE — gate PASS dengan bukti
```

### CONTOH SALAH (INI YANG TERJADI 2026-07-02)
```
"Background process selesai, gate PASS, file sudah jadi"
— TIDAK ada SHA256
— TIDAK ada ukuran file
— TIDAK ada exit code
— File ternyata IDENTIK (c1a43ef6... = c1a43ef6...)
— INI FALSE CLAIM — JANGAN DIULANGI
```

Pelanggaran aturan ini = False-READY. Shadow resolver akan mendeteksi mismatch.
Action-gate v2 (kalau sudah LIVE) akan memblokir klaim tanpa bukti.
DIRECTIVE
  echo "OK: directive appended"
fi

echo "=== PROOF ==="
grep -nF "$M" "$USER_MD"
echo "---"
echo "=== DEPLOY COMPLETE ==="
echo "Integrity check: $INTEGRITY_SCRIPT"
echo "Directive active: $M"
echo "rollback: cp ${USER_MD}.bak.${TS} $USER_MD"
