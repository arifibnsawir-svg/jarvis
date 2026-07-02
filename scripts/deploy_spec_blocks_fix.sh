#!/usr/bin/env bash
# =============================================================================
# deploy_spec_blocks_fix.sh
# -----------------------------------------------------------------------------
# Fixes the ROOT CAUSE of Jarvis 20-iteration debug hell:
# Jarvis writes SPEC with "content": "string" → factory can't read → blank
# page → gate FAIL → 20 iterations of regex debugging.
#
# Solution:
#   1. spec_content_to_blocks.py in factory skill (Joki-tugas-)
#   2. Hard directive in USER.md: NEVER use "content": "string"
#   3. Fallback: auto-convert via script if Jarvis forgets
#
# SOFT layer. No restart needed.
# =============================================================================
set -euo pipefail

USER_MD="${HERMES_USER_MD:-$HOME/.hermes/memories/USER.md}"
SCRIPTS_DIR="$HOME/.hermes/scripts"
TS="$(date +%Y%m%d_%H%M%S)"

[ -f "$USER_MD" ] || { echo "ERROR: USER.md tidak ada di $USER_MD" >&2; exit 2; }
cp "$USER_MD" "${USER_MD}.bak.${TS}"
echo "backup: ${USER_MD}.bak.${TS}"

echo "=== [1] Deploy factory update (spec_content_to_blocks.py) ==="
cd ~/Joki-tugas- && git checkout main && git pull && bash jarvis_document_factory/deploy_document_factory.sh 2>&1 | tail -10

echo "=== [2] Verify converter installed ==="
ls -la ~/.hermes/skills/productivity/jarvis-document-factory/spec_content_to_blocks.py 2>/dev/null || \
  echo "WARNING: converter not found via deploy_document_factory.sh — may need manual copy"

echo "=== [3] Wire directive to USER.md ==="
M="## SPEC BLOCKS FORMAT — MANDATORY (NO 'content' STRING)"
if grep -qF "$M" "$USER_MD"; then
  echo "SKIP: directive already exists: $M"
else
  cat >> "$USER_MD" <<'DIRECTIVE'

## SPEC BLOCKS FORMAT — MANDATORY (NO 'content' STRING)
Ini adalah ATURAN PALING PENTING untuk document factory. Jarvis telah terbukti
berulang kali (3+ kali dalam sesi terakhir) menulis SPEC dengan format SALAH.

### FORMAT BENAR (WAJIB)
SETIAP section HARUS punya `"blocks": [...]` — BUKAN `"content": "string"`.
Factory TIDAK BISA membaca `"content"`. Kalau kamu tulis `"content"`,
renderer akan menghasilkan halaman kosong → gate FAIL → iterasi debug
sia-sia.

```json
{
  "sections": [
    {
      "id": "bab1",
      "title": "Pendahuluan",
      "blocks": [
        {"type": "paragraph", "text": "Isi paragraf pertama..."},
        {"type": "heading", "level": 2, "id": "h-1", "text": "Sub-bab"},
        {"type": "list", "ordered": true, "items": ["Item 1", "Item 2"]},
        {"type": "callout", "text": "Catatan penting"},
        {"type": "table", "caption": "Judul", "header": ["Kolom1"], "rows": [["Data"]]}
      ]
    }
  ]
}
```

### FORMAT SALAH (DILARANG KERAS)
```json
{
  "sections": [
    {
      "id": "bab1",
      "title": "Pendahuluan",
      "content": "Isi paragraf panjang yang tidak akan dibaca factory..."
    }
  ]
}
```

### CONVERTER (JALUR DARURAT)
Kalau kamu terlanjur menulis `"content"`, jalankan converter:

  /home/arif/.hermes/hermes-agent/venv/bin/python \
    ~/.hermes/skills/productivity/jarvis-document-factory/spec_content_to_blocks.py \
    SPEC.json --fix

Ini menghasilkan SPEC.json.fixed dengan format `blocks` yang benar.

### TEMPLATE
Gunakan `examples/makalah_4bab_spec.json` sebagai acuan struktur.
JANGAN menebak format SPEC. Lihat contoh dulu.

Aturan ini berlaku untuk SEMUA jenis dokumen — akademik, bisnis, proposal.
Pelanggaran = 20 iterasi debug sia-sia yang bisa dihindari.
DIRECTIVE
  echo "OK: directive appended"
fi

echo "=== PROOF ==="
grep -nF "$M" "$USER_MD"
echo "---"
echo "=== DEPLOY COMPLETE ==="
echo "Converter: ~/.hermes/skills/productivity/jarvis-document-factory/spec_content_to_blocks.py"
echo "Example: examples/makalah_4bab_spec.json"
echo "Directive: $M"
echo "rollback: cp ${USER_MD}.bak.${TS} $USER_MD"
