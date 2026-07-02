#!/usr/bin/env bash
# deploy_adaptive_page_gate.sh (v3)
# Makes the PIPA4 page-count check adaptive (anti-padding) across EVERY active
# audit script under ~/.hermes/pipelines/pipa4 -- including extension-less
# executables (e.g. `pipa4_audit`) and phase5a/phase5b dryrun audits.
#
# v2 bug: used `--include='*.py'`, so it silently skipped the extension-less
# executable `pipa4_audit` -- which is exactly the file phase7a actually runs.
# v3 drops the extension filter and scans all text files for the pattern.
#
# When DISABLE_PAGE_TOPUP=1 is set in env, the gate no longer emits
# NEEDS_PAGE_TOPUP. Idempotent + per-file timestamped backup. No restart needed.
set -uo pipefail

BASE="${PIPA4_DIR:-$HOME/.hermes/pipelines/pipa4}"
TS="$(date +%Y%m%d_%H%M%S)"
UNPATCHED='if f == "page_count":'
PATCHED='if f == "page_count" and not os.environ.get("DISABLE_PAGE_TOPUP"):'

if [ ! -d "$BASE" ]; then
  echo "ERROR: $BASE not found" >&2
  exit 2
fi

echo "=== [1] Finding ALL active audit files (any extension, excl. pycache/backups) ==="
# -r recursive, -l list files, -I skip binary. NO --include filter this time so
# extension-less executables like `pipa4_audit` are included.
FILES="$(grep -rlI --exclude-dir=__pycache__ -F "$UNPATCHED" "$BASE" 2>/dev/null | grep -v '\.bak' || true)"

if [ -z "$FILES" ]; then
  echo "No active file with UNPATCHED pattern found. Checking existing patched markers..."
  grep -rnI --exclude-dir=__pycache__ 'DISABLE_PAGE_TOPUP' "$BASE" 2>/dev/null | grep -v '\.bak' || echo "(no patched marker either -- verify manually)"
else
  echo "$FILES"
  echo "=== [2] Patching each (backup + env-guard + ensure import os) ==="
  echo "$FILES" | while IFS= read -r f; do
    [ -f "$f" ] || continue
    cp -p "$f" "${f}.bak.${TS}"
    python3 - "$f" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1])
code = p.read_text(encoding="utf-8")
old = 'if f == "page_count":'
new = 'if f == "page_count" and not os.environ.get("DISABLE_PAGE_TOPUP"):'
if old not in code and new in code:
    print("   already patched:", p.name)
else:
    code = code.replace(old, new)
    # Ensure `import os` exists, WITHOUT breaking a shebang / coding line.
    import re
    has_os = re.search(r'(?m)^[ \t]*import os([ \t]|$)', code) is not None
    if not has_os:
        lines = code.split("\n")
        insert_at = 0
        if lines and lines[0].startswith("#!"):
            insert_at = 1
        if len(lines) > insert_at and "coding" in lines[insert_at] and lines[insert_at].lstrip().startswith("#"):
            insert_at += 1
        lines.insert(insert_at, "import os")
        code = "\n".join(lines)
        print("   + added import os")
    p.write_text(code, encoding="utf-8")
    print("   patched:", p.name)
PY
  done
fi

echo "=== [3] Clearing pycache under pipa4 ==="
find "$BASE" -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null || true
echo "cleared"

echo "=== [4] Verify: any UNPATCHED active file left? (MUST be empty) ==="
LEFT="$(grep -rlI --exclude-dir=__pycache__ -F "$UNPATCHED" "$BASE" 2>/dev/null | grep -v '\.bak' || true)"
if [ -z "$LEFT" ]; then
  echo "OK: no unpatched active file remains."
else
  echo "STILL UNPATCHED (needs attention):"
  echo "$LEFT"
  exit 1
fi

echo "=== [5] Show patched lines across all files ==="
grep -rnI --exclude-dir=__pycache__ 'DISABLE_PAGE_TOPUP' "$BASE" 2>/dev/null | grep -v '\.bak' || true
echo "=== DONE (v3). Bypass short/business docs with: DISABLE_PAGE_TOPUP=1 ==="
