#!/usr/bin/env bash
# HTML -> PDF di Acer. Chromium headless (utama, paling akurat utk HTML/CSS modern), soffice fallback.
# Buat deck claude-design (butuh @media print / @page landscape biar 1 slide = 1 halaman).
# Pakai: html_to_pdf.sh input.html [output.pdf]
set -uo pipefail
IN="${1:?usage: html_to_pdf.sh input.html [output.pdf]}"
OUT="${2:-${IN%.html}.pdf}"
ABS="file://$(readlink -f "$IN")"

CHROME=""
for c in chromium chromium-browser google-chrome; do command -v "$c" >/dev/null 2>&1 && CHROME="$c" && break; done

if [ -n "$CHROME" ]; then
  "$CHROME" --headless=new --disable-gpu --no-sandbox --no-pdf-header-footer --print-to-pdf="$OUT" "$ABS" >/dev/null 2>&1 \
   || "$CHROME" --headless --disable-gpu --no-sandbox --print-to-pdf="$OUT" "$ABS" >/dev/null 2>&1 || true
fi
if [ ! -s "$OUT" ] && command -v soffice >/dev/null 2>&1; then
  soffice --headless --convert-to pdf --outdir "$(dirname "$(readlink -f "$OUT")")" "$IN" >/dev/null 2>&1 || true
fi
if [ -s "$OUT" ]; then echo "PDF_OK: $OUT ($(du -h "$OUT" | cut -f1))"; else echo "PDF_FAIL (cek HTML/print CSS)"; fi
