#!/usr/bin/env bash
# deploy_evidence_a2_fix.sh
# Follow-up to deploy_evidence_policy.sh. Closes 2 gaps that left evidence
# review NON audience-aware in practice (business/light still got flagged):
#   GAP-1 (A1 single-quote): pipa4_audit (extensionless) uses
#         result['evidence'] = 'PASS' if citations else 'FAIL'   (single quotes)
#         -> old double-quote anchor missed it -> stayed RAW.
#   GAP-2 (A2 adv/gate form): phase5b pipa4_audit & pipa4_audit.py use
#         adv["citation_suspicion"] = gate.get("citation_count", 0) < 2
#         (advisory dict `adv`, gate dict `gate`, NO `constraint` in scope)
#         -> old A2 anchor (advisory/gate_result form) missed it -> RAW,
#         so NEEDS_EVIDENCE_REVIEW still fired even when evidence PASSED.
# academic (strict/default) UNCHANGED; only light|off suppressed.
# For adv/gate advisory (no constraint param) we key suspicion off the
# already-policy-aware evidence result: suspicious only when evidence == FAIL.
# Idempotent + timestamped backups. No restart needed.
set -uo pipefail
BASE="${PIPA4_DIR:-$HOME/.hermes/pipelines/pipa4}"
TS="$(date +%Y%m%d_%H%M%S)"
[ -d "$BASE" ] || { echo "ERROR: $BASE not found" >&2; exit 2; }

echo "=== [1] Patch GAP-1 (A1 single-quote) + GAP-2 (A2 adv/gate) ==="
for f in \
  "$BASE/phase5b/pipa4_audit" \
  "$BASE/phase5b/pipa4_audit.py" \
  "$BASE/phase5a/pipa4_audit_dryrun.py" \
  "$BASE/phase4/pipa4_audit_dryrun.py"; do
  [ -f "$f" ] || continue
  python3 - "$f" "$TS" <<'PY'
import sys, re, pathlib
p, ts = pathlib.Path(sys.argv[1]), sys.argv[2]
code = p.read_text(encoding="utf-8"); orig = code
a1 = re.compile(r"result\['evidence'\]\s*=\s*'PASS'\s+if\s+citations\s+else\s+'FAIL'")
a1n = "result['evidence'] = 'PASS' if (citations or (constraint or {}).get('evidence_policy', 'strict') in ('off', 'light')) else 'FAIL'"
n1 = len(a1.findall(code)); code = a1.sub(lambda m: a1n, code)
a2 = re.compile(r'adv\["citation_suspicion"\]\s*=\s*gate\.get\("citation_count",\s*0\)\s*<\s*2(?!\s*and)')
a2n = 'adv["citation_suspicion"] = gate.get("citation_count", 0) < 2 and gate.get("evidence") == "FAIL"'
n2 = len(a2.findall(code)); code = a2.sub(lambda m: a2n, code)
if code != orig:
    pathlib.Path(str(p) + ".bak." + ts).write_text(orig, encoding="utf-8")
    p.write_text(code, encoding="utf-8")
    print("   PATCHED %-22s a1_single=%d a2=%d (bak .%s)" % (p.name, n1, n2, ts))
else:
    print("   ok/none %-22s a1_single=%d a2=%d" % (p.name, n1, n2))
PY
done

echo "=== [2] Clear pycache ==="
find "$BASE" -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null || true; echo cleared

echo "=== [3] Verify NO raw anchors remain (both quote styles + both A2 forms) ==="
grep -rnI  --exclude-dir=__pycache__ "result\['evidence'\] = 'PASS' if citations else 'FAIL'" "$BASE" 2>/dev/null | grep -v '\.bak' && echo "^ A1 single RAW" || echo "OK: no raw A1 single-quote"
grep -rnFI --exclude-dir=__pycache__ 'result["evidence"] = "PASS" if citations else "FAIL"' "$BASE" 2>/dev/null | grep -v '\.bak' && echo "^ A1 double RAW" || echo "OK: no raw A1 double-quote"
grep -rnEI --exclude-dir=__pycache__ 'adv\["citation_suspicion"\] = gate\.get\("citation_count", 0\) < 2$' "$BASE" 2>/dev/null | grep -v '\.bak' && echo "^ A2 adv/gate RAW" || echo "OK: no raw A2 adv/gate"
grep -rnFI --exclude-dir=__pycache__ 'advisory["citation_suspicion"] = gate_result.get("citation_count", 0) < 2' "$BASE" 2>/dev/null | grep -v '\.bak' && echo "^ A2 advisory RAW" || echo "OK: no raw A2 advisory"

echo "=== [4] PROOF matrix (real hook run, explicit PDF, no glob) ==="
PDF="${PIPA4_TEST_PDF:-/home/arif/.hermes/outbox/cikarang_feasibility.pdf}"
if [ -f "$PDF" ]; then
python3 - "$PDF" <<'PY'
import importlib.util, os, json, sys, glob
PDF = sys.argv[1]
hp = os.path.expanduser("~/.hermes/scripts/pipa4_hook.py")
sp = importlib.util.spec_from_file_location("pipa4_hook", hp)
m = importlib.util.module_from_spec(sp); sp.loader.exec_module(m)
def probe(cn, dpt):
    m.run(PDF, constraint_name=cn, disable_page_topup=dpt)
    fs = glob.glob(os.path.expanduser("~/.hermes/pipelines/pipa4/*/runs/*/PIPA4_AUDIT_RESULT.json"))
    blob = json.dumps(json.load(open(max(fs, key=os.path.getmtime))), default=str)
    return "NEEDS_EVIDENCE_REVIEW" in blob
b = probe("business_document.json", True)
a = probe("academic_book.json", True)
print("  business(light)  NEEDS_EVIDENCE_REVIEW:", b, "(expect False)")
print("  academic(strict) NEEDS_EVIDENCE_REVIEW:", a, "(expect True)")
print("  RESULT:", "PASS audience-aware OK" if (b is False and a is True) else "FAIL - investigate")
PY
else
  echo "  (skip proof: test PDF not found at $PDF)"
fi
echo "=== DONE. strict=citations wajib (default/akademik); light|off=no evidence gate ==="
