#!/usr/bin/env bash
# deploy_deep_analysis_autohook.sh (HARD-ENFORCE v2)
# Verdict hanya sah kalau membawa eval_receipt (HMAC) dari evaluator asli DAN
# lolos verify_deep_analysis.py. JALANKAN HANYA setelah E2E test lolos
# (script ini yang MENGAKTIFKAN enforcement + wiring USER.md).
set -euo pipefail

USER_MD="${HERMES_USER_MD:-$HOME/.hermes/memories/USER.md}"
SCRIPTS_DIR="$HOME/.hermes/scripts"
PY="$HOME/.hermes/hermes-agent/venv/bin/python"
SECRET="$HOME/.hermes/.deep_eval_secret"
LEDGER="$HOME/.hermes/logs/deep_analysis_ledger.jsonl"
TS="$(date +%Y%m%d_%H%M%S)"

[ -f "$USER_MD" ] || { echo "ERROR: USER.md tidak ada di $USER_MD" >&2; exit 2; }
cp "$USER_MD" "${USER_MD}.bak.${TS}"
echo "backup: ${USER_MD}.bak.${TS}"

echo "=== [1] Deploy scripts (repo -> produksi) ==="
mkdir -p "$SCRIPTS_DIR" "$(dirname "$LEDGER")"
cp -f ~/jarvis/scripts/deep_analysis_evaluator.py "$SCRIPTS_DIR/deep_analysis_evaluator.py"
cp -f ~/jarvis/scripts/verify_deep_analysis.py   "$SCRIPTS_DIR/verify_deep_analysis.py"
chmod +x "$SCRIPTS_DIR/verify_deep_analysis.py"
ls -la "$SCRIPTS_DIR/deep_analysis_evaluator.py" "$SCRIPTS_DIR/verify_deep_analysis.py"

echo "=== [2] Init secret (sekali, chmod 600) ==="
if [ ! -s "$SECRET" ]; then
  ( umask 077; head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$SECRET" )
  chmod 600 "$SECRET"; echo "secret dibuat: $SECRET"
else
  echo "secret sudah ada: $SECRET"
fi

echo "=== [3] Wire directive HARD ke USER.md ==="
OLD="## DEEP ANALYSIS AUTO-HOOK — Evaluator Auto-Trigger"
grep -qF "$OLD" "$USER_MD" && echo "NOTE: directive SOFT lama ada — hapus manual blok: $OLD"
M="## DEEP ANALYSIS GATE — RECEIPT WAJIB (HARD)"
if grep -qF "$M" "$USER_MD"; then
  echo "SKIP: directive sudah ada: $M"
else
  cat >> "$USER_MD" <<'DIRECTIVE'

## DEEP ANALYSIS GATE — RECEIPT WAJIB (HARD)
Setiap output Deep Analysis WAJIB lewat gate ini. Verdict tanpa receipt = ASBUN = DITOLAK.

### ATURAN (MANDATORY, NO EXCEPTIONS)
1. Simpan output ke file:
   printf '%s' "<full deep analysis>" > /tmp/deep_analysis_eval.txt
2. Jalankan evaluator (WAJIB, jangan skip, jangan karang):
   /home/arif/.hermes/hermes-agent/venv/bin/python \
     ~/.hermes/scripts/deep_analysis_evaluator.py \
     --file /tmp/deep_analysis_eval.txt --json > /tmp/deep_analysis_verdict.json
3. Verdict cuma boleh ditulis kalau JSON punya "eval_receipt" DAN lolos:
   /home/arif/.hermes/hermes-agent/venv/bin/python \
     ~/.hermes/scripts/verify_deep_analysis.py \
     --analysis-file /tmp/deep_analysis_eval.txt \
     --receipt "<eval_receipt dari verdict>"
   Exit 0 = sah. Exit != 0 = DILARANG nulis blok verdict; lapor gagal apa adanya.
4. Blok verdict WAJIB memuat baris Receipt persis dari evaluator (Model, Skor, Receipt).
5. DILARANG: nulis PASS/skor tanpa langkah 2-3; ngarang receipt; nyalin receipt
   lama utk analisa beda (sha256 gak cocok -> verifier tolak).

Receipt = HMAC-SHA256 (secret lokal) atas sha256(analisa)+model+waktu+verdict+skor.
verify_deep_analysis.py nangkep setiap pemalsuan secara deterministik.

### RUNTIME BLOCK
verify_deep_analysis.py didaftarkan sebagai check untuk action-gate v2 / shadow
resolver (layer HARD yang sama dengan INTEGRITY ENFORCEMENT).
DIRECTIVE
  echo "OK: directive HARD appended"
fi

echo "=== PROOF ==="
grep -nF "$M" "$USER_MD"
echo "--- self-test: verifier HARUS nolak receipt ngasal ---"
printf '%s' "dummy analysis untuk self test aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" > /tmp/_datest.txt
if "$PY" "$SCRIPTS_DIR/verify_deep_analysis.py" --analysis-file /tmp/_datest.txt --receipt deadbeef; then
  echo "BUG: harusnya REJECT"; exit 1
else
  echo "OK: verifier nolak receipt palsu (exit != 0)"
fi
echo "=== DEPLOY COMPLETE ==="
echo "rollback: cp ${USER_MD}.bak.${TS} $USER_MD"
