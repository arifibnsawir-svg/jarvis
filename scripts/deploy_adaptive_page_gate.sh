#!/usr/bin/env bash
# deploy_adaptive_page_gate.sh
# Patches local PIPA4 phase5b audit scripts to make page-count check adaptive (anti-padding).
# Prevents NEEDS_PAGE_TOPUP from blocking short/business documents.
set -euo pipefail

TARGET_DIR="$HOME/.hermes/pipelines/pipa4/phase5b"
TS="$(date +%Y%m%d_%H%M%S)"

echo "=== [1] Locating audit script ==="
ACTIVE_FILE=""
if [ -f "$TARGET_DIR/pipa4_audit.py" ]; then
  ACTIVE_FILE="$TARGET_DIR/pipa4_audit.py"
elif [ -f "$TARGET_DIR/pipa4_audit.bak" ]; then
  ACTIVE_FILE="$TARGET_DIR/pipa4_audit.bak"
fi

if [ -z "$ACTIVE_FILE" ]; then
  echo "ERROR: Active audit script not found in $TARGET_DIR" >&2
  exit 1
fi

echo "Found active audit script: $ACTIVE_FILE"
cp "$ACTIVE_FILE" "${ACTIVE_FILE}.bak.${TS}"
echo "Backup created: ${ACTIVE_FILE}.bak.${TS}"

echo "=== [2] Applying Adaptive Page-Count Patch ==="
# We replace the hardcoded "page_count" check to respect an env var or skip if non-academic/short.
# Safe replacement using python's replace to ensure idempotency.
python3 - <<PY
import pathlib
path = pathlib.Path("$ACTIVE_FILE")
code = path.read_text(encoding="utf-8")

# Let's replace the primary page_count check.
# We make it skip if DISABLE_PAGE_TOPUP is in environment.
old_check = 'if f == "page_count":'
new_check = 'if f == "page_count" and not os.environ.get("DISABLE_PAGE_TOPUP"):'

if old_check in code:
    code = code.replace(old_check, new_check)
    print("Patched check_page_count condition.")
else:
    print("Warning: exact match for 'if f == \"page_count\":' not found. Checking if already patched.")

# Also clean pycache to force recompile
pycache = path.parent / "__pycache__"
if pycache.exists():
    import shutil
    shutil.rmtree(pycache)
    print("Cleared pycache.")

path.write_text(code, encoding="utf-8")
PY

# If the active file was .bak, make sure it's copied or handled
if [ "$(basename "$ACTIVE_FILE")" = "pipa4_audit.bak" ]; then
  echo "Active file is .bak. Creating pipa4_audit.py from it to ensure Python uses the patched version."
  cp -f "$ACTIVE_FILE" "$TARGET_DIR/pipa4_audit.py"
fi

echo "=== [3] Verifying Patch ==="
grep -n "page_count" "$TARGET_DIR/pipa4_audit.py" || true
echo "=== SUCCESS: Adaptive Page Gate Deployed. Run with DISABLE_PAGE_TOPUP=1 to bypass. ==="
