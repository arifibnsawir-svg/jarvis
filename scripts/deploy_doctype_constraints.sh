#!/usr/bin/env bash
# deploy_doctype_constraints.sh
# Audience-aware PIPA4 constraints by doc_type. Academic stays strict
# (academic_book.json / makalah_short.json, UNCHANGED). Non-academic docs are
# judged by audience-appropriate standards instead of academic-book rules
# (no more "missing bab/daftar pustaka" flagged on a business doc).
# Council + humanizer + anti-false-ready stay strict; only the JUDGING STANDARD adapts.
# Idempotent, per-file backup. Reproducible source of change.
set -uo pipefail
TS="$(date +%Y%m%d_%H%M%S)"
CDIR="$HOME/.hermes/pipelines/pipa4/constraints"
SRC="$HOME/jarvis/pipelines/pipa4/constraints"

echo "=== [1] Install non-academic constraint files -> $CDIR ==="
mkdir -p "$CDIR"
if [ ! -d "$SRC" ]; then
  echo "   WARN: source $SRC not found (did you pull jarvis?)"
else
  for src in "$SRC"/*.json; do
    [ -f "$src" ] || continue
    dst="$CDIR/$(basename "$src")"
    [ -f "$dst" ] && cp -p "$dst" "${dst}.bak.${TS}"
    cp -p "$src" "$dst"
    echo "   installed: $dst"
  done
fi

echo "=== [2] Wire doc_type -> constraint in orchestrator.py ==="
ORCHS="$(find "$HOME" -maxdepth 6 -type f -path '*jarvis_document_factory/docfactory/orchestrator.py' 2>/dev/null)"
if [ -z "$ORCHS" ]; then
  echo "   WARN: orchestrator.py not found"
else
  echo "$ORCHS" | while IFS= read -r f; do
    if grep -q "general_document.json" "$f"; then echo "   already wired: $f"; continue; fi
    cp -p "$f" "${f}.bak.${TS}"
    python3 - "$f" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = '                constraint = getattr(spec, "pipa4_constraint", None) or None'
add = """
                if not constraint and not getattr(spec, "is_academic", False):
                    _dt = (getattr(spec, "doc_type", "") or "").lower()
                    if any(k in _dt for k in ("business", "bisnis", "proposal", "feasibility", "kelayakan", "pitch", "report", "laporan", "plan", "memo")):
                        constraint = "business_document.json"
                    elif any(k in _dt for k in ("creative", "kreatif", "story", "cerita", "novel", "poem", "puisi", "fiksi", "script", "naskah", "lirik")):
                        constraint = "creative_document.json"
                    elif any(k in _dt for k in ("personal", "pribadi", "letter", "surat", "cv", "resume", "essay", "esai", "opini", "blog")):
                        constraint = "personal_document.json"
                    else:
                        constraint = "general_document.json"
"""
if old in s and "general_document.json" not in s:
    open(p, "w", encoding="utf-8").write(s.replace(old, old + add))
    print("   wired:", p)
else:
    print("   WARN anchor missing or already wired:", p)
PY
  done
fi

echo "=== [3] Clear pycache ==="
[ -n "$ORCHS" ] && echo "$ORCHS" | while IFS= read -r f; do
  find "$(dirname "$f")" -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null || true
done
echo "cleared"

echo "=== [4] Verify ==="
ls -la "$CDIR"
[ -n "$ORCHS" ] && echo "$ORCHS" | while IFS= read -r f; do grep -nE "business_document.json|general_document.json" "$f"; done
echo "=== DONE. doc_type-aware constraints deployed. Academic strict; non-academic audience-aware. ==="
