# HANDOFF CHECKPOINT - Sesi 2026-07-01 (lanjutan section 12.30)
_Companion buat HANDOFF_CHECKPOINT.md. Sesi ini dikerjakan pakai Notion AI (Opus) + koneksi GitHub MCP, MENERUSKAN sesi Kiro yang putus karena limit bulanan. Semua commit GitHub via akun arifibnsawir-svg (GitHub MCP OAuth)._

## 12.30 JARVIS-DOCUMENT-FACTORY: verifikasi live + routing/citation fix + sourcing + konsultasi dosen + uji dunia nyata

### KONTEKS
- Kiro selesai BUILD + DEPLOY skill jarvis-document-factory (PR #10 Joki-tugas-), lalu kena limit SEBELUM validasi real-turn.
- Notion AI ambil alih: verifikasi real-turn via Jarvis (Telegram), fix yang ketemu, rampungin PR. Eksekusi Acer tetap lewat Jarvis; commit repo lewat GitHub MCP.

### YANG DIVERIFIKASI / DIFIX (semua evidence-based)
1. **ROUTING** (bug utama: Jarvis freehand, gak lewat skill/gate).
   - FIX: 2 direktif USER.md (PRECEDENCE + OPERATIONAL RULES). PROVEN: Jarvis jalanin run.py + gate PASS.
2. **citation_consistency PPTX-aware** — deck meringkas isi, cek SPEC body bukan teks deck. Commit 8cc12e2.
3. **ARSI loop** — BY DESIGN (agent-driven iteration, bukan auto-loop dalam 1 call). Bukan bug.
4. **ACADEMIC SOURCING** — wiring academic-search -> factory. PROVEN: 25 sumber Indonesia terverifikasi.
5. **CITATION PARSER ROBUST** — comma-form, dkk, et al. Commit ad88aed. PROVEN: 6/6 sitasi terdeteksi.
6. **DOSEN RULES FIRST** — direktif: tiap tugas kuliah, Jarvis WAJIB tanya aturan ke Arif dulu, jangan nebak. PROVEN: Jarvis nanya 8 pertanyaan detail.

### ARSITEKTUR (re-grounding dari repo, BUKAN asumsi)
- **NEURO-ARC** = lapis REPRESENTASI (narasi->entitas->ukuran->relasi->output = TaskState). Dipakai SEBELUM eksekusi.
- **A.R.S.I** = DOKTRIN/ATURAN (Audit->Rancang->Sistemasi->Iterasi). Dipatuhi, tidak "berjalan".
- **arsi engine** = MESIN/RUNTIME yang menjalankan aturan A.R.S.I di atas TaskState. Punya PID.
- **4-PIPA**: PIPA1-3 = SOFT (agent+combo+skill). PIPA4 = HARD (gate deterministik Python).
- Urutan: PIPA-ROUTING -> NEURO-ARC -> A.R.S.I -> arsi engine -> GATE PIPA4.
- **PIPA-ROUTING** = adaptive depth (trivial 0-pipa / riset bebas / artefak penuh) + saklar Fable/Mythos.

### STEERING / ATURAN DOSEN (keputusan final)
- Awalnya dirancang: deploy folder steering dari repo ke Acer, Jarvis baca file .md.
- Arif koreksi: "Aturan dosen itu banyak, harus flexible, jangan hardcode 2 file."
- **Keputusan final**: SIMPLIFIKASI. Jarvis TANYA langsung ke Arif tiap ada tugas. Tidak perlu folder steering. Ini lebih flexible & sesuai kebutuhan.
- Direktif DOSEN RULES FIRST di-deploy ke USER.md (backup aman, idempotent, no restart).

### UJI DUNIA NYATA — makalah "Pengaruh Media Sosial terhadap Prestasi Belajar Mahasiswa"
**Yang BERHASIL:**
- Konsultasi aturan: Jarvis nanya 8 pertanyaan (format, sistematika, font, sitasi, rubrik) ✅
- Academic-search: 31 hasil Crossref/OpenAlex, 25 lolos verify DOI ✅
- Struktur konten: Cover, Kata Pengantar, 4 Bab, Daftar Pustaka ✅
- Humanizer: nol em-dash/en-dash/curly/emoji ✅
- Font & spasi: TNR 12pt, spasi 1.5, align justify ✅

**Yang GAGAL:**
- **Factory ditinggal**: Jarvis coba run.py 3x -> gagal (SPEC validation error) -> switch ke freehand python-docx
- **Gate di-skip**: tidak ada gate deterministik. Output freehand tanpa PASS/FAIL.
- **Margin kiri meleset**: 3.0cm (aturan 4.0cm). Freehand = tidak ada validasi.
- **Halaman kurang**: ~7 halaman (target minimal 8).
- **Daftar Pustaka chaos**: beberapa heading BAB dan paragraf isi masuk ke daftar pustaka.

**ROOT CAUSE:** Jarvis tidak bisa susun SPEC JSON yang valid untuk tugas besar (25 refs, 4 bab). Gagal 3x -> menyerah -> fallback freehand. Ini pola klasik dari checkpoint 12.21/12.24.

### 3 PERBAIKAN PENDING (next session)
1. **validate_spec.py** — script pra-render yang ngecek SPEC sebelum run.py. Error message jelas: field apa yang kurang, bukan crash misterius.
2. **Direktif anti-fallback** — "Kalau run.py gagal, JANGAN switch freehand. Baca error, perbaiki SPEC, ulangi. Maks 5 iterasi sebelum minta bantuan Arif."
3. **Contoh SPEC makalah 4-bab** di `examples/` — biar Jarvis punya template konkret, bukan nebak struktur.

### DIRECTIVES LIVE DI ACER (USER.md)
Semua SOFT, idempotent + backup, no restart:
1. DOCUMENT FACTORY ROUTING PRECEDENCE
2. DOCUMENT FACTORY OPERATIONAL RULES
3. FACTORY ACADEMIC SOURCING
4. DOSEN RULES FIRST (KONSULTASI ATURAN) — BARU 2026-07-01

### COMMIT REPO (sesi ini, semua via arifibnsawir-svg)
**Joki-tugas-:** 8cc12e2 (citation PPTX-aware), c544e1c (merge PR #10), ad88aed (citation parser robust).
**jarvis:** 9c9c19f (deploy_docfactory_routing.sh), f93cda6 (RESUME_HANDOFF sync), b9793b0 (checkpoint awal), fb61356 (deploy_factory_academic_sourcing.sh), ae79373 (checkpoint update), + commit ini.

### RAMPUNG PR
- Joki-tugas-: PR #10 merged. PR #1-#6 closed. 0 terbuka.
- jarvis: PR #3-#7 closed (isi di main via konsolidasi). 0 terbuka.

### ROLLBACK
- USER.md: cp ~/.hermes/memories/USER.md.bak.<ts> USER.md.
- gate/citation fix: revert commit di Joki-tugas-.
- PR closed bisa di-reopen.

### OPEN ITEMS (lanjut tuning)
1. **3 PERBAIKAN DI ATAS** (validate_spec.py, anti-fallback directive, contoh SPEC makalah 4-bab)
2. Relevance filter academic-search
3. action-gate v2 naik LIVE
4. PDF presentasi landscape
5. structure_order whitespace-insensitive
