# HANDOFF CHECKPOINT - 2026-07-01 (sesi lanjutan malam)
_Lanjutan dari HANDOFF_CHECKPOINT_2026-07-01.md bagian "3 PERBAIKAN PENDING" / RESUME OPEN ITEMS. Baca RESUME_HANDOFF.md dulu buat peta cepat._

## VERDICT
- **FAKTA TERBUKTI (di repo):** 3 perbaikan pending sudah DI-COMMIT. File ada di repo, reuse logika existing, tidak menambah dependency.
  - Joki-tugas- @ main commit `4fbf6c2` (validate_spec.py, examples/makalah_4bab_spec.json, tests/test_validate_cli.py, SKILL.md, deploy_document_factory.sh).
  - jarvis @ main (checkpoint ini + scripts/deploy_anti_fallback.sh + update RESUME).
- **BELUM TERBUKTI:** belum di-deploy & dijalankan di Acer. Status = **PENDING deploy+verify**. TIDAK boleh disebut live/PROVEN sampai Arif menjalankannya di Acer (agent cloud tak di tailnet).
- **RISIKO:** rendah. Semua lapis SOFT, idempotent, ada backup+rollback. validate_spec.py read-only (tak merender/menulis dokumen). Direktif anti-fallback cuma append USER.md (no-restart).
- **NEXT:** Arif deploy + test di Acer (perintah di bawah), paste output balik untuk verifikasi.

## Yang dikerjakan (mengalamatkan 3 PERBAIKAN PENDING checkpoint 12.30)

### 1. validate_spec.py (Joki-tugas-: jarvis_document_factory/validate_spec.py) - BARU
Validator pra-render: cek SPEC SEBELUM run.py, kasih pesan JELAS (field apa yang kurang), bukan crash misterius.
- Reuse logika existing (bukan validator baru): parse_spec, validate, humanize_spec, apply_citation_layer, resolve_figures, assert_referenced_images_exist, + gate.check_citation_consistency. Single source of truth tetap di docfactory.
- Alur: (a) scan struktur non-fatal (lapor SEMUA masalah umum sekaligus: formats, title, section id/title/duplikat, toc-tanpa-chapter, akademik-tanpa-referensi, referensi unverified, figure block tak terdaftar); (b) urutan pra-render otoritatif (humanize -> citation -> resolve_figures -> assert_images -> validate) dengan pesan rapi per jenis error (SpecValidationError/UnsupportedFormatError/MissingImageError); (c) pratinjau citation_consistency level SPEC untuk dokumen akademik.
- Exit: 0 = siap render, 1 = ada masalah (tiap masalah + hint), 2 = file tak terbaca / bukan JSON. Dukung --json.
- Test: tests/test_validate_cli.py (valid->0, judul kosong->1, JSON rusak->2, toc-tanpa-bab->1, akademik-tanpa-referensi->1).
- SKILL.md ditambah bagian "Pra-cek SPEC (WAJIB sebelum run.py)" + "Kalau run.py GAGAL - ANTI-FALLBACK".
- deploy_document_factory.sh: jalur fallback non-rsync sekarang ikut menyalin validate_spec.py (jalur rsync sudah otomatis).

### 2. Direktif ANTI-FALLBACK (jarvis: scripts/deploy_anti_fallback.sh) - BARU
Marker USER.md `## DOCUMENT FACTORY ANTI-FALLBACK`. Idempotent per-marker + auto-backup (`USER.md.bak.<ts>`), no-restart, jalan di Acer. Isi: kalau run.py gagal DILARANG freehand; wajib validate_spec.py -> perbaiki SPEC -> re-run (maks 5 iterasi) -> stop & lapor Arif dengan SPEC+output. Mengikuti pola PERSIS deploy_docfactory_routing.sh.

### 3. Contoh SPEC makalah 4 bab (Joki-tugas-: jarvis_document_factory/examples/makalah_4bab_spec.json) - BARU
Kasus nyata yang dulu gagal: "Pengaruh Media Sosial terhadap Prestasi Belajar Mahasiswa". Struktur: frontmatter (Kata Pengantar), toc (Daftar Isi), BAB I-IV (Pendahuluan, Landasan Teori, Pembahasan, Penutup; ada sub-heading, paragraf, list, tabel), references (Daftar Pustaka). `is_academic: true` + `style: {}` supaya WARISI default akademik (A4, TNR12, spasi 1.5, justify, margin 3/3/4/3 -> mengajarkan margin kiri 4.0 cm yang dulu keliru 3.0). 5 sumber terverifikasi (Slameto 2010; Nasrullah 2015; Kaplan 2010; Syah 2017; Boyd 2007), tiap sumber DISITIR di body bentuk (Nama, Tahun) -> lolos citation_consistency dua-arah. Bersih humanizer (tanpa em-dash/en-dash/kutip keriting/emoji).

## PERINTAH DEPLOY + TEST DI ACER (buat Arif)
```
# A) Skill factory (validate_spec.py + contoh + SKILL.md) - no restart
cd ~/Joki-tugas- && git checkout main && git pull
bash jarvis_document_factory/deploy_document_factory.sh

# B) Direktif anti-fallback ke USER.md - no restart
cd ~/jarvis && git checkout main && git pull
bash scripts/deploy_anti_fallback.sh

# C) Uji validate_spec.py pada contoh (harus exit 0)
VENV=/home/arif/.hermes/hermes-agent/venv/bin/python
SKILL=~/.hermes/skills/productivity/jarvis-document-factory
$VENV $SKILL/validate_spec.py $SKILL/examples/makalah_4bab_spec.json ; echo "exit=$?"

# D) Render contoh lewat run.py (harus gate PASS / exit 0)
HERMES_RENDER_DECK=~/.hermes/scripts/render_deck.py \
$VENV $SKILL/run.py $SKILL/examples/makalah_4bab_spec.json --out /tmp/makalah_out --basename makalah_medsos ; echo "exit=$?"

# E) (opsional) test CLI
cd ~/Joki-tugas-/jarvis_document_factory && $VENV -m pytest tests/test_validate_cli.py -q
```
Paste output C/D/E balik biar bisa diverifikasi (evidence-first). Rollback USER.md: `cp USER.md.bak.<ts> USER.md`.

## CATATAN
- validate_spec.py = read-only, cocok dijalankan berkali-kali; tidak merender apa pun. Gate deterministik factory TETAP satu-satunya penentu DONE pada file jadi.
- Belum diubah (masih terbuka): relevance filter academic-search, action-gate v2 naik LIVE, word-count akurasi, PDF presentasi landscape. Lihat RESUME_HANDOFF.md Bagian 6.
