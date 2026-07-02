#!/usr/bin/env bash
# =============================================================================
# deploy_deep_analysis_autohook.sh
# -----------------------------------------------------------------------------
# AUTO-HOOK for Deep Analysis: after Jarvis produces Deep Analysis output,
# automatically runs deep_analysis_evaluator.py via 9Router (jarvis-reason)
# and includes the JSON verdict in the response.
#
# Flow:
#   deep analysis output → save to /tmp → evaluator → jarvis-reason →
#   JSON verdict (PASS/NEEDS_REVISION + score + strengths/weaknesses)
#
# SOFT layer: USER.md directive. No restart.
# =============================================================================
set -euo pipefail

USER_MD="${HERMES_USER_MD:-$HOME/.hermes/memories/USER.md}"
TS="$(date +%Y%m%d_%H%M%S)"

[ -f "$USER_MD" ] || { echo "ERROR: USER.md tidak ada di $USER_MD" >&2; exit 2; }
cp "$USER_MD" "${USER_MD}.bak.${TS}"
echo "backup: ${USER_MD}.bak.${TS}"

M="## DEEP ANALYSIS AUTO-HOOK — Evaluator Auto-Trigger"
if grep -qF "$M" "$USER_MD"; then
  echo "SKIP: directive already exists: $M"
  exit 0
fi

cat >> "$USER_MD" <<'DIRECTIVE'

## DEEP ANALYSIS AUTO-HOOK — Evaluator Auto-Trigger
Setiap kali SELESAI menulis output Deep Analysis (mode "analisa mendalam",
"riset", "deep dive", "multiperspektif", dll), OTOMATIS jalankan:

1. Simpan output ke file:
   echo "<full deep analysis output>" > /tmp/deep_analysis_eval.txt

2. Jalankan evaluator via jarvis-reason:
   /home/arif/.hermes/hermes-agent/venv/bin/python \
     ~/.hermes/scripts/deep_analysis_evaluator.py \
     --file /tmp/deep_analysis_eval.txt --json

3. Sertakan JSON verdict di akhir respons:
   ```
   ---
   ## Evaluasi Kualitas (via jarvis-reason)
   - Verdict: PASS/NEEDS_REVISION
   - Model: [nama model]
   - Skor: X/100
   - Strengths: [...]
   - Weaknesses: [...]
   - Fix suggestions: [...]
   ```

ATURAN:
- Evaluasi WAJIB dijalankan. JANGAN skip.
- Kalau evaluator ERROR: laporkan error-nya, bukan verdict palsu.
- Kalau NEEDS_REVISION: tawarkan untuk perbaiki weaknesses yang disebut.
- Evaluator memanggil jarvis-reason via 9Router — sabar, bisa ~10-30 detik.

Token hemat: jarvis-agent menulis (2000 token), jarvis-reason mengevaluasi
(500 token). Evaluasi TIDAK menggantikan gate — dia advisory.

Ini memastikan setiap Deep Analysis lo TAJAM dan LAYAK DIPERCAYA —
bukan sekadar asbun panjang.
DIRECTIVE

echo "=== PROOF ==="
grep -nF "$M" "$USER_MD"
echo "---"
echo "=== DEPLOY COMPLETE ==="
echo "Auto-hook active: evaluator runs after every Deep Analysis."
echo "rollback: cp ${USER_MD}.bak.${TS} $USER_MD"
