#!/usr/bin/env bash
# Deploy upgrade DESAIN pptx: renderer house design-system + skill V2 (wajib render lewat renderer).
# Idempotent. Smoke-test render. TIDAK restart gateway (skill aktif di session baru; renderer dipakai on-call).
set -uo pipefail

SRC_R=~/jarvis/renderer/render_deck.py
DST_R=~/.hermes/scripts/render_deck.py
SRC_S=~/jarvis/skills/pptx-slides-creation-guard/SKILL.md
DST_S=~/.hermes/skills/pptx-slides-creation-guard/SKILL.md

# python yg punya python-pptx (Jarvis pakai venv hermes-agent)
PYBIN=~/.hermes/hermes-agent/venv/bin/python
[ -x "$PYBIN" ] || PYBIN=python3
echo "PYBIN=$PYBIN"

echo "=== [1] deploy renderer ==="
mkdir -p "$(dirname "$DST_R")"
cp -f "$SRC_R" "$DST_R"
ls -la "$DST_R"

echo; echo "=== [2] backup + update skill pptx-slides-creation-guard (V2) ==="
mkdir -p "$(dirname "$DST_S")"
[ -f "$DST_S" ] && cp -f "$DST_S" "$DST_S.bak.$(date +%Y%m%d_%H%M%S)" && echo "skill lama di-backup"
cp -f "$SRC_S" "$DST_S"
wc -c "$DST_S"
grep -c "Visual Design Standard" "$DST_S"

echo; echo "=== [3] python-pptx tersedia? ==="
"$PYBIN" -c "import pptx; print('python-pptx', pptx.__version__)" || { echo "INSTALL python-pptx..."; "$PYBIN" -m pip install -q python-pptx; }

echo; echo "=== [4] smoke-test render (bukti renderer jalan + ada desain) ==="
SPEC=/tmp/_deck_smoke.json
cat > "$SPEC" <<'JSON'
{"footer":"Smoke Test","slides":[
 {"layout":"cover","eyebrow":"Demo","title":"Smoke Test Deck","subtitle":"render_deck.py"},
 {"layout":"bullets","title":"Cek","bullets":["Warna: aksen aktif","Layout: 16:9","Footer: nomor halaman"]},
 {"layout":"closing","title":"Selesai","subtitle":"ok"}]}
JSON
"$PYBIN" "$DST_R" "$SPEC" /tmp/_deck_smoke.pptx
"$PYBIN" - <<'PY'
from pptx import Presentation
from pptx.util import Emu
p=Presentation("/tmp/_deck_smoke.pptx")
shapes=sum(1 for s in p.slides for sh in s.shapes if sh.shape_type==1)
print("DIMS:",round(Emu(p.slide_width).inches,2),"x",round(Emu(p.slide_height).inches,2),"| accent_shapes:",shapes,"| slides:",len(p.slides._sldIdLst))
print("RESULT:", "PASS" if shapes>0 and round(Emu(p.slide_width).inches,2)==13.33 else "FAIL")
PY

echo; echo "=== [5] CATATAN ==="
echo "- Skill V2 aktif di SESSION BARU (kirim /new). Renderer dipakai on-call (gak perlu restart)."
echo "- Re-render deck tidur: tulis spec JSON lalu: $PYBIN $DST_R spec.json out.pptx"
echo "- ROLLBACK skill: cp $DST_S.bak.<ts> $DST_S ; rm -f $DST_R"
