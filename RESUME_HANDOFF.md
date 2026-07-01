# RESUME / HANDOFF - Jarvis Tuning (sumber kebenaran tunggal)
_Update: 2026-07-01 (sesi lanjutan malam). Sesi baru (agent mana pun) tinggal baca file INI + HANDOFF_CHECKPOINT.md + HANDOFF_CHECKPOINT_2026-07-01_LANJUTAN.md + .kiro/steering/jarvis-conventions.md, langsung lanjut._

> Baca urutan: (1) file ini buat peta cepat, (2) HANDOFF_CHECKPOINT.md bagian 12.x + HANDOFF_CHECKPOINT_2026-07-01_LANJUTAN.md buat detail teknis, (3) .kiro/steering/jarvis-conventions.md buat aturan kerja.

---

## 0. TL;DR - di mana kita sekarang
Jarvis = AI assistant di server Acer (Hermes Gateway, Telegram interface, model via 9router). Fokus sesi-sesi terakhir = TUNING biar Jarvis jadi agent joki-kuliah/akademik yang andal. Semua perubahan = lapis SOFT (skill/plugin/direktif USER.md), idempotent, ada rollback.

MILESTONE (2026-07-01): skill **jarvis-document-factory** SELESAI, ter-deploy live di Acer, dan TERBUKTI: Jarvis bisa produksi PPTX/DOCX/PDF lewat pipeline deterministik ber-gate (SPEC JSON -> renderer -> gate). Routing fix + citation fix PROVEN. SEMUA PR (Joki-tugas- + jarvis) sudah dirampungin (lihat Bagian 4).

SESI LANJUTAN (2026-07-01 malam): 3 PERBAIKAN PENDING + 2 OPEN ITEMS kelar:
- 3 perbaikan checkpoint 12.30 (validate_spec, anti-fallback, contoh makalah) DEPLOYED + VERIFIED
- #1 relevance filter academic-search DEPLOYED + VERIFIED
- #3 word-count akurasi COMMITTED (Joki-tugas- `a6dff05` + `d366824`), PENDING deploy+verify di Acer

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
- **Prinsip**: Structure-Before-Render (model keluarkan SPEC JSON, renderer deterministik yang membuat file), gate deterministik = SATU-SATUNYA penentu DONE, reuse `render_deck.py` (PPTX) + skill `humanizer`, anti-halu gambar (path harus ada).
- **3 renderer**: PDF (WeasyPrint A4, target-counter TOC, hyphens:none), DOCX (python-docx mirror + scan TOC dari PDF + footer PAGE), PPTX (render_deck 16:9). Gate 7-cek: structure_order, citation_consistency, humanizer_clean, no_blank_page, no_dangling_heading, toc_accurate, images_real.
- **ROUTING FIX (PROVEN live)**: dua direktif di USER.md: PRECEDENCE + OPERATIONAL RULES. Jarvis auto-pakai run.py, PDF = A4 factory, gate PASS.
- **FIX citation_consistency PPTX-aware** (commit 8cc12e2 di Joki-tugas-): deck meringkas isi -> cek sitasi terhadap SPEC body, bukan teks deck yang teringkas.
- **PRA-CEK + ANTI-FALLBACK + TEMPLATE (VERIFIED)**: validate_spec.py, deploy_anti_fallback.sh, makalah_4bab_spec.json.
- **WORD-COUNT (BARU, COMMITTED, PENDING VERIFY)**: `word_count` dihitung dari file jadi (bukan estimasi SPEC), ada di RenderResult + GateVerdict + JSON report run.py. Jarvis baca dari situ, nggak nebak. Joki-tugas- `a6dff05` + `d366824`.
- **ARSI loop**: run.py sengaja 1-pass, iterasi agent-driven. BY DESIGN, bukan bug.
- **Catatan presentasi**: PDF slide landscape = ekspor LibreOffice pasca-gate PPTX (belum diwajibkan).

## 3b. ACADEMIC-SEARCH (cari + saring + verifikasi sumber ilmiah)
- **Lokasi**: repo `jarvis`, `skills/academic-search/`. Deploy: `scripts/deploy_academic_search.sh` (no-restart).
- **Alur (VERIFIED)**: SEARCH multi-database -> KONSOLIDASI -> RELEVANCE FILTER (`relevance_filter.py`) -> VERIFY DOI -> cite-only-verified.
- **relevance_filter.py (VERIFIED)**: stdlib murni. Skor 0..1 coverage+title, substring match tahan imbuhan ID. Pisah RELEVAN vs TANGENSIAL. Menutup gap sumber tangensial yang dulu lolos verify DOI.

## 4. STATUS PR (semua RAMPUNG per 2026-07-01)
- **Joki-tugas-**: PR #10 MERGED. PR #1-#6 CLOSED (arsip). **0 PR terbuka.** Commit langsung: `4fbf6c2`, `2324405`, `a6dff05`, `d366824`.
- **jarvis**: PR #2 merged. PR #3-#7 CLOSED sebagai superseded. **0 PR terbuka.** Commit langsung: deploy_anti_fallback.sh, relevance_filter, checkpoint, RESUME, dll.

## 5. STATUS KEMAMPUAN (terbukti)
- **jarvis-document-factory** PROVEN: routing, citation PPTX-aware, gate PASS, validate_spec + anti-fallback.
- **Relevance filter** PROVEN: selftest PASS, dummy 2 relevan/1 tangensial.
- **Word-count** COMMITTED (PENDING verify): word_count di JSON report run.py, dihitung dari file jadi.
- **Routing akademik** PROVEN. **Web-grounding** PROVEN. **mistake-logger** PROVEN. **PIPA4 gate** sehat. **humanizer** default.

## 6. GAP / OPEN ITEMS (prioritas, evidence-based)
1. ~~RELEVANSI sumber~~ SELESAI + VERIFIED. `relevance_filter.py` live.
2. **action-gate v2 naik LIVE**: masih shadow; nunggu data organik + GO Arif.
3. ~~WORD-COUNT akurasi~~ SELESAI + COMMITTED (Joki-tugas- `a6dff05` + `d366824`). `word_count` di RenderResult/GateVerdict + `count_words()` di readers.py + tiap renderer + JSON report run.py + SKILL.md "baca dari JSON, jangan nebak". **PENDING deploy+verify di Acer.**
4. (opsional) PDF presentasi landscape.
5. (opsional) office-academic redundan.

> CATATAN 2: 3 perbaikan checkpoint 12.30 + #1 relevance filter VERIFIED.
> CATATAN 3: #3 word-count COMMITTED, PENDING deploy (Joki-tugas- `d366824`). Sisa: #2, #4, #5.

## 7. DEPLOY & ROLLBACK (tiap fitur, semua idempotent + backup)
Pola: `cd ~/<repo> && git checkout main && git pull && bash scripts/<deploy>.sh`.
- Skill factory: `cd ~/Joki-tugas- && git checkout main && git pull && bash jarvis_document_factory/deploy_document_factory.sh`
- Jarvis skrip: `deploy_docfactory_routing.sh`, `deploy_anti_fallback.sh`, `deploy_academic_search.sh`, `deploy_academic_ppt_routing_fix.sh`, `deploy_web_search_ddgs.sh`, `deploy_mistake_logger.sh`, `deploy_pipa4_final_gate.sh`.
- Rollback: backup file USER.md/conifg.yaml. Kill-switch: MISTAKE_LOGGER_OFF, ACTION_GATE_MODE=off.

## 8. KALAU PAKAI AGENT SELAIN KIRO
- Skill produksi = repo Joki-tugas-. Tuning/infra/checkpoint = repo jarvis. Baca RESUME + CHECKPOINT + LANJUTAN + jarvis-conventions.
- Eksekusi tetap lewat Jarvis(Telegram)/SSH Arif. Observe-before-patch, patuhi konvensi.
