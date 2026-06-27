"""Demo: Structure Before Render -> file asli -> GUARDIAN gate."""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "state"))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "guardian"))

from render_pptx import render_pptx
from render_docx import render_docx
from spec_schema import extract_text
from task_state import TaskState, OutputSpec, Constraint
from guardian import run_guardian

OUT = "/tmp/jarvis_out"

# ---------- PPTX carousel (bersih) ----------
deck = {
    "type": "pptx", "title": "Carousel",
    "slides": [
        {"layout": "title", "title": "Menang di AI bukan soal tools", "subtitle": "Catatan singkat"},
        {"layout": "bullets", "title": "Tiga salah kaprah",
         "bullets": ["Ngejar tool tercanggih", "Numpuk prompt sebanyak-banyaknya", "Lupa nyusun masalah"]},
        {"layout": "quote", "quote": "Representasi > Kecanggihan", "attribution": "Arif"},
        {"layout": "body", "title": "Intinya", "body": "Sistem bukan tools. Yang nentuin hasil itu cara berpikir."},
    ],
}
pf = render_pptx(deck, f"{OUT}/carousel.pptx")
print("PPTX facts :", pf)

st = TaskState(narasi="carousel publik IG")
st.neuro.output = OutputSpec("carousel", "pptx", "ig", target="public_social")
st.neuro.ukuran = [Constraint("V", "santai", "voice", value="casual"),
                   Constraint("C1", "tepat 4 slide", "slide_count", "==", 4)]
v = run_guardian(extract_text(deck), st, artifact_facts=pf)
print("PPTX gate  :", st.status.value, "/", v.result, "/", v.failures or "OK")

# ---------- DOCX naskah ----------
doc = {
    "type": "docx", "title": "Draf Bab 1", "meta": {"author": "Arif", "date": "2026"},
    "blocks": [
        {"type": "heading", "level": 1, "text": "Dari Operator ke Arsitek"},
        {"type": "paragraph", "text": "Sistem bukan tools. Ini soal cara berpikir."},
        {"type": "bullets", "items": ["Audit", "Rancang", "Sistemasi", "Iterasi"]},
        {"type": "quote", "text": "Bangun sistem, bukan kejar hype"},
    ],
}
df = render_docx(doc, f"{OUT}/bab1.docx")
print("DOCX facts :", df)
print("files exist:", os.path.exists(f"{OUT}/carousel.pptx"), os.path.exists(f"{OUT}/bab1.docx"))
