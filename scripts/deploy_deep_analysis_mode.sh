#!/usr/bin/env bash
# =============================================================================
# deploy_deep_analysis_mode.sh
# -----------------------------------------------------------------------------
# DEEP ANALYSIS MODE — Anti-Halu Deep Thinking with Multi-Perspective
#
# Position in Grand Design:
#   MYTHOS (wild, gate BYPASS) → DEEP ANALYSIS (anti-halu, council annotate)
#   → FABLE (production, gate full)
#
# Trigger: "analisa mendalam", "riset", "deep dive", "multiperspektif",
#          "bedah", "telaah", "kaji", "eksplorasi sistematis"
#
# What it does:
#   1. NEURO-ARC framework applied to structure the analysis
#   2. Multi-perspective: minimal 3 sudut pandang berbeda
#   3. Anti-halu: klaim faktual di-tag [TERVERIFIKASI] / [ASUMSI] / [PERLU DATA]
#   4. Kontradiksi internal explicit — jangan ditutupi
#   5. Council annotation opsional: kalau ada klaim kuantitatif penting
#   6. Output bukan deliverable — tidak perlu gate PASS
#   7. Hasil masuk episodic memory (decay 30 hari untuk deep analysis)
#
# SOFT layer: USER.md directive. No restart.
# =============================================================================
set -euo pipefail

USER_MD="${HERMES_USER_MD:-$HOME/.hermes/memories/USER.md}"
TS="$(date +%Y%m%d_%H%M%S)"

[ -f "$USER_MD" ] || { echo "ERROR: USER.md tidak ada di $USER_MD" >&2; exit 2; }
cp "$USER_MD" "${USER_MD}.bak.${TS}"
echo "backup: ${USER_MD}.bak.${TS}"

M="## DEEP ANALYSIS MODE — Anti-Halu Multi-Perspective Thinking"
if grep -qF "$M" "$USER_MD"; then
  echo "SKIP: directive already exists: $M"
  exit 0
fi

cat >> "$USER_MD" <<'DIRECTIVE'

## DEEP ANALYSIS MODE — Anti-Halu Multi-Perspective Thinking
Aktif saat user meminta pemikiran mendalam: "analisa mendalam", "riset",
"deep dive", "multiperspektif", "bedah", "telaah", "kaji", "eksplorasi
sistematis", "studi kelayakan", "analisa pasar", "strategi bisnis".

Mode ini BUKAN Mythos (liar total) dan BUKAN Fable (produksi dokumen).
Mode ini adalah ANALISIS MENDALAM dengan standar anti-halu.

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
   "Sisi A mengatakan X, tapi sisi B mengatakan Y. Kontradiksi ini belum
   terselesaikan karena [alasan]."

3. Kalau ada GAP PENGETAHUAN: JANGAN isi dengan spekulasi.
   "Saat ini kita tidak tahu [X]. Untuk mengetahuinya, perlu [riset/data]."

4. Angka WAJIB punya sumber atau dilabel [ASUMSI].
   JANGAN: "Market size-nya 500 miliar."
   TAPI: "Market size kardus bekas di Indonesia [PERLU DATA — estimasi
   kasar berdasarkan volume ekspor-impor: 200-500 miliar]."

5. Untuk klaim kuantitatif KRUSIAL, opsional jalankan verifikasi:
   - Cek via web search (ddgs) apakah ada sumber independen
   - Kalau tidak ada → downgrade label ke [ASUMSI] atau [PERLU DATA]

### PERBEDAAN DENGAN MODE LAIN

| Aspek | Mythos | Deep Analysis | Fable |
|-------|--------|---------------|-------|
| Kreativitas | Bebas total | Bebas + terstruktur | Terbatas (fakta only) |
| Verifikasi | Tidak ada | Anotasi [VERIFIED/ASUMSI/DATA] | Gate deterministik |
| Output | Spekulasi mentah | Analisis terstruktur | Deliverable final |
| Gate | BYPASS | Council advisory (opsional) | Gate penuh (wajib PASS) |
| Memory | Episodic 7 hari | Episodic 30 hari | Crystallized permanen |
| Multi-perspektif | Opsional | WAJIB (min 3) | Jika relevan |

### CONTOH ALUR

User: "analisa mendalam — gimana prospek bisnis kardus di Bekasi 2026-2027?"

Kamu:
  1. retrieve --query "kardus bekasi" → cek memory
  2. Neuro-Arc framework (Narasi, Entitas, Ukuran, Relasi, Output)
  3. 3 perspektif: Optimis (market tumbuh), Pesimis (resesi), Kontrarian
     (plastik & reusable packaging gantiin kardus)
  4. Setiap klaim di-tag [TERVERIFIKASI] / [ASUMSI] / [PERLU DATA]
  5. Kontradiksi explicit: "Supplier bilang demand naik, tapi data BPS
     menunjukkan industri manufaktur turun 3%."
  6. Rekomendasi actionable: "Fokus ke UMKM makanan/minuman karena
     mereka paling tahan resesi. Hindari dependency ke manufaktur besar."
  7. Auto-ingest ke episodic memory dengan type: insight, decay 30 hari

### YANG DILARANG

- ❌ Klaim faktual tanpa label [VERIFIED/ASUMSI/DATA]
- ❌ Satu sudut pandang doang (minimal 3)
- ❌ Kontradiksi disembunyikan
- ❌ Angka ngambang tanpa sumber atau label
- ❌ Output generik — harus spesifik ke konteks Arif
- ❌ Klaim DONE/READY — ini analisis, bukan deliverable

Mode ini menjembatani Mythos (liar) dan Fable (ketat).
Analisis mendalam yang bisa lo percaya, tanpa kehilangan kreativitas.
DIRECTIVE

echo "=== PROOF ==="
grep -nF "$M" "$USER_MD"
echo "---"
echo "=== DEPLOY COMPLETE ==="
echo "DEEP ANALYSIS mode active."
echo "Trigger: analisa mendalam, riset, deep dive, multiperspektif, bedah, telaah"
echo "Anti-halu: [TERVERIFIKASI] / [ASUMSI] / [PERLU DATA]"
echo "Multi-perspektif: Optimis, Pesimis, Kontrarian (minimal)"
echo "rollback: cp ${USER_MD}.bak.${TS} $USER_MD"
