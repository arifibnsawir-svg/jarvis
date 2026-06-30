#!/usr/bin/env bash
# FIX jalur pembuatan dokumen (2 sekaligus), SELF-GROUNDING + idempotent + backup, NO restart:
#   FIX #1: directive ARTIFACT ROUTING di USER.md nunjuk skill yang BENERAN ada (anti "skill hantu").
#           Rename HANYA kalau target HANTU & pengganti TERBUKTI ADA (deteksi via find di Acer).
#   FIX #2: tegakkan humanizer di alur dokumen -> inject "Humanizer Gate" ke pptx-slides-creation-guard.
# Aktif di /new (lewat skill + USER.md injection), tidak perlu restart gateway.
set -uo pipefail
SK="$HOME/.hermes/skills"
UM="$HOME/.hermes/memories/USER.md"
GUARD="$SK/pptx-slides-creation-guard/SKILL.md"
ts="$(date +%Y%m%d_%H%M%S)"

echo "=== [A] INVENTORY skill yang dirujuk directive (sumber kebenaran = Acer) ==="
echo "Total SKILL.md terpasang: $(find "$SK" -name SKILL.md 2>/dev/null | wc -l)"
exists() { find "$SK" -maxdepth 4 -type d -iname "$1" 2>/dev/null | head -1; }
for s in academic-document-factory office-document-ops claude-design popular-web-designs baoyu-infographic powerpoint office-academic-skill; do
  h="$(exists "$s")"; if [ -n "$h" ]; then echo "ADA   [$s] -> $h"; else echo "HANTU [$s]"; fi
done

echo "=== [B] FIX #1: directive ARTIFACT ROUTING -> skill nyata (conditional, anti-salah-patch) ==="
if [ ! -f "$UM" ]; then echo "RESULT_FIX1: FAIL (USER.md tidak ada)"; else
"${HERMES_PY:-python3}" - "$UM" "$SK" "$ts" <<'PY'
import sys, os, subprocess, shutil, pathlib
um = pathlib.Path(sys.argv[1]); sk = sys.argv[2]; ts = sys.argv[3]
def exists(name):
    r = subprocess.run(["find", sk, "-maxdepth","4","-type","d","-iname",name],
                       capture_output=True, text=True)
    return bool(r.stdout.strip())
t = um.read_text(encoding="utf-8"); orig = t
plan = []
# rename HANYA kalau target HANTU dan pengganti yang dipilih TERBUKTI ada
if not exists("academic-document-factory") and exists("office-academic-skill"):
    plan.append(("academic-document-factory", "office-academic-skill"))
if not exists("office-document-ops") and exists("document-preservation-guard"):
    plan.append(("office-document-ops", "document-preservation-guard"))
applied = []
for a, b in plan:
    if a in t:
        t = t.replace(a, b); applied.append(f"{a} -> {b}")
if t != orig:
    shutil.copy(um, f"{um}.bak.{ts}")
    um.write_text(t, encoding="utf-8")
    print("RESULT_FIX1: SUCCESS | RENAMED:", applied, "| BACKUP:", f"{um}.bak.{ts}")
else:
    print("RESULT_FIX1: NO-CHANGE (rujukan udah valid / pengganti tak tersedia / skill ternyata nested)")
# info jalur wow-HTML
if not exists("claude-design"):
    print("WARN_WOW_HTML: claude-design HANTU -> jalur POLISHED HTML kemungkinan freehand "
          "(ini akar HTML corrupt di tes). Butuh keputusan terpisah (skill HTML-design nyata), JANGAN di-auto-fix di sini.")
else:
    print("INFO: claude-design ADA (jalur wow-HTML punya skill).")
PY
fi

echo "=== [C] FIX #2: Humanizer Gate ke pptx-slides-creation-guard (idempotent append) ==="
if [ ! -f "$GUARD" ]; then echo "RESULT_FIX2: FAIL (SKILL.md guard tidak ada)"; else
MARK="Humanizer Gate (WAJIB"
if grep -q "$MARK" "$GUARD"; then
  echo "RESULT_FIX2: SKIP (Humanizer Gate sudah ada)"
else
  cp "$GUARD" "$GUARD.bak.$ts"
  cat >> "$GUARD" <<'MD'

## Humanizer Gate (WAJIB, V2.1)
Sebelum klaim PPT/deck/dokumen "validated" atau "siap", WAJIB jalanin skill humanizer sebagai FINAL
style pass ke SELURUH prosa (judul, bullet, body, caption) -- terlepas renderer mana yang dipakai
(render_deck, claude-design, office-academic-skill). Menegakkan USER.md humanizer-default yang
terbukti SERING ke-skip di alur dokumen (cuma reliable nyala di sosmed). Untuk DUAL-OUTPUT: terapkan
humanizer ke SUMBER konten (HTML + spec.json) SEBELUM render, biar PDF dan PPTX dua-duanya bersih.
Kalau humanizer belum dijalankan -> status DILARANG naik ke PPT_VALIDATED_BASIC.
MD
  echo "RESULT_FIX2: SUCCESS | BACKUP: $GUARD.bak.$ts"
fi
fi

echo "=== PROOF ==="
echo "-- skill rujukan akademik di USER.md (harus office-academic-skill, BUKAN academic-document-factory) --"
grep -niE "academic-document-factory|office-academic-skill|office-document-ops|document-preservation-guard" "$UM" | head
echo "-- Humanizer Gate di guard --"
grep -n "Humanizer Gate" "$GUARD" | head
echo "=== SELESAI (no restart; aktif di sesi /new berikutnya) ==="
