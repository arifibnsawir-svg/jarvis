#!/usr/bin/env bash
# Wiring ROUTING artefak (D-soft enforcement): direktif always-on di USER.md yg MAKSA Jarvis
# milih skill spesialis terbaik (bukan freehand / guard generik). Idempotent + backup. No restart (aktif di /new).
set -uo pipefail
"${HERMES_PY:-python3}" - <<'PY'
import pathlib, shutil, time
um = pathlib.Path.home()/".hermes/memories/USER.md"
ts = time.strftime("%Y%m%d_%H%M%S")
MARK = "ARTIFACT ROUTING (always): pick the BEST installed skill"
d = ("ARTIFACT ROUTING (always): pick the BEST installed skill for the intent; do NOT freehand or fall back to a "
     "generic guard. Map: (1) wow/business/marketing/pitch/personal-brand presentation -> use claude-design "
     "(default) or popular-web-designs (when a named system like Stripe/Linear/Vercel is requested) -> single-file "
     "HTML deck, dark/modern, SVG/line icons, NO emoji, no gradient-blob slop. (2) academic/tugas (makalah, PDF->Word "
     "reading report, defense/seminar PPT, mini-book) -> use academic-document-factory (+ office-document-ops for file "
     "ops) -> editable DOCX/PPTX with source labels. (3) quick simple editable pptx -> powerpoint or render_deck. "
     "(4) infographic -> baoyu-infographic. ALWAYS regardless of skill: apply the humanizer to prose; NO emoji unless "
     "explicitly requested (use SVG/line icons in decks); any quantitative claim without a verifiable source MUST be "
     "labeled 'estimasi - sumber belum terverifikasi' or omitted (cite-or-abstain); never declare FINAL/READY without "
     "validation (gate authority, not LLM claim).")
if not um.exists():
    print("RESULT: FAIL (USER.md not found)"); raise SystemExit
t = um.read_text(encoding="utf-8")
if MARK in t:
    print("RESULT: SKIP (sudah ada)")
else:
    shutil.copy(um, str(um)+".bak."+ts)
    um.write_text(t.rstrip()+"\n"+d+"\n", encoding="utf-8")
    print("BACKUP:", str(um)+".bak."+ts)
    print("RESULT:", "SUCCESS" if MARK in um.read_text(encoding="utf-8") else "FAIL")
PY
echo "=== PROOF ==="
grep -n "ARTIFACT ROUTING" ~/.hermes/memories/USER.md
