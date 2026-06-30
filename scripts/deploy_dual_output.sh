#!/usr/bin/env bash
# Deploy DUAL-OUTPUT deck: tool html_to_pdf + render_deck ke ~/.hermes/scripts/ + direktif always-on USER.md.
# "Keduanya": HTML(wow)->PDF + .pptx editable dari 1 konten. Larang pptxgenjs/sharp (crash di CPU Acer).
# Idempotent + backup. No restart (aktif di /new).
set -uo pipefail
mkdir -p ~/.hermes/scripts
cp -f ~/jarvis/scripts/html_to_pdf.sh ~/.hermes/scripts/html_to_pdf.sh && chmod +x ~/.hermes/scripts/html_to_pdf.sh
cp -f ~/jarvis/renderer/render_deck.py ~/.hermes/scripts/render_deck.py
echo "tools ter-deploy:"; ls -la ~/.hermes/scripts/html_to_pdf.sh ~/.hermes/scripts/render_deck.py

"${HERMES_PY:-python3}" - <<'PY'
import pathlib, shutil, time
um = pathlib.Path.home()/".hermes/memories/USER.md"
ts = time.strftime("%Y%m%d_%H%M%S")
MARK = "DUAL-OUTPUT DECKS"
d = ("DUAL-OUTPUT DECKS: when a presentation/deck is requested for delivery and BOTH a polished and an editable "
     "version are useful (default for tugas/akademik & business pitch), produce BOTH from the SAME content+sources: "
     "(1) POLISHED -> wow HTML via claude-design, INCLUDE @media print / @page landscape CSS so each slide = one "
     "page, then convert to PDF with ~/.hermes/scripts/html_to_pdf.sh <file.html>. (2) EDITABLE -> .pptx via "
     "python3 ~/.hermes/scripts/render_deck.py <spec.json> <out.pptx> (preset academic/business/dark). Keep content, "
     "structure, and sources IDENTICAL across both; apply humanizer; NO emoji (SVG/line icons in HTML, shape markers "
     "in pptx); academic sources Indonesia-first + cite-or-abstain. Deliver both files and clearly label polished vs "
     "editable. DO NOT use pptxgenjs or the 'sharp' npm package (native binary crashes on this CPU: Illegal "
     "instruction); for editable pptx use render_deck.py only.")
if not um.exists():
    print("RESULT: FAIL (USER.md not found)"); raise SystemExit
t = um.read_text(encoding="utf-8")
if MARK in t:
    print("RESULT: SKIP (sudah ada)")
else:
    shutil.copy(um, str(um)+".bak."+ts)
    um.write_text(t.rstrip()+"\n"+d+"\n", encoding="utf-8")
    print("BACKUP:", str(um)+".bak."+ts); print("RESULT:", "SUCCESS" if MARK in um.read_text(encoding="utf-8") else "FAIL")
PY
echo "=== PROOF ==="; grep -n "DUAL-OUTPUT DECKS" ~/.hermes/memories/USER.md
echo "=== chromium ada? ==="; command -v chromium >/dev/null 2>&1 && echo "chromium OK" || (command -v soffice >/dev/null 2>&1 && echo "soffice OK (fallback)" || echo "WARN: no HTML->PDF tool")
