# RESUME / HANDOFF - Jarvis Tuning (sumber kebenaran tunggal)
_Update: 2026-07-01. Sesi baru (agent mana pun) tinggal baca file INI + HANDOFF_CHECKPOINT.md + .kiro/steering/jarvis-conventions.md, langsung lanjut._

> Baca urutan: (1) file ini buat peta cepat, (2) HANDOFF_CHECKPOINT.md bagian 12.x buat detail teknis, (3) .kiro/steering/jarvis-conventions.md buat aturan kerja.

---

## 0. TL;DR - di mana kita sekarang
Jarvis = AI assistant di server Acer (Hermes Gateway, Telegram interface, model via 9router). Fokus sesi-sesi terakhir = TUNING biar Jarvis jadi agent joki-kuliah/akademik yang andal. Semua perubahan = lapis SOFT (skill/plugin/direktif USER.md), idempotent, ada rollback.

MILESTONE (2026-07-01): skill **jarvis-document-factory** SELESAI, ter-deploy live di Acer, dan TERBUKTI: Jarvis bisa produksi PPTX/DOCX/PDF lewat pipeline deterministik ber-gate (SPEC JSON -> renderer -> gate). Routing fix + citation fix PROVEN. SEMUA PR (Joki-tugas- + jarvis) sudah dirampungin (lihat Bagian 4).

## 1. CARA KERJA INFRA (penting buat agent mana pun)
- Server: Acer `arif-aspire-5551` (Tailscale). Agent cloud TIDAK di tailnet -> SEMUA eksekusi di Acer lewat Jarvis (Telegram) atau SSH oleh Arif. Agent nulis kode/skrip ke repo; Arif/Jarvis jalanin di Acer lalu paste output balik.
- Live system di Acer: `~/.hermes/` (skills/, plugins/, scripts/, pipelines/, memories/USER.md, config.yaml). Repo `arifibnsawir-svg/jarvis` = working copy + sumber skrip (BUKAN sistem hidup).
- Gateway messaging = proses `hermes_cli.main gateway run` (BUKAN port 9119 = DASHBOARD). Verify gate-liveness via behavioral (log/decisions.jsonl), bukan PID listener 9119.
- Restart gateway ~210s (berat). Skill/direktif USER.md = aktif di sesi BARU (/new) TANPA restart. Plugin BARU = butuh restart (discover saat startup) + opt-in di config.yaml `plugins.enabled`.
- Model council/reasoning = combo `jarvis-reason` (via guardian_router port 20129). TERBUKTI sehat.
- JANGAN tulis API key mentah. JANGAN restart/edit config core tanpa approval Arif.

## 2. ATURAN KERJA (jarvis-conventions.md - wajib dipatuhi)
VERDICT format (FAKTA TERBUKTI/BELUM TERBUKTI/RISIKO/NEXT) - evidence-first (jangan klaim tanpa bukti command) - observe-before-patch (baca dulu, jangan nebak) - anti-False-READY (LLM gak boleh deklarasi DONE, itu wewenang gate) - anti-over-engineering (ingetin Arif "udah cukup") - SOFT vs HARD (PIPA1-3 = skill, PIPA4 = gate) - humanizer DEFAULT semua artefak (no em-dash/kutip keriting/emoji).

## 3. JARVIS-DOCUMENT-FACTORY (skill utama produksi dokumen)
- **Lokasi kode**: repo `arifibnsawir-svg/Joki-tugas-`, folder `jarvis_document_factory/` (PR #10 MERGED ke main). BUKAN di repo `jarvis`. Repo `jarvis` cuma reuse `render_deck.py` + nyimpen skrip tuning/checkpoint.
- **Deploy Acer**: `~/.hermes/skills/productivity/jarvis-document-factory/` (no-restart). Entry point wajib: `run.py`.
- **Prinsip**: Structure-Before-Render (model keluarkan SPEC JSON, renderer deterministik yang bikin file), gate deterministik = SATU-SATUNYA penentu DONE, reuse `render_deck.py` (PPTX) + skill `humanizer`, anti-halu gambar (path harus ada).
- **3 renderer**: PDF (WeasyPrint A4, target-counter TOC, hyphens:none), DOCX (python-docx mirror + scan TOC dari PDF + footer PAGE), PPTX (render_deck 16:9). Gate 7-cek: structure_order, citation_consistency, humanizer_clean, no_blank_page, no_dangling_heading, toc_accurate, images_real.
- **ROUTING FIX (PROVEN live)**: dua direktif di USER.md (skrip `scripts/deploy_docfactory_routing.sh` di repo jarvis): (1) PRECEDENCE = permintaan bikin dokumen WAJIB lewat skill ini; (2) OPERATIONAL RULES = wajib jalanin `run.py`, DONE cuma kalau gate PASS (exit 0), larang freehand `render_deck`/skip gate. Terbukti: Jarvis auto-pakai run.py, PDF = A4 factory (bukan slide-convert), gate PASS.
- **FIX citation_consistency PPTX-aware** (commit 8cc12e2 di Joki-tugas-): deck meringkas isi -> cek sitasi terhadap SPEC body, bukan teks deck yang teringkas. Terbukti FAIL(false-positive) -> PASS; referensi beneran tak terpakai tetap FAIL.
- **ARSI loop**: `run_pipeline` punya loop iterasi TAPI butuh `fix_fn`; `run.py` sengaja 1-pass (gate FAIL -> AWAITING_GATE + failed_checks). Iterasi "perbaiki SPEC" = agent-driven (Jarvis revisi SPEC lalu re-run), dicover direktif OPERATIONAL RULES. Ini BY DESIGN (konsisten anti-False-READY), bukan bug.
- **Catatan presentasi**: PDF presentasi keluar A4 dokumen (bukan slide landscape) karena PDF renderer factory = A4. Kalau butuh PDF slide landscape, ekspor PPTX via LibreOffice SETELAH gate PASS (belum diwajibkan; A4 handout dianggap cukup).

## 4. STATUS PR (semua RAMPUNG per 2026-07-01)
- **Joki-tugas-**: PR #10 (skill jarvis-document-factory) **MERGED ke main** (squash c544e1c, termasuk fix citation). PR #1-#6 (deliverable buku PKN / modul) **CLOSED sebagai arsip** (branch + commit utuh; itu OUTPUT kerja joki, bukan bagian tuning Jarvis). **0 PR terbuka.**
- **jarvis**: PR #2 (action-gate v2) merged sebelumnya. PR #3-#7 (academic-ppt-routing, web-search-ddgs, academic-search, mistake-logger, pipa4-final-gate) isinya SUDAH di main via `chore/consolidate-handoff` (diverifikasi: file identik SHA di main) -> PR **CLOSED sebagai superseded**. **0 PR terbuka.**

## 5. STATUS KEMAMPUAN (terbukti)
- **jarvis-document-factory** PROVEN live: routing (run.py+gate), citation PPTX-aware, PPTX 16:9 + PDF A4 + DOCX, gate deterministik PASS. Lihat Bagian 3.
- **Routing akademik** PROVEN: PPT akademik -> render_deck (bukan pptxgenjs). Bug academic-document-factory DOCX-only dipisah via direktif (12.25).
- **Web-grounding** PROVEN: academic-search (OpenAlex/Crossref no-key) + verify DOI; Google Scholar best-effort. ddgs = web umum.
- **mistake-logger** PROVEN LIVE: auto-log error ke LESSONS.md.
- **PIPA4 gate** engine sehat (audit+council jarvis-reason). Caveat page-count DOCX: render PDF dulu.
- **humanizer** default semua artefak. Ada 2 humanizer (ambiguous) -> load path eksplisit `~/.hermes/skills/humanizer/SKILL.md`.

## 6. GAP / OPEN ITEMS (prioritas, evidence-based)
1. **RELEVANSI sumber (kualitas joki #1)**: academic-search verify "DOI resolve" tapi BELUM cek relevansi topik (tes gaya-belajar: 4/6 sumber tangensial). FIX: filter judul/abstract match kata kunci inti.
2. **action-gate v2 naik LIVE**: masih shadow; nunggu data organik + keputusan interpreter + GO Arif.
3. **Word-count akurasi**: Jarvis suka misreport panjang -> verify via wc/PDF.
4. (opsional) **PDF presentasi**: sekarang A4 dokumen; kalau mau slide landscape, tambah ekspor LibreOffice pasca-gate.
5. (opsional) **office-academic-skill redundan** (pakai academic-document-factory untuk Word).

> CATATAN: rencana lama "distill skill academic-deliverable-method dari deliverable joki" = SUDAH TEREALISASI jadi **jarvis-document-factory** (di repo Joki-tugas-). Jangan bikin skill akademik baru lagi tanpa alasan kuat (anti-over-engineering).

## 7. DEPLOY & ROLLBACK (tiap fitur, semua idempotent + backup)
Pola: `cd ~/jarvis && git fetch origin && git checkout <branch> && git pull && bash scripts/<deploy>.sh`. Skrip inti:
- `deploy_docfactory_routing.sh` (USER.md: 2 direktif routing factory) - BARU 2026-07-01.
- `deploy_academic_ppt_routing_fix.sh` - `deploy_web_search_ddgs.sh` (config core, approval) - `deploy_academic_search.sh` (skill+pip) - `deploy_mistake_logger.sh` (plugin+config, RESTART) - `deploy_pipa4_final_gate.sh` (helper+USER.md).
- Skill factory (Joki-tugas-): `cd ~/Joki-tugas- && git checkout main && git pull && bash jarvis_document_factory/deploy_document_factory.sh`.
- Rollback tiap skrip cetak path backup (`USER.md.bak.<ts>` / `config.yaml.bak.<ts>`). Kill-switch mistake-logger: `MISTAKE_LOGGER_OFF=1`. Kill-switch action-gate: `ACTION_GATE_MODE=off`.

## 8. KALAU PAKAI AGENT SELAIN KIRO
- **Skill produksi dokumen** = repo `Joki-tugas-` (`jarvis_document_factory/`). **Tuning/infra/checkpoint** = repo `jarvis`. Baca file ini + HANDOFF_CHECKPOINT.md (12.x) + jarvis-conventions.md.
- Eksekusi tetap lewat Jarvis(Telegram)/SSH Arif (agent cloud gak di tailnet Acer).
- Patuhi konvensi (Bagian 2). Observe-before-patch: SELALU baca state Acer sebelum patch. Jangan percaya checkpoint lama buat status infra -> verify ulang dengan command.
