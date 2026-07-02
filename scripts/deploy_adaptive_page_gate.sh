#!/usr/bin/env bash
# deploy_adaptive_page_gate.sh (v2)
# Makes PIPA4 page-count check adaptive (anti-padding) across ALL active audit .py scripts.
# When DISABLE_PAGE_TOPUP=1 is set in env, the gate no longer emits NEEDS_PAGE_TOPUP.
# Idempotent + per-file backup. No restart needed.
set -uo pipefail

BASE="$HOME/.hermes/pipelines/pipa4"
TS="$(date +%Y%m%d_%H%M%S)"
PATTERN='if f == "page_count":'

echo "=== [1] Finding active audit scripts (*.py, excluding pycache) ==="
FILES="$(grep -rlF "$PATTERN" "$BASE" --include='*.py' 2>/dev/null | grep -v '__pycache__' || true)"

if [ -z "$FILES" ]; then
  echo "No active .py with UNPATCHED pattern found. Checking if already patched..."
  grep -rn "DISABLE_PAGE_TOPUP" "$BASE" --include='*.py' 2>/dev/null | grep -v '__pycache__' || echo "(no patched marker either -- verify manually)"
else
  echo "$FILES"
  echo "=== [2] Patching each ==="
  echo "$FILES" | while IFS= read -r f; do
    [ -f "$f" ] || continue
    cp "$f" "${f}.bak.${TS}"
    python3 - "$f" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1])
code = p.read_text(encoding="utf-8")
old = 'if f == "page_count":'
new = 'if f == "page_count" and not os.environ.get("DISABLE_PAGE_TOPUP"):'
if new in code:
    print("   already patched:", p.name)
else:
    code = code.replace(old, new)
    if "import os" not in code:
        code = "import os\n" + code
        print("   + added import os")
    p.write_text(code, encoding="utf-8")
    print("   patched:", p.name)
PY
  done
fi

echo "=== [3] Clearing pycache under pipa4 ==="
find "$BASE" -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null || true
echo "cleared"

echo "=== [4] Verify: any UNPATCHED active file left? (should be empty) ==="
LEFT="$(grep -rlF "$PATTERN" "$BASE" --include='*.py' 2>/dev/null | grep -v '__pycache__' || true)"
if [ -z "$LEFT" ]; then echo "OK: no unpatched active .py remain."; else echo "STILL UNPATCHED:"; echo "$LEFT"; fi

echo "=== [5] Show patched lines ==="
grep -rn 'DISABLE_PAGE_TOPUP' "$BASE" --include='*.py' 2>/dev/null | grep -v '__pycache__' || true
echo "=== DONE. Bypass short/business docs with: DISABLE_PAGE_TOPUP=1 ==="
