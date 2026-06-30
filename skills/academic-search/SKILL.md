---
name: academic-search
description: "Cari + verifikasi sumber ilmiah untuk tugas akademik (makalah, laporan, PPT sidang, skripsi, mini-book). Search multi-database (Google Scholar, OpenAlex, Crossref, Semantic Scholar, PubMed, arXiv, Garuda/SINTA) lalu WAJIB verifikasi tiap sitasi (DOI resolve + URL kebuka) sebelum dikutip. Indonesia-first. Anti-halu: sumber tak terverifikasi dibuang atau dilabel, tidak pernah dikarang."
category: research
license: MIT (lihat LICENSE.upstream - zLanqing/codex-claude-academic-skills)
metadata:
  layer: intake
  no_key: true
  deps: [requests, scholarly]
---

# ACADEMIC SEARCH - cari sumber ilmiah kredibel (anti-halu)

## Kapan dipakai
Tiap kali butuh SUMBER ilmiah buat artefak akademik (makalah, laporan, PPT sidang/seminar, skripsi, mini-book, daftar pustaka). Dipanggil SEBELUM nulis isi/daftar pustaka. Bekerja lintas-skill produksi (academic-document-factory, render_deck, office-document-ops).

## Prinsip inti (WAJIB)
1. **Banyak sumber (coverage)** biar gampang: query beberapa database sekaligus, jangan satu.
2. **Verifikasi 100% (kredibilitas)**: SETIAP sitasi WAJIB lolos verify (DOI resolve via CrossRef ATAU URL kebuka) sebelum dikutip. Yang gagal -> BUANG atau label "belum terverifikasi". JANGAN pernah ngarang DOI/penulis/jurnal/tahun.
3. **Indonesia-first**: utamakan jurnal Indonesia dulu, baru internasional.
4. **Cite-or-abstain**: kalau gak nemu sumber terverifikasi -> bilang "belum nemu", jangan dipaksa.

## Workflow (search-wide -> verify -> cite-only-verified)
### 1. SEARCH (multi-database, no-key dulu)
Baca how-to di `paper-lookup/references/` untuk query tiap API. Urutan prioritas:
- **Indonesia-first**: OpenAlex & Crossref (filter afiliasi/jurnal Indonesia), Garuda (https://garuda.kemdiktisaintek.go.id), SINTA (https://sinta.kemdiktisaintek.go.id), repositori .ac.id.
- **Internasional/umum**: OpenAlex, Crossref, Semantic Scholar (`paper-lookup/references/{openalex,crossref,semantic-scholar}.md`).
- **Domain spesifik**: PubMed/PMC (`citation-management/scripts/search_pubmed.py`), arXiv/bioRxiv/medRxiv.
- **Google Scholar** (WAJIB ikut, best-effort): `citation-management/scripts/search_google_scholar.py` (pakai `scholarly`, no-key). Catatan: Scholar bisa kena CAPTCHA/rate-limit -> pakai delay (sudah built-in 2-5s), jadikan SATU dari banyak sumber, JANGAN andalkan sendirian. Kalau ke-block, sumber no-key lain tetap nutup.
- Strategi: minimal 3 database komplementer + citation-chaining/snowball. Lihat `literature-review/references/database_strategies.md`.

### 2. KONSOLIDASI
- Kumpulkan hasil ke results.json -> `literature-review/scripts/search_databases.py <results.json> --deduplicate --rank citations --format markdown` (dedup + ranking by sitasi/tahun).

### 3. VERIFY (GERBANG WAJIB - di sinilah kredibilitas 100% ditegakkan)
- `literature-review/scripts/verify_citations.py <file.md>` -> ekstrak DOI -> cek resolve via doi.org + metadata CrossRef + cek URL kebuka. Output: verified vs failed.
- ATAU `citation-management/scripts/validate_citations.py refs.bib --check-dois`.
- **HANYA sitasi yang LOLOS yang boleh masuk daftar pustaka.** Yang failed -> buang/cari ganti.
- DOI -> BibTeX terverifikasi: `citation-management/scripts/doi_to_bibtex.py -i dois.txt -o refs.bib`.

### 4. CITE
- Sajikan hanya sumber terverifikasi (judul, penulis, jurnal, tahun, DOI/link yang resolve). Format sitasi sesuai kebutuhan (APA default; lihat `literature-review/references/citation_styles.md`).

## Aturan keras (anti-halu)
- DILARANG nyajiin link/DOI tanpa lewat verify. (Ini akar masalah link Garuda mati yang halu.)
- DILARANG scrape Google Scholar sebagai SATU-SATUNYA sumber (CAPTCHA -> gampang gagal -> halu). Selalu dampingi OpenAlex/Crossref + verify.
- Kalau verify gagal semua -> "belum nemu sumber terverifikasi", bukan ngarang.

## Dependency
`pip install requests scholarly` (no-key untuk OpenAlex/Crossref/PubMed/doi.org; Semantic Scholar key opsional). Tidak ada binary native (aman di CPU lama).

## Verification Checklist
- [ ] Query >= 3 database (termasuk Indonesia-first + Google Scholar).
- [ ] Hasil di-dedup + rank.
- [ ] SEMUA sitasi lolos verify_citations (DOI resolve / URL kebuka).
- [ ] Sitasi gagal-verify dibuang atau dilabel, TIDAK dikutip sebagai fakta.
- [ ] Indonesia-first dihormati.
