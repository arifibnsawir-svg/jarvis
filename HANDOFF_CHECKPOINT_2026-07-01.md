# HANDOFF CHECKPOINT - Sesi 2026-07-01 (lanjutan section 12.30)
_Companion buat HANDOFF_CHECKPOINT.md. Sesi ini dikerjakan pakai Notion AI (Opus) + koneksi GitHub MCP, MENERUSKAN sesi Kiro yang putus karena limit bulanan. Semua commit GitHub via akun arifibnsawir-svg (GitHub MCP OAuth)._

## 12.30 JARVIS-DOCUMENT-FACTORY: verifikasi live + routing/citation fix + rampung PR

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
   - Diagnosa: run_pipeline PUNYA loop tapi butuh fix_fn; run.py sengaja 1-pass (fix_fn=None) -> gate FAIL = AWAITING_GATE. Iterasi 'perbaiki SPEC' = agent-driven (Jarvis revisi + re-run), dicover OPERATIONAL RULES. BY DESIGN (konsisten anti-False-READY), bukan bug. Tidak ada perubahan kode.

### RAMPUNG PR
- Joki-tugas-: PR #10 (skill) MERGED ke main (squash c544e1c, termasuk fix 8cc12e2). PR #1-#6 (deliverable buku PKN/modul) CLOSED sebagai arsip (OUTPUT kerja, bukan tuning; branch utuh). 0 terbuka.
- jarvis: PR #3-#7 diverifikasi isinya SUDAH di main (spot-check SHA identik: pipa4_gate.sh b9bfe05, deploy_mistake_logger.sh 139f72c) via chore/consolidate-handoff -> CLOSED superseded. 0 terbuka.

### COMMIT REPO (sesi ini)
- Joki-tugas-: 8cc12e2 (fix gate), c544e1c (merge PR #10 -> main).
- jarvis: 9c9c19f (scripts/deploy_docfactory_routing.sh), f93cda6 (RESUME_HANDOFF.md sync), + checkpoint ini.

### INFRA BARU: GitHub MCP
- GitHub MCP server (api.githubcopilot.com/mcp) tersambung ke agen Notion AI Arif via OAuth. Punya tool tulis: create_or_update_file, push_files, merge_pull_request, dll. Jadi commit/PR bisa langsung dari chat (bukan lewat Jarvis).
- CATATAN: git push DARI ACER (Jarvis) kena 403 - kredensial git Acer read-only (dulu Kiro yang push). Untuk sekarang: push lewat GitHub MCP (Notion AI), Jarvis cukup pull+deploy. Kalau mau Jarvis push sendiri, set PAT scope repo di Acer (opsional).

### STATUS AKHIR
- Skill jarvis-document-factory: LIVE di Acer, routing+citation PROVEN, gate deterministik jalan. Target 'skill jalan mulus' TERCAPAI.
- Repo bersih: Joki-tugas- main = skill final; jarvis main = tuning+skrip+RESUME terkini. 0 PR terbuka di dua repo.

### OPEN ITEMS (lanjut tuning - lihat RESUME_HANDOFF.md Bagian 6)
1. Relevance filter academic-search (judul/abstract match kata kunci inti).
2. action-gate v2 naik LIVE (masih shadow; butuh data organik + GO Arif).
3. Word-count akurasi (verify via wc/PDF).
4. (opsional) PDF presentasi landscape; office-academic-skill redundan.

### ROLLBACK
- USER.md direktif: cp ~/.hermes/memories/USER.md.bak.<ts> USER.md.
- gate.py fix: revert commit 8cc12e2 di Joki-tugas-.
- PR closed bisa di-reopen kapan saja (branch utuh).
