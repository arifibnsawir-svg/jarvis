# HANDOFF CHECKPOINT - Sesi 2026-07-01 (lanjutan section 12.30)
_Companion buat HANDOFF_CHECKPOINT.md. Sesi ini dikerjakan pakai Notion AI (Opus) + koneksi GitHub MCP, MENERUSKAN sesi Kiro yang putus karena limit bulanan. Semua commit GitHub via akun arifibnsawir-svg (GitHub MCP OAuth)._

## 12.30 JARVIS-DOCUMENT-FACTORY: verifikasi live + routing/citation fix + rampung PR + sourcing+wiring

### KONTEKS
- Kiro selesai BUILD + DEPLOY skill jarvis-document-factory (PR #10 Joki-tugas-), lalu kena limit SEBELUM validasi real-turn + learning checkpoint.
- Notion AI ambil alih: verifikasi real-turn via Jarvis (Telegram), fix yang ketemu, rampungin PR. Eksekusi Acer tetap lewat Jarvis; commit repo lewat GitHub MCP.

### YANG DIVERIFIKASI / DIFIX (semua evidence-based)
1. ROUTING (bug utama berulang: Jarvis freehand, gak lewat skill/gate).
   - Bukti awal: Turn 1 Jarvis pakai pptx-slides-creation-guard + office-document-ops, PDF landscape slide-convert, gate ad-hoc palsu. Setelah direktif PRECEDENCE saja: masih freehand render_deck + skip gate ("lewat skill" terlalu longgar).
   - FIX: tambah direktif OPERATIONAL RULES di USER.md (wajib run.py, DONE cuma kalau gate PASS, larang freehand/skip). Skrip: scripts/deploy_docfactory_routing.sh (2 direktif, idempotent, no restart).
   - PROVEN (re-test /new): Jarvis jalanin run.py -> exit 0, gate pdf+pptx PASS; PPTX 16:9 (verified 13.33x7.5in), PDF A4 factory (595x842). BUKAN lagi slide-convert.
2. citation_consistency PPTX-aware.
   - Bukti: Turn 2 gate FAIL 'reference-never-cited: Prayitno'. Akar: deck meringkas isi bab (paragraf ber-sitasi tak muncul di slide), tapi refs diambil dari SPEC penuh -> false-positive.
   - FIX (gate.py): untuk fmt==pptx, cek sitasi terhadap SPEC body (_spec_body_text), bukan teks deck. Deck-cited selalu subset SPEC-cited -> aman. PDF/DOCX tak berubah.
   - Divalidasi end-to-end di sandbox pakai deck ASLI: FAIL -> PASS; referensi beneran tak terpakai tetap FAIL. Commit 8cc12e2 (Joki-tugas-), live di Acer, re-test deck akademik PASS.
3. ARSI loop (kenapa gate FAIL Turn 2 gak auto-iterasi).
   - Diagnosa: run_pipeline PUNYA loop tapi butuh fix_fn; run.py sengaja 1-pass (fix_fn=None) -> gate FAIL = AWAITING_GATE. Iterasi 'perbaiki SPEC' = agent-driven (Jarvis revisi + re-run), dicover OPERATIONAL RULES. BY DESIGN, bukan bug.
4. ACADEMIC SOURCING (wiring academic-search -> factory).
   - Bukti awal: Jarvis nulis referensi dari ingatan (schema authors/year/title/doi) -> _ref_surnames kosong -> citation_consistency FAIL. FIX: direktif FACTORY ACADEMIC SOURCING di USER.md: deliverable akademik WAJIB panggil academic-search dulu, hanya sumber lolos verify (DOI resolve + URL hidup) masuk SPEC pakai schema {id, apa, url, verified:true}. Skrip: scripts/deploy_factory_academic_sourcing.sh. Commit fb61356.
   - PROVEN (re-test /new): Jarvis cari Crossref Indonesia-first -> 6/10 sumber PASS verify -> 6 referensi terverifikasi masuk SPEC -> PDF 9 halaman, humanizer-clean. Bug citation_consistency ditemukan (lihat #5).
5. CITATION PARSER ROBUST (comma-form, dkk, et al).
   - Bukti: PDF body mengandung "(Tarma, 2014)" dan "Halik dkk. (2017)" tapi gate false-FAIL 'reference-never-cited'. Akar: CITE_SINGLE regex hanya cocokkan "Name (Year)", buta ke "Name, Year" (comma) dan "Name dkk./et al. (Year)".
   - FIX (citation.py): CITE_SINGLE = r"([A-Z][a-zA-Z]+)(?:\s+(?:dkk\.|et al\.))?[\,\(]\s*(\d{4})\)?". Commit ad88aed (Joki-tugas- main).
   - PROVEN: PDF final re-test -> exit 0, gate PASS, 6/6 sitasi terdeteksi.

### END-TO-END ACCEPTANCE (proven 2026-07-01 ~16:31)
- Prompt: "buatkan makalah PDF topik Pengaruh Gaya Belajar terhadap Prestasi Belajar Mahasiswa"
- Skill dipanggil: academic-search (cari) -> jarvis-document-factory (produksi)
- Sumber: Crossref Indonesia-first, 6/10 PASS verify DOI, 6 referensi ke SPEC {apa, verified}
- run.py -> exit 0, status DONE, gate PASS, 9 halaman, humanizer-clean, 6/6 surname terdeteksi
- PDF terverifikasi independen: body punya semua nama, Daftar Pustaka lengkap, humanizer-clean

### RAMPUNG PR
- Joki-tugas-: PR #10 (skill) MERGED ke main (squash c544e1c, termasuk fix 8cc12e2). PR #1-#6 (deliverable buku PKN/modul) CLOSED sebagai arsip. 0 terbuka.
- jarvis: PR #3-#7 diverifikasi isinya SUDAH di main (spot-check SHA identik) via chore/consolidate-handoff -> CLOSED superseded. 0 terbuka.

### COMMIT REPO (sesi ini)
- Joki-tugas-: 8cc12e2 (fix gate citation PPTX-aware), c544e1c (merge PR #10 -> main), ad88aed (fix citation parser robust).
- jarvis: 9c9c19f (scrips/deploy_docfactory_routing.sh), f93cda6 (RESUME_HANDOFF.md sync), b9793b0 (checkpoint ini), fb61356 (scripts/deploy_factory_academic_sourcing.sh).

### INFRA BARU: GitHub MCP
- GitHub MCP server (api.githubcopilot.com/mcp) tersambung ke agen Notion AI Arif via OAuth. Punya tool tulis: create_or_update_file, push_files, merge_pull_request, dll. Jadi commit/PR bisa langsung dari chat.
- CATATAN: git push DARI ACER (Jarvis) kena 403 - kredensial git Acer read-only (dulu Kiro yang push). Untuk sekarang: push lewat GitHub MCP (Notion AI), Jarvis cukup pull+deploy.

### DIRECTIVES LIVE DI ACER (USER.md)
Semua SOFT, idempotent + backup, no restart. Skrip deploy di scripts/:
1. DOCUMENT FACTORY ROUTING PRECEDENCE (wajib lewat skill factory, demote jalur lama)
2. DOCUMENT FACTORY OPERATIONAL RULES (wajib run.py, DONE hanya gate PASS, larang freehand/skip)
3. FACTORY ACADEMIC SOURCING (deliverable akademik WAJIB academic-search dulu, verified only, Indonesia-first, anti-halu)

### STATUS AKHIR
- Skill jarvis-document-factory: LIVE di Acer, routing+academic sourcing+citation parser PROVEN, gate deterministik PASS, end-to-end proven bikin makalah PDF 9 hal ber-sumber Indonesia terverifikasi. Target 'skill jalan mulus' TERCAPAI.
- Repo bersih: Joki-tugas- main = skill final + semua fix; jarvis main = tuning+skrip+RESUME terkini. 0 PR terbuka.

### OPEN ITEMS (lanjut tuning - lihat RESUME_HANDOFF.md)
1. Relevance filter academic-search (judul/abstract match kata kunci inti).
2. action-gate v2 naik LIVE (masih shadow; butuh data organik + GO Arif).
3. Word-count akurasi (verify via wc/PDF).
4. (opsional) PDF presentasi landscape; office-academic-skill redundan.
5. (opsional) structure_order whitespace-insensitive.

### ROLLBACK
- USER.md direktif: cp ~/.hermes/memories/USER.md.bak.<ts> USER.md.
- gate.py / citation.py fix: revert commit di Joki-tugas-.
- PR closed bisa di-reopen (branch utuh).
