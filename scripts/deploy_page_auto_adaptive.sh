#!/usr/bin/env bash
# deploy_page_auto_adaptive.sh
# AUTOMATIC page-count adaptivity keyed on SPEC.is_academic:
#   - academic docs (is_academic=true): page targets ENFORCED (strict, unchanged)
#   - non-academic (business/report/personal): NEEDS_PAGE_TOPUP auto-bypassed
# PIPA4 council + EVERY other gate check stay strict for ALL doc types.
# Idempotent, per-file backup. This script is the reproducible source of change.
set -uo pipefail
TS="$(date +%Y%m%d_%H%M%S)"

patch_hook () {
  local f="$1"
  [ -f "$f" ] || return 0
  if grep -q "disable_page_topup" "$f"; then echo "   already patched: $f"; return 0; fi
  cp -p "$f" "${f}.bak.${TS}"
  python3 - "$f" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
o = s
sig_old = ('def run(artifact_path: str, constraint_name: Optional[str] = None,\n'
           '        timeout_seconds: int = 420) -> dict:')
sig_new = ('def run(artifact_path: str, constraint_name: Optional[str] = None,\n'
           '        timeout_seconds: int = 420, disable_page_topup: bool = False) -> dict:')
s = s.replace(sig_old, sig_new)
sub_old = ('    try:\n'
           '        proc = subprocess.run(\n'
           '            ["bash", gate_sh, artifact_path, constraint],\n'
           '            capture_output=True, text=True, timeout=timeout_seconds,\n'
           '        )')
sub_new = ('    try:\n'
           '        _env = os.environ.copy()\n'
           '        if disable_page_topup:\n'
           '            _env["DISABLE_PAGE_TOPUP"] = "1"\n'
           '        proc = subprocess.run(\n'
           '            ["bash", gate_sh, artifact_path, constraint],\n'
           '            capture_output=True, text=True, timeout=timeout_seconds, env=_env,\n'
           '        )')
s = s.replace(sub_old, sub_new)
if s != o:
    open(p, "w", encoding="utf-8").write(s)
    print("   patched:", p)
else:
    print("   WARN anchors not found (no change):", p)
PY
}

echo "=== [1] Patch pipa4_hook.py (live + repo copies) ==="
patch_hook "$HOME/.hermes/scripts/pipa4_hook.py"
patch_hook "$HOME/jarvis/scripts/pipa4_hook.py"

echo "=== [2] Patch factory orchestrator.py ==="
ORCHS="$(find "$HOME" -maxdepth 6 -type f -path '*jarvis_document_factory/docfactory/orchestrator.py' 2>/dev/null)"
if [ -z "$ORCHS" ]; then
  echo "   WARN: orchestrator.py not found under \$HOME"
else
  echo "$ORCHS" | while IFS= read -r f; do
    if grep -q "_disable_topup" "$f"; then echo "   already patched: $f"; continue; fi
    cp -p "$f" "${f}.bak.${TS}"
    python3 - "$f" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = '                pipa4_result = pipa4_mod.run(target_path, constraint_name=constraint)'
new = ('                # Page-count adaptivity: only academic docs held to page targets.\n'
       '                # Non-academic (business/report/personal) bypass NEEDS_PAGE_TOPUP.\n'
       '                # Council + all other checks stay strict regardless.\n'
       '                _disable_topup = not getattr(spec, "is_academic", False)\n'
       '                pipa4_result = pipa4_mod.run(\n'
       '                    target_path, constraint_name=constraint,\n'
       '                    disable_page_topup=_disable_topup,\n'
       '                )')
if old in s:
    open(p, "w", encoding="utf-8").write(s.replace(old, new))
    print("   patched:", p)
else:
    print("   WARN anchor not found:", p)
PY
  done
fi

echo "=== [3] Clear pycache ==="
find "$HOME/.hermes" -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null || true
[ -n "$ORCHS" ] && echo "$ORCHS" | while IFS= read -r f; do
  find "$(dirname "$f")" -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null || true
done
echo "cleared"

echo "=== [4] Verify ==="
echo "-- hook (expect disable_page_topup + env) --"
grep -n "disable_page_topup" "$HOME/.hermes/scripts/pipa4_hook.py" 2>/dev/null | head
echo "-- orchestrator (expect _disable_topup) --"
[ -n "$ORCHS" ] && echo "$ORCHS" | while IFS= read -r f; do grep -n "_disable_topup" "$f"; done
echo "=== DONE. academic=strict page targets, non-academic=adaptive; council stays strict ==="
