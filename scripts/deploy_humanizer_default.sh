#!/usr/bin/env bash
# Perluas cakupan humanizer: dari "cuma sosmed" -> DEFAULT untuk SEMUA artefak (PPT/Word/PDF/laporan/dll).
# Mekanisme: append 1 direktif always-on ke ~/.hermes/memories/USER.md (idempotent + backup).
# TIDAK restart (USER.md di-inject ke system prompt tiap turn; aktif di session baru). Aturan sosmed lama TIDAK diubah.
set -uo pipefail
"${HERMES_PY:-python3}" - <<'PY'
import pathlib, shutil, time
um = pathlib.Path.home()/".hermes/memories/USER.md"
ts = time.strftime("%Y%m%d_%H%M%S")
MARK = "humanizer skill by DEFAULT to the prose of ANY generated artifact"
d = ("Apply the 'humanizer' skill by DEFAULT to the prose of ANY generated artifact before finalizing, "
     "not only social posts: PPT/slides, Word/DOCX, PDF, reports, and any document deliverable. Run it as the "
     "FINAL style pass regardless of which production skill created the artifact (academic-document-factory, "
     "powerpoint, office-document-ops, render_deck, claude-design, popular-web-designs, etc.). Humanizer = no "
     "em-dash, no curly/smart quotes, no emoji unless explicitly requested, natural human tone, avoid stiff AI "
     "phrasing. Keep the existing social-post flow (humanizer then arif-voice-finalizer) unchanged.")
if not um.exists():
    print("RESULT: FAIL (USER.md not found)"); raise SystemExit
t = um.read_text(encoding="utf-8")
if MARK in t:
    print("RESULT: SKIP (direktif sudah ada)")
else:
    shutil.copy(um, str(um)+".bak."+ts); 
    um.write_text(t.rstrip()+"\n"+d+"\n", encoding="utf-8")
    print("BACKUP:", str(um)+".bak."+ts)
    print("RESULT:", "SUCCESS" if MARK in um.read_text(encoding="utf-8") else "FAIL")
PY
echo "=== PROOF ==="
grep -ni "humanizer" ~/.hermes/memories/USER.md
