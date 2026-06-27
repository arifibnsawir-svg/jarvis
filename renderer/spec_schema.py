"""
Spec Schema — kontrak JSON yang HARUS dihasilkan LLM (bukan file binernya).

Prinsip "Structure Before Render":
  LLM keluarin SPEC JSON -> validate (deterministik) -> renderer Python bikin file.
  LLM TIDAK PERNAH bikin .pptx/.docx langsung (itu sumber 'ngaco').

validate_spec() = gerbang deterministik kecil sebelum render. Kalau spec invalid,
tolak SEBELUM bikin file -> error jelas, bukan file korup.
"""
from __future__ import annotations


class SpecError(ValueError):
    pass


PPTX_LAYOUTS = {"title", "bullets", "body", "quote", "image"}
DOCX_BLOCKS = {"heading", "paragraph", "bullets", "quote", "image", "pagebreak"}


def validate_spec(spec: dict) -> dict:
    if not isinstance(spec, dict):
        raise SpecError("spec harus object JSON")
    t = spec.get("type")
    if t == "pptx":
        return _validate_pptx(spec)
    if t == "docx":
        return _validate_docx(spec)
    raise SpecError(f"type tidak dikenal: {t!r} (harus 'pptx' atau 'docx')")


def _validate_pptx(spec: dict) -> dict:
    slides = spec.get("slides")
    if not isinstance(slides, list) or not slides:
        raise SpecError("pptx.slides harus list non-kosong")
    for i, s in enumerate(slides):
        layout = s.get("layout")
        if layout not in PPTX_LAYOUTS:
            raise SpecError(f"slide[{i}].layout {layout!r} invalid; pilih {PPTX_LAYOUTS}")
        if layout in ("title", "bullets", "body") and not s.get("title"):
            raise SpecError(f"slide[{i}] layout {layout} wajib punya 'title'")
        if layout == "bullets" and not isinstance(s.get("bullets"), list):
            raise SpecError(f"slide[{i}] layout bullets wajib 'bullets' (list)")
        if layout == "body" and not s.get("body"):
            raise SpecError(f"slide[{i}] layout body wajib 'body'")
        if layout == "quote" and not s.get("quote"):
            raise SpecError(f"slide[{i}] layout quote wajib 'quote'")
        if layout == "image" and not s.get("image_path"):
            raise SpecError(f"slide[{i}] layout image wajib 'image_path' (artefak NYATA)")
    return spec


def _validate_docx(spec: dict) -> dict:
    blocks = spec.get("blocks")
    if not isinstance(blocks, list) or not blocks:
        raise SpecError("docx.blocks harus list non-kosong")
    for i, b in enumerate(blocks):
        bt = b.get("type")
        if bt not in DOCX_BLOCKS:
            raise SpecError(f"block[{i}].type {bt!r} invalid; pilih {DOCX_BLOCKS}")
        if bt == "heading" and not b.get("text"):
            raise SpecError(f"block[{i}] heading wajib 'text'")
        if bt == "paragraph" and "text" not in b:
            raise SpecError(f"block[{i}] paragraph wajib 'text'")
        if bt == "bullets" and not isinstance(b.get("items"), list):
            raise SpecError(f"block[{i}] bullets wajib 'items' (list)")
        if bt == "image" and not b.get("path"):
            raise SpecError(f"block[{i}] image wajib 'path' (artefak NYATA)")
    return spec


def extract_text(spec: dict) -> str:
    """Tarik SEMUA teks dari spec -> untuk dicek GUARDIAN (brand/sacred IP)."""
    parts: list[str] = []
    if spec.get("title"):
        parts.append(str(spec["title"]))
    if spec.get("type") == "pptx":
        for s in spec.get("slides", []):
            for k in ("title", "subtitle", "body", "quote", "attribution", "caption"):
                if s.get(k):
                    parts.append(str(s[k]))
            parts += [str(x) for x in s.get("bullets", [])]
    elif spec.get("type") == "docx":
        for b in spec.get("blocks", []):
            if b.get("text"):
                parts.append(str(b["text"]))
            parts += [str(x) for x in b.get("items", [])]
            if b.get("caption"):
                parts.append(str(b["caption"]))
    return "\n\n".join(parts)
