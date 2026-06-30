#!/usr/bin/env bash
# Deploy skill pihak-ketiga: office-academic-skill (dari zLanqing/codex-claude-academic-skills, MIT).
# Lane: joki kuliah -> output .pptx & .docx EDITABLE + anti-fabrikasi + tag sumber + template-clone + overflow scan.
# SCOPED: cuma office-academic-skill (SKIP scientific-toolkit & research-writing utk sekarang).
# ADAPT: override bahasa output -> BAHASA INDONESIA (upstream default China).
# Idempotent. TIDAK restart gateway (skill aktif di session baru /new). LICENSE dipertahankan (MIT attribution).
set -uo pipefail

PYBIN=~/.hermes/hermes-agent/venv/bin/python
[ -x "$PYBIN" ] || PYBIN=python3
echo "PYBIN=$PYBIN"

SRC=~/.hermes/skills/_src_academic
DST=~/.hermes/skills/office-academic-skill
REPO=https://github.com/zLanqing/codex-claude-academic-skills.git

echo "=== [1] ambil/upgrade source (MIT) ==="
if [ -d "$SRC/.git" ]; then (cd "$SRC" && git pull --ff-only); else git clone --depth 1 "$REPO" "$SRC"; fi
echo "commit:"; (cd "$SRC" && git log --oneline -1)

echo; echo "=== [2] copy HANYA office-academic-skill + LICENSE (atribusi MIT) ==="
rm -rf "$DST"; mkdir -p "$DST"
cp -r "$SRC/office-academic-skill/." "$DST/"
cp -f "$SRC/LICENSE" "$DST/LICENSE.upstream" 2>/dev/null || true
du -sh "$DST"; ls -1 "$DST"

echo; echo "=== [3] override bahasa -> Bahasa Indonesia (sisip blok setelah frontmatter) ==="
"$PYBIN" - <<'PY'
import pathlib
p = pathlib.Path.home()/".hermes/skills/office-academic-skill/SKILL.md"
t = p.read_text(encoding="utf-8")
MARK = "OVERRIDE DEPLOY HERMES"
if MARK in t:
    print("override sudah ada (skip)")
else:
    block = (
        "\n## " + MARK + " (Jarvis) -- BACA INI DULU, MENANG ATAS DEFAULT DI BAWAH\n"
        "- BAHASA OUTPUT DEFAULT = BAHASA INDONESIA baku. Override semua 'default to Chinese': "
        "penjelasan, prosa laporan Word, teks slide, outline, speaker notes -> Bahasa Indonesia.\n"
        "- Pertahankan apa adanya: judul/istilah Inggris, rumus, nama variabel/model, perintah software, entri referensi.\n"
        "- Font teks Latin & angka: Times New Roman / Calibri / Arial. TIDAK perlu font CJK (YaHei/SimSun) untuk output Indonesia.\n"
        "- Tetap tegakkan: anti-fabrikasi (no fake DOI/data/nilai), tag sumber, action title, 1 ide per slide, cek overflow teks, JANGAN timpa file asli (buat versi baru).\n"
        "- Jika skill humanizer Hermes aktif, patuhi juga (tanpa em-dash, tanpa kutip keriting, tanpa emoji).\n"
    )
    # sisip setelah blok frontmatter pertama (--- ... ---)
    parts = t.split("---", 2)
    if len(parts) >= 3:
        t = parts[0] + "---" + parts[1] + "---" + block + parts[2]
    else:
        t = block + t
    p.write_text(t, encoding="utf-8")
    print("override Bahasa Indonesia disisipkan")
PY
grep -n "OVERRIDE DEPLOY HERMES\|BAHASA OUTPUT DEFAULT" "$DST/SKILL.md" | head

echo; echo "=== [4] install deps di venv ==="
"$PYBIN" -m pip install -q "python-pptx>=0.6.23" "Pillow>=10.0" "PyMuPDF>=1.24" "pypdf>=4.0" && echo "deps OK"

echo; echo "=== [5] verifikasi: frontmatter parse + import tool kunci ==="
"$PYBIN" - <<'PY'
import pathlib, sys
p = pathlib.Path.home()/".hermes/skills/office-academic-skill/SKILL.md"
txt = p.read_text(encoding="utf-8")
try:
    import yaml; d = yaml.safe_load(txt.split("---")[1]); fm = d.get("name")
except Exception as e:
    fm = "yaml-missing(%s)" % e
print("frontmatter name:", fm)
sys.path.insert(0, str(pathlib.Path.home()/".hermes/skills/office-academic-skill/references/thesis-defense-pptx/scripts"))
try:
    import pptx_template_tools as tt
    have = [f for f in ("set_text_preserve_style","replace_exact_text","add_pic_fit","write_table") if hasattr(tt,f)]
    print("template_tools import OK, fungsi:", have)
except Exception as e:
    print("template_tools import FAIL:", repr(e))
PY

echo; echo "=== [6] CATATAN ==="
echo "- Skill aktif di SESSION BARU (kirim /new). Folder lengkap (references+scripts) ke-deploy."
echo "- Wiring routing (langkah terpisah): tambah di pipa-routing -> 'PPT/Word tugas/akademik editable' = pakai office-academic-skill."
echo "- ROLLBACK: rm -rf $DST"
