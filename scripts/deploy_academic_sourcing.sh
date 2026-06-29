#!/usr/bin/env bash
# Aturan SUMBER AKADEMIK (always-on, lintas-skill): kredibel+terverifikasi, Indonesia dulu, no halu.
# Idempotent + backup. No restart (aktif di /new).
set -uo pipefail
"${HERMES_PY:-python3}" - <<'PY'
import pathlib, shutil, time
um = pathlib.Path.home()/".hermes/memories/USER.md"
ts = time.strftime("%Y%m%d_%H%M%S")
MARK = "ACADEMIC SOURCING (always, default)"
d = ("ACADEMIC SOURCING (always, default): for ANY academic/tugas artifact (makalah, laporan, PPT sidang/seminar, "
     "skripsi, mini-book), finding credible and verifiable sources is MANDATORY and ON by default, regardless of which "
     "production skill renders the file (academic-document-factory, powerpoint, render_deck, office-document-ops). "
     "PRIORITIZE Indonesian sources FIRST: jurnal Indonesia via Garuda (garuda.kemdikbud.go.id), SINTA "
     "(sinta.kemdikbud.go.id), Google Scholar, repositori kampus (.ac.id), situs resmi (.go.id), penerbit/buku ID; "
     "THEN international sources (DOI, journal, publisher). NEVER fabricate DOI, author, journal, year, page, or "
     "findings. Every citation MUST be checkable (a link/DOI that resolves or a verifiable bibliographic entry); any "
     "claim without a verifiable source must be labeled 'belum ada sumber terverifikasi' or omitted (cite-or-abstain). "
     "Also: PPT sidang/seminar tetap dianggap akademik -> terapkan aturan sumber ini meskipun file dirender lewat "
     "powerpoint/render_deck.")
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
grep -n "ACADEMIC SOURCING" ~/.hermes/memories/USER.md
