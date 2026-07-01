# HANDOFF CHECKPOINT - 2026-07-01 (sesi lanjutan malam)
_Lanjutan dari HANDOFF_CHECKPOINT_2026-07-01.md bagian "3 PERBAIKAN PENDING" / RESUME OPEN ITEMS. Baca RESUME_HANDOFF.md dulu buat peta cepat._

## VERDICT
- **FAKTA TERBUKTI (di repo + VERIFIED di Acer):** 3 perbaikan pending + #1 relevance filter beres.
  - Joki-tugas-: `4fbf6c2`, `2324405`, `a6dff05`, `d366824`.
  - jarvis: checkpoint, deploy scripts, RESUME, relevance_filter, dll.
- **RISIKO:** rendah. Semua lapis SOFT, idempotent, backup+rollback.
- **NEXT:** #3 word-count COMMITTED (PENDING deploy). Sisa open = #2, #4, #5.

## Yang dikerjakan (mengalamatkan 3 PERBAIKAN PENDING checkpoint 12.30)

### 1. validate_spec.py (VERIFIED)
### 2. Direktif ANTI-FALLBACK (VERIFIED)
### 3. Contoh SPEC makalah 4 bab (VERIFIED)

## PERINTAH DEPLOY + TEST DI ACER (arsip; sudah dijalankan & PASS)
[perintah A-E sebelumnya...]

---

## LANJUTAN 2 - OPEN ITEM #1: relevance filter academic-search (VERIFIED)
### VERDICT
selftest PASS, dummy 2 relevan/1 tangensial. VERIFIED di Acer.

---

## LANJUTAN 3 - OPEN ITEM #3: word-count akurasi (COMMITTED, PENDING VERIFY)
### VERDICT
- **FAKTA TERBUKTI (di repo):** word_count ditambah ke pipeline factory.
  - Joki-tugas-: `a6dff05` (readers.py + count_words(), spec.py + word_count di RenderResult/GateVerdict, pdf+docx renderer panggil count_words) + `d366824` (gate.py word_count, orchestrator + run.py report JSON, pptx renderer, SKILL.md guidance).
  - Belum di-deploy/diverifikasi di Acer.
- **RISIKO:** rendah. count_words() = len(read_text(fmt, path).split()), stdlib murni, dibaca setelah file ditulis. Tidak mengubah gate PASS/FAIL.
- **NEXT:** deploy skill factory ke Acer (git pull + deploy script), lalu uji render contoh makalah dan cek `word_count` ada di JSON report.

### Apa yang diubah
- **readers.py**: `count_words(fmt, path)` → `len(read_text(fmt, path).split())` — hitung kata dari teks file jadi (pdf/docx/pptx).
- **spec.py**: `RenderResult.word_count` (default 0) dan `GateVerdict.word_count` (default 0).
- **pdf.py renderer**: setelah `document.write_pdf()` → panggil `count_words("pdf", out_path)`, masuk ke `RenderResult`.
- **docx.py renderer**: setelah `doc.save()` → panggil `count_words("docx", out_path)`, masuk ke `RenderResult`.
- **pptx.py renderer**: setelah `render_deck()` → panggil `count_words("pptx", out_path)`, masuk ke `RenderResult`.
- **gate.py**: `gate()` sekarang `word_count = count_words(fmt, file_path)` masuk ke `GateVerdict`.
- **run.py**: JSON report sekarang punya `"word_count"` di tiap output.
- **SKILL.md**: bagian baru "Hasil: baca dari JSON report, jangan menebak" + checklist line.

### Perintah deploy + verify (di Acer)
```
# A) deploy skill factory (no restart)
cd ~/Joki-tugas- && git checkout main && git pull
bash jarvis_document_factory/deploy_document_factory.sh

# B) uji render contoh + cek word_count
VENV=/home/arif/.hermes/hermes-agent/venv/bin/python
SKILL=~/.hermes/skills/productivity/jarvis-document-factory
HERMES_RENDER_DECK=~/.hermes/scripts/render_deck.py \
$VENV $SKILL/run.py $SKILL/examples/makalah_4bab_spec.json --out /tmp/makalah_wc --basename makalah_wc ; echo "exit=$?"

# C) cek JSON report (harus ada "word_count") 
$VENV -c "import json; r=json.load(open('/tmp/makalah_wc/makalah_wc.pdf')); print('page_count:', r['page_count'], 'word_count:', r['word_count'])" 2>/dev/null || \
$VENV -c "import json; r=json.load(sys.stdin)" < <($HERMES_RENDER_DECK=~/.hermes/scripts/render_deck.py $VENV $SKILL/run.py /tmp/makalah_wc_spec.json ...) 2>/dev/null || \
echo "cek manual: grep word_count dari output run.py"

# D) hitung manual dengan wc sebagai pembanding
pdf_text=$(python3 -c "from pypdf import PdfReader; print(' '.join(p.extract_text() or '' for p in PdfReader('/tmp/makalah_wc/makalah_wc.pdf').pages))" 2>/dev/null)
[ -n "$pdf_text" ] && echo "wc -w (pdf text): $(echo "$pdf_text" | wc -w)"
docx_text=$(python3 -c "import docx; d=docx.Document('/tmp/makalah_wc/makalah_wc.docx'); print(' '.join(p.text for p in d.paragraphs))" 2>/dev/null)
[ -n "$docx_text" ] && echo "wc -w (docx text): $(echo "$docx_text" | wc -w)"
```
Yang penting: JSON report run.py sekarang punya `"word_count"` (bukan 0 atau kosong), dan nilainya masuk akal (beberapa ribu kata buat makalah 4 bab).
