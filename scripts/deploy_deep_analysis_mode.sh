#!/usr/bin/env bash
# =============================================================================
# deploy_deep_analysis_mode.sh
# -----------------------------------------------------------------------------
# DEEP ANALYSIS MODE — Anti-Halu Multi-Perspective with jarvis-reason + PIPA4
#
# COGNITIVE STACK:
#   Combo: jarvis-reason (Opus 4.8 → GPT 5.5 → Mistral Large 3 → Qwen 3.5)
#   Framework: NEURO-ARC + multi-perspective
#   Quality: PIPA4 council annotation (advisory, NOT blocking)
#   Labels: [TERVERIFIKASI] / [ASUMSI] / [PERLU DATA]
#
# POSITION in Grand Design:
#   MYTHOS (wild, jarvis-agent, gate BYPASS)
#     → DEEP ANALYSIS (jarvis-reason, council annotate, anti-halu)
#     → FABLE (jarvis-agent/run.py, gate full, council PASS/FAIL)
#
# SOFT layer: USER.md directive. No restart.
# =============================================================================
set -euo pipefail

USER_MD="${HERMES_USER_MD:-$HOME/.hermes/memories/USER.md}"
TS="$(date +%Y%m%d_%H%M%S)"

[ -f "$USER_MD" ] || { echo "ERROR: USER.md tidak ada di $USER_MD" >&2; exit 2; }
cp "$USER_MD" "${USER_MD}.bak.${TS}"
echo "backup: ${USER_MD}.bak.${TS}"

M="## DEEP ANALYSIS MODE — Anti-Halu Multi-Perspective with jarvis-reason + PIPA4"
if grep -qF "## DEEP ANALYSIS MODE" "$USER_MD"; then
  echo "=== Updating existing DEEP ANALYSIS directive to add jarvis-reason + PIPA4 enforcement ==="
  # Add jarvis-reason + PIPA4 lines to existing directive
  sed -i '/^## DEEP ANALYSIS MODE/,/^## /{
    /^## DEEP ANALYSIS MODE/ a\
\
### COGNITIVE STACK (MANDATORY)\
\
Mode ini menggunakan COMBO TERBAIK: **jarvis-reason** (Opus 4.8 → GPT 5.5 → Mistral Large 3 → Qwen 3.5).\
Ini bukan chatting biasa. Ini PENGAMBILAN KEPUTUSAN. Setiap analisis harus TAJAM, AKURAT, dan ANTI-HALU.\
\
PIPA4 Council TETAP BERJALAN sebagai lapis verifikasi — bukan untuk memblokir, tapi untuk MENGANOTASI:\
  - Setiap klaim kuantitatif diperiksa konsistensinya\
  - Kontradiksi internal di-flag\
  - Asumsi yang tidak dilabel akan DIDETEKSI\
  - false_READY_count HARUS 0\
\
Council = ADVISORY di mode ini. Dia tidak memblokir output. Dia memastikan output LAYAK DIPERCAYA.\
Karena ini urusan PEMIKIRAN dan PENGAMBILAN KEPUTUSAN — bukan sekadar brainstorming liar.
  }' "$USER_MD"
  echo "OK: jarvis-reason + PIPA4 enforcement added to existing DEEP ANALYSIS directive."
else
  cat >> "$USER_MD" <<'DIRECTIVE'

## DEEP ANALYSIS MODE — Anti-Halu Multi-Perspective with jarvis-reason + PIPA4
Aktif saat user meminta pemikiran mendalam: "analisa mendalam", "riset",
"deep dive", "multiperspektif", "bedah", "telaah", "kaji", "eksplorasi
sistematis", "studi kelayakan", "analisa pasar", "strategi bisnis".

Mode ini BUKAN Mythos (liar total) dan BUKAN Fable (produksi dokumen).
Mode ini adalah ANALISIS MENDALAM untuk PENGAMBILAN KEPUTUSAN.

### COGNITIVE STACK (MANDATORY)

Mode ini menggunakan COMBO TERBAIK: **jarvis-reason**
(Opus 4.8 → GPT 5.5 → Mistral Large 3 → Qwen 3.5 → MiMo 2.5 Pro →
Kimi K2.6 → GPT-4o → Sonnet 4.5).
Ini bukan chatting biasa. Ini PENGAMBILAN KEPUTUSAN.
Setiap analisis harus TAJAM, AKURAT, dan ANTI-HALU.

PIPA4 Council TETAP BERJALAN sebagai lapis verifikasi advisory:
  - Setiap klaim kuantitatif diperiksa konsistensinya
  - Kontradiksi internal di-flag
  - Asumsi yang tidak dilabel akan DIDETEKSI
  - false_READY_count HARUS 0

Council = ADVISORY di mode ini. Dia tidak memblokir output.
Dia memastikan output LAYAK DIPERCAYA.
Karena ini urusan PEMIKIRAN dan PENGAMBILAN KEPUTUSAN —
bukan sekadar brainstorming liar.

### KERANGKA WAJIB: NEURO-ARC

Setiap output Deep Analysis HARUS menggunakan struktur:

  NARASI — Konteks mentah. Apa yang kita tahu? Apa yang kita tidak tahu?
    Jujur tentang gap pengetahuan.

  ENTITAS — Semua aktor, kekuatan, ide yang terlibat.
    Siapa stakeholder? Siapa yang diuntungkan/dirugikan?

  UKURAN — Semua angka dan data. TAPI:
    [TERVERIFIKASI] = ada sumber + dicek
    [ASUMSI] = estimasi logis tapi belum dicek
    [PERLU DATA] = butuh riset lebih lanjut

  RELASI — Koneksi kausal, feedback loop, hidden dynamics.
    Minimal 3 sudut pandang berbeda (lihat ATURAN MULTI-PERSPEKTIF).

  OUTPUT — Sintesis yang TAJAM dan BISA DIPAKAI.
    Bukan ringkasan — rekomendasi yang actionable.
    Bukan template — insight yang spesifik ke konteks Arif.

### ATURAN MULTI-PERSPEKTIF (MANDATORY)

Setiap Deep Analysis WAJIB mengeksplorasi minimal 3 sudut pandang:

  1. OPTIMIS (Best Case): Kalau semua berjalan sesuai rencana
  2. PESIMIS (Worst Case): Kalau asumsi kunci gagal
  3. KONTRARIAN (Devil's Advocate): Argumen kenapa ini ide buruk

Untuk analisis yang lebih besar, tambahkan:
  4. SISTEMIK (Systems View): Dampak ke-2 dan ke-3, unintended consequences
  5. TEMPORAL (Time View): Jangka pendek (3 bln) vs menengah (1 thn) vs panjang (3+ thn)

### ATURAN ANTI-HALU

1. Setiap klaim faktual WAJIB dilabel:
   [TERVERIFIKASI] = ada sumber yang bisa dicek
   [ASUMSI] = estimasi logis berdasarkan pola/pattern
   [PERLU DATA] = butuh riset lebih lanjut, spekulatif

2. Kalau ada KONTRADIKSI internal: JANGAN tutupi. Tampilkan explicit.

3. Kalau ada GAP PENGETAHUAN: JANGAN isi dengan spekulasi.

4. Angka WAJIB punya sumber atau dilabel [ASUMSI].

5. Untuk klaim kuantitatif KRUSIAL, opsional jalankan verifikasi:
   - Cek via web search (ddgs) apakah ada sumber independen
   - Kalau tidak ada → downgrade label ke [ASUMSI] atau [PERLU DATA]

### PERBEDAAN DENGAN MODE LAIN

| Aspek | Mythos | Deep Analysis | Fable |
|-------|--------|---------------|-------|
| Combo | jarvis-agent | **jarvis-reason** | jarvis-agent (tulis) + jarvis-reason (council) |
| Kreativitas | Bebas total | Bebas + terstruktur | Terbatas (fakta only) |
| Verifikasi | Tidak ada | Council annotate + [LABEL] | Gate deterministik |
| Output | Spekulasi mentah | Analisis terstruktur | Deliverable final |
| Gate | BYPASS | Council advisory | Gate penuh (wajib PASS) |
| Memory | Episodic 7 hari | Episodic 30 hari | Crystallized permanen |
| Multi-perspektif | Opsional | WAJIB (min 3) | Jika relevan |

### YANG DILARANG

- ❌ Klaim faktual tanpa label [VERIFIED/ASUMSI/DATA]
- ❌ Satu sudut pandang doang (minimal 3)
- ❌ Kontradiksi disembunyikan
- ❌ Angka ngambang tanpa sumber atau label
- ❌ Output generik — harus spesifik ke konteks Arif
- ❌ Klaim DONE/READY — ini analisis, bukan deliverable

Mode ini menjembatani Mythos (liar) dan Fable (ketat).
Combo terbaik + PIPA ketat = keputusan yang bisa lo percaya.
DIRECTIVE
  echo "OK: directive appended"
fi

echo "=== PROOF ==="
grep -nF "DEEP ANALYSIS MODE" "$USER_MD"
grep -nF "jarvis-reason" "$USER_MD" | grep -i "deep\|analysis" | head -3
echo "---"
echo "=== DEPLOY COMPLETE ==="
echo "DEEP ANALYSIS with jarvis-reason + PIPA4 council annotation."
echo "Combo: Opus 4.8 → GPT 5.5 → Mistral Large 3 → Qwen 3.5"
echo "Council: advisory annotation, NOT blocking"
echo "Anti-halu: [TERVERIFIKASI] / [ASUMSI] / [PERLU DATA]"
echo "Multi-perspektif: Optimis, Pesimis, Kontrarian (minimal)"
echo "rollback: cp ${USER_MD}.bak.${TS} $USER_MD"
