"""
render_deck.py -- renderer PRESENTASI 16:9 ber-DESIGN-SYSTEM (bukan default-blank python-pptx).
Tujuan: hilangin look "standar" (hitam-putih, font default, gap mati) -> deck rapi & berwarna.

Filosofi: spec JSON -> render deterministik -> artifact_facts (anti-halu, buat validasi guard).
Dep: pip install python-pptx

Layout didukung: cover | section | bullets | two_col | closing
Theme (bisa di-override via spec["theme"]): warna + font.
"""
from __future__ import annotations
import os

from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.enum.shapes import MSO_SHAPE
from pptx.oxml.ns import qn

# ---------- DESIGN TOKENS (light professional) ----------
THEME = {
    "bg":       "FFFFFF",
    "ink":      "1F2933",   # teks utama (slate gelap, bukan hitam pekat)
    "muted":    "64748B",   # subjudul/footer
    "accent":   "2563EB",   # biru aksen
    "accent_2": "1E40AF",   # biru gelap (band)
    "soft":     "EEF2FF",   # fill lembut (marker/box)
    "band_tx":  "FFFFFF",
    "head_font": "Calibri",
    "body_font": "Calibri",
}

EMU_IN = 914400


def _rgb(h: str) -> RGBColor:
    return RGBColor.from_string(h.lstrip("#").upper())


def _rect(slide, l, t, w, h, color, line=False):
    sp = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, l, t, w, h)
    sp.fill.solid(); sp.fill.fore_color.rgb = _rgb(color)
    if not line:
        sp.line.fill.background()
    sp.shadow.inherit = False
    return sp


def _tb(slide, l, t, w, h, anchor=MSO_ANCHOR.TOP):
    tb = slide.shapes.add_textbox(l, t, w, h)
    tf = tb.text_frame
    tf.word_wrap = True
    tf.vertical_anchor = anchor
    return tf


def _run(p, text, size, color, font, bold=False, italic=False):
    r = p.add_run(); r.text = text
    r.font.size = Pt(size); r.font.bold = bold; r.font.italic = italic
    r.font.name = font; r.font.color.rgb = _rgb(color)
    return r


def render_deck(spec: dict, out_path: str) -> dict:
    th = {**THEME, **(spec.get("theme") or {})}
    ink, muted, accent, accent2, soft, band_tx = (
        th["ink"], th["muted"], th["accent"], th["accent_2"], th["soft"], th["band_tx"])
    HF, BF = th["head_font"], th["body_font"]
    footer = spec.get("footer", "")

    prs = Presentation()
    prs.slide_width = Inches(13.333)
    prs.slide_height = Inches(7.5)
    W, H = prs.slide_width, prs.slide_height
    blank = prs.slide_layouts[6]
    ML = Inches(0.9)            # margin kiri
    CW = W - 2 * ML            # lebar konten

    def bg(slide, color):
        slide.background.fill.solid()
        slide.background.fill.fore_color.rgb = _rgb(color)

    def footer_bar(slide, idx):
        # garis tipis + judul kiri + nomor kanan
        _rect(slide, ML, H - Inches(0.62), CW, Emu(9525), soft)  # rule tipis (~0.75pt)
        tf = _tb(slide, ML, H - Inches(0.55), CW * 0.7, Inches(0.4))
        _run(tf.paragraphs[0], footer, 10, muted, BF)
        tf2 = _tb(slide, W - ML - Inches(1.2), H - Inches(0.55), Inches(1.2), Inches(0.4))
        tf2.paragraphs[0].alignment = PP_ALIGN.RIGHT
        _run(tf2.paragraphs[0], str(idx), 10, muted, BF)

    def head(slide, title):
        _rect(slide, 0, 0, W, Inches(0.22), accent)          # accent bar atas (full width)
        tf = _tb(slide, ML, Inches(0.55), CW, Inches(1.0))
        _run(tf.paragraphs[0], title, 30, accent2, HF, bold=True)
        _rect(slide, ML, Inches(1.55), Inches(1.6), Emu(28575), accent)  # rule pendek bawah judul

    slides = spec.get("slides", [])
    image_paths = []
    page = 0

    for s in slides:
        layout = s.get("layout", "bullets")
        slide = prs.slides.add_slide(blank)
        bg(slide, th["bg"])

        if layout == "cover":
            _rect(slide, 0, 0, Inches(0.35), H, accent)               # bar vertikal kiri
            tf = _tb(slide, ML, Inches(2.3), CW, Inches(2.2), MSO_ANCHOR.TOP)
            _run(tf.paragraphs[0], s.get("title", ""), 44, ink, HF, bold=True)
            _rect(slide, ML, Inches(3.85), Inches(2.2), Emu(38100), accent)  # underline aksen
            if s.get("subtitle"):
                st = _tb(slide, ML, Inches(4.1), CW, Inches(1.0))
                _run(st.paragraphs[0], s["subtitle"], 22, muted, BF)
            if s.get("eyebrow"):
                ey = _tb(slide, ML, Inches(1.7), CW, Inches(0.5))
                _run(ey.paragraphs[0], s["eyebrow"].upper(), 13, accent, BF, bold=True)

        elif layout == "section":
            _rect(slide, 0, 0, W, H, accent2)                         # full band
            tf = _tb(slide, ML, Inches(3.0), CW, Inches(1.6), MSO_ANCHOR.MIDDLE)
            _run(tf.paragraphs[0], s.get("title", ""), 38, band_tx, HF, bold=True)
            if s.get("subtitle"):
                p = tf.add_paragraph(); _run(p, s["subtitle"], 18, soft, BF)

        elif layout == "bullets":
            head(slide, s.get("title", ""))
            body = _tb(slide, ML, Inches(2.0), CW, H - Inches(2.8))
            for j, b in enumerate(s.get("bullets", [])):
                p = body.paragraphs[0] if j == 0 else body.add_paragraph()
                _run(p, "\u25aa  ", 16, accent, BF, bold=True)        # marker kotak aksen
                # dukung "Lead: detail" -> lead di-bold
                if isinstance(b, str) and ": " in b and len(b.split(": ", 1)[0]) <= 28:
                    lead, rest = b.split(": ", 1)
                    _run(p, lead + ": ", 18, ink, BF, bold=True)
                    _run(p, rest, 18, ink, BF)
                else:
                    _run(p, str(b), 18, ink, BF)
                p.space_after = Pt(12); p.line_spacing = 1.1
            page += 1; footer_bar(slide, page)

        elif layout == "two_col":
            head(slide, s.get("title", ""))
            colw = (CW - Inches(0.6)) / 2
            for ci, key in enumerate(("left", "right")):
                col = s.get(key) or {}
                cl = ML + ci * (colw + Inches(0.6))
                if col.get("heading"):
                    ht = _tb(slide, cl, Inches(2.0), colw, Inches(0.6))
                    _run(ht.paragraphs[0], col["heading"], 20, accent2, HF, bold=True)
                cb = _tb(slide, cl, Inches(2.7), colw, H - Inches(3.5))
                for j, b in enumerate(col.get("bullets", [])):
                    p = cb.paragraphs[0] if j == 0 else cb.add_paragraph()
                    _run(p, "\u25aa  ", 14, accent, BF, bold=True)
                    _run(p, str(b), 16, ink, BF)
                    p.space_after = Pt(10); p.line_spacing = 1.1
            page += 1; footer_bar(slide, page)

        elif layout == "closing":
            _rect(slide, 0, 0, W, H, accent2)
            tf = _tb(slide, ML, Inches(2.8), CW, Inches(1.8), MSO_ANCHOR.MIDDLE)
            _run(tf.paragraphs[0], s.get("title", "Terima kasih"), 40, band_tx, HF, bold=True)
            if s.get("subtitle"):
                p = tf.add_paragraph(); _run(p, s["subtitle"], 18, soft, BF)

        elif layout == "image":
            head(slide, s.get("title", ""))
            ip = s.get("image_path", "")
            if not ip or not os.path.exists(ip):
                raise FileNotFoundError(f"image_path tidak ada (anti-halu): {ip!r}")
            image_paths.append(ip)
            slide.shapes.add_picture(ip, ML, Inches(2.0), width=CW)
            page += 1; footer_bar(slide, page)

        else:
            raise ValueError(f"layout tidak dikenal: {layout}")

    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    prs.save(out_path)

    def _texts(sp):
        out = []
        for sl in sp.slides:
            for sh in sl.shapes:
                if sh.has_text_frame:
                    out.append(sh.text_frame.text)
        return " ".join(out)

    return {
        "artifact": out_path,
        "slide_count": len(slides),
        "image_paths": image_paths,
        "ratio": "16:9",
        "theme_accent": "#" + accent,
        "word_count": len(_texts(prs).split()),
        "file_size": os.path.getsize(out_path),
    }


if __name__ == "__main__":
    import json, sys
    spec = json.load(open(sys.argv[1])) if len(sys.argv) > 1 else None
    out = sys.argv[2] if len(sys.argv) > 2 else "/tmp/deck.pptx"
    if spec is None:
        print("usage: render_deck.py spec.json out.pptx"); sys.exit(1)
    print(json.dumps(render_deck(spec, out), ensure_ascii=False, indent=2))
