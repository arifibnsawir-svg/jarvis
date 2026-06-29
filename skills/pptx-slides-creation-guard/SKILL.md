---
name: pptx-slides-creation-guard
description: "Safeguard + design standard untuk bikin PowerPoint: validasi layout/integritas DAN wajib render lewat house design-system renderer (bukan default-blank python-pptx)."
category: productivity
---

# PPTX / SLIDES CREATION GUARD V2

## Trigger
Active when the user requests:
- Creating a PPT / slides / deck / PowerPoint / presentation.
- Converting a document to PPT.
- Summarizing into slides.
- Academic assignments in PPT format.

## Core Rules
1. **No Overwrites:** Never overwrite original PPTX, DOCX, or PDF files.
2. **Unique Filenames:** Always create new files with unique, descriptive names.
3. **Default Output:** `/home/arif/.hermes/outbox/presentations/`
4. **Audit First:** If the source is an important document, perform a read-only audit before generation.
5. **No Blind Claims:** Never claim a PPT is final without performing at least basic validation.
6. **Concise Content:** Avoid long paragraphs in slides. Keep them ringkas (concise) and visual-friendly.
7. **Clear Structure:** Cover -> Agenda/Goals -> Main content -> Illustrations/Examples -> Conclusion -> References (if academic).
8. **Defaults:** Use 16:9 ratio and reasonable slide counts unless specified.
9. **Academic Integrity:** Do not fabricate sources. Mark missing data as [To Be Completed].

## Visual Design Standard (V2) -- WAJIB
Tujuan: hilangkan look "standar" (hitam-putih, font default, gap mati). JANGAN bangun slide dari blank
dengan textbox + warna default. SELALU lewat renderer house design-system:

1. **Pisahkan KONTEN dari RENDER.** Keluarkan dulu SPEC terstruktur (JSON), lalu render via tool.
   JANGAN nulis python-pptx ad-hoc yang naro teks hitam di slide putih polos.
2. **Renderer:** `~/.hermes/scripts/render_deck.py` (house design-system: 16:9, palet aksen,
   skala tipografi, accent bar, divider, nomor halaman). Pakai:
   `python3 ~/.hermes/scripts/render_deck.py <spec.json> <out.pptx>` (pakai python yg ada python-pptx).
3. **Spec schema (JSON):**
   ```json
   {
     "footer": "Judul ringkas deck",
     "theme": {},                       // optional: override warna/font
     "slides": [
       {"layout":"cover","eyebrow":"...","title":"...","subtitle":"..."},
       {"layout":"section","title":"...","subtitle":"..."},
       {"layout":"bullets","title":"...","bullets":["Lead: detail", "..."]},
       {"layout":"two_col","title":"...","left":{"heading":"...","bullets":["..."]},"right":{"heading":"...","bullets":["..."]}},
       {"layout":"closing","title":"Terima kasih","subtitle":"..."}
     ]
   }
   ```
4. **Layout & preset tersedia (render_deck v2):** layout = cover | section (pakai "number") | bullets | two_col | big_stat (pakai "stats":[{value,label,note}]) | quote (quote+attribution) | timeline (pakai "phases":[{when,title,desc}]) | image | closing (subtitle+contacts). Preset (spec["preset"]) = academic (default, serif scholarly) | business (modern) | dark. Engine ini "berkreasi tanpa template" - selera desain sudah di-encode (palet, tipografi, grid, footer+nomor halaman).
5. **Aturan isi slide:** maksimal ~5 bullet per slide; bullet ringkas; pakai pola "Lead: detail"
   biar kata kunci ke-bold otomatis; pakai layout `section` sebagai pembatas bab; `two_col` untuk
   perbandingan; `closing` untuk penutup. Gunakan variasi layout, jangan semua `bullets`.
5. **Gambar:** hanya via `{"layout":"image","image_path":"..."}` dengan file yang BENAR-BENAR ADA
   (renderer nolak path tak-ada = anti-halu). Jangan comot logo/gambar acak.
6. **artifact_facts:** renderer balikin slide_count/ratio/theme_accent/word_count/file_size -> pakai buat validasi.

## Validation Minimum
After creating a PPT, you **MUST** verify:
- File existence and file size (dari artifact_facts).
- Slide count + ratio 16:9.
- List of slide titles.
- Export to PDF / render PNG slide 1-2 (if tools available) untuk cek visual.
- No placeholders (TODO, lorem ipsum, [Insert here], chunk markers).
- No empty slides without justification.

## Status Labels
`PPT_DRAFT_CREATED` | `PPT_VALIDATED_BASIC` | `PPT_RENDER_CHECKED` | `PPT_NEEDS_MANUAL_REVIEW` | `PPT_FINAL_READY`

## Blocked by Default
- Overwriting original PPT files.
- Claiming final without validation.
- Filling slides with wall-of-text paragraphs.
- **Building slides from blank with default font + black-on-white (look "standar") -- WAJIB lewat render_deck.py.**
- Using random unapproved images/logos.
- Fabricating data/academic sources.
- Creating slides from long documents without an initial structure/outline.

## Allowed Safe Actions
- Creating slide outlines / deck spec JSON.
- Drafting slide content.
- Generating new PPT files via render_deck.py.
- Exporting PDF previews / rendering sample slides.
- Creating revision notes / "DRAFT_REVIEW_ONLY" version.
