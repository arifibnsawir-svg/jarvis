#!/usr/bin/env bash
# deploy_evidence_policy.sh
# Makes PIPA4 evidence-review AUDIENCE-AWARE, keyed on the constraint's
# "evidence_policy" field, across EVERY active audit script under
# ~/.hermes/pipelines/pipa4 (incl. extension-less executables like `pipa4_audit`).
#
# evidence_policy semantics (read from the loaded constraint dict):
#   - "strict"        : citations required; missing -> evidence FAIL + citation_suspicion
#                       (DEFAULT / academic, UNCHANGED)
#   - "light" | "off" : missing citations no longer FAIL, no citation_suspicion
#                       -> no NEEDS_EVIDENCE_REVIEW
# Any constraint WITHOUT the field defaults to "strict" => zero behavior change
# for academic_book.json / makalah_short.json.
#
# Idempotent + per-file timestamped backup. No restart needed.
set -uo pipefail

BASE="${PIPA4_DIR:-$HOME/.hermes/pipelines/pipa4}"
TS="$(date +%Y%m%d_%H%M%S)"

A1='result["evidence"] = "PASS" if citations else "FAIL"'
A2='advisory["citation_suspicion"] = gate_result.get("citation_count", 0) < 2'

if [ ! -d "$BASE" ]; then
  echo "ERROR: $BASE not found" >&2
  exit 2
fi

echo "=== [1] Finding ALL active audit files that decide evidence (any extension) ==="
FILES="$( { grep -rlI --exclude-dir=__pycache__ -F "$A1" "$BASE" 2>/dev/null; grep -rlI --exclude-dir=__pycache__ -F "$A2" "$BASE" 2>/dev/null; } | grep -v '\.bak' | sort -u || true)"

if [ -z "$FILES" ]; then
  echo "No active file with evidence anchors found. Checking existing patched markers..."
  grep -rnI --exclude-dir=__pycache__ 'evidence_policy' "$BASE" 2>/dev/null | grep -v '\.bak' || echo "(no patched marker either -- verify manually)"
else
  echo "$FILES"
  echo "=== [2] Patching each (backup + constraint-driven evidence policy) ==="
  echo "$FILES" | while IFS= read -r f; do
    [ -f "$f" ] || continue
    cp -p "$f" "${f}.bak.${TS}"
    python3 - "$f" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1])
code = p.read_text(encoding="utf-8")
orig = code

a1_old = 'result["evidence"] = "PASS" if citations else "FAIL"'
a1_new = 'result["evidence"] = "PASS" if (citations or (constraint or {}).get("evidence_policy", "strict") in ("off", "light")) else "FAIL"'

a2_old = 'advisory["citation_suspicion"] = gate_result.get("citation_count", 0) < 2'
a2_new = 'advisory["citation_suspicion"] = (gate_result.get("citation_count", 0) < 2) and (constraint or {}).get("evidence_policy", "strict") == "strict"'

changed = []
if a1_new in code:
    print("   A1 already patched:", p.name)
elif a1_old in code:
    code = code.replace(a1_old, a1_new)
    changed.append("A1(evidence)")
else:
    print("   A1 anchor NOT found:", p.name)

if a2_new in code:
    print("   A2 already patched:", p.name)
elif a2_old in code:
    code = code.replace(a2_old, a2_new)
    changed.append("A2(citation_suspicion)")
else:
    print("   A2 anchor NOT found:", p.name)

if code != orig:
    p.write_text(code, encoding="utf-8")
    print("   patched [%s]: %s" % (", ".join(changed), p.name))
else:
    print("   no change:", p.name)
PY
  done
fi

echo "=== [3] Clearing pycache under pipa4 ==="
find "$BASE" -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null || true
echo "cleared"

echo "=== [4] Verify: patched markers across all files (expect evidence_policy) ==="
grep -rnI --exclude-dir=__pycache__ 'evidence_policy' "$BASE" 2>/dev/null | grep -v '\.bak' || echo "(none -- check anchors above)"

echo "=== [5] Any RAW (unpatched) evidence anchor left? (MUST be OK on both) ==="
grep -rlI --exclude-dir=__pycache__ -F "$A1" "$BASE" 2>/dev/null | grep -v '\.bak' && echo "^ A1 STILL RAW" || echo "OK: no raw A1 remains"
grep -rlI --exclude-dir=__pycache__ -F "$A2" "$BASE" 2>/dev/null | grep -v '\.bak' && echo "^ A2 STILL RAW" || echo "OK: no raw A2 remains"

echo "=== DONE. strict=citations required (default/academic); light|off=no evidence gate ==="
