# RESUME / HANDOFF - Jarvis Tuning (sumber kebenaran tunggal)
_Update: 2026-07-01 (sesi lanjutan malam). Sesi baru (agent mana pun) tinggal baca file INI + HANDOFF_CHECKPOINT.md + HANDOFF_CHECKPOINT_2026-07-01_LANJUTAN.md + .kiro/steering/jarvis-conventions.md, langsung lanjut._

> Baca urutan: (1) file ini buat peta cepat, (2) HANDOFF_CHECKPOINT.md bagian 12.x + HANDOFF_CHECKPOINT_2026-07-01_LANJUTAN.md buat detail teknis, (3) .kiro/steering/jarvis-conventions.md buat aturan kerja.

---

## 0. TL;DR - di mana kita sekarang
Jarvis = AI assistant di server Acer (Hermes Gateway, Telegram interface, model via 9router). Fokus sesi-sesi terakhir = TUNING biar Jarvis jadi agent joki-kuliah/akademik yang andal. Semua perubahan = lapis SOFT (skill/plugin/direktif USER.md), idempotent, ada rollback.

MILESTONE (2026-07-01): skill **jarvis-document-factory** SELESAI, ter-deploy live di Acer, dan TERBUKTI: Jarvis bisa produksi PPTX/DOCX/PDF lewat pipeline deterministik ber-gate (SPEC JSON -> renderer -> gate). Routing fix + citation fix PROVEN. SEMUA PR (Joki-tugas- + jarvis) sudah dirampungin.

SESI LANJUTAN (2026-07-01 malam): **5 ITEM KELAR (VERIFIED):**
1. ✅ validate_spec.py — validator pra-render
2. ✅ ANTI-FALLBACK — direktif larangan freehand
3. ✅ Contoh makalah 4 bab — template SPEC
4. ✅ Relevance filter (#1) — saring sumber tangensial
5. ✅ Word-count (#3) — hitung dari file jadi, PDF 793 exact match

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
- **ROUTING FIX + CITATION + PRA-CEK + ANTI-FALLBACK + TEMPLATE (VERIFIED)**
- **WORD-COUNT (VERIFIED 2026-07-01 21:27)**: `word_count` dihitung dari file jadi (bukan estimasi SPEC), ada di RenderResult + GateVerdict + JSON report run.py. PDF 793 words (exact match vs wc eksternal), DOCX 772 words. Jarvis baca dari JSON report, tidak nebak lagi. Joki-tugas- `a6dff05` + `d366824`.
- **ARSI loop**: run.py sengaja 1-pass, iterasi agent-driven. BY DESIGN, bukan bug.

## 3b. ACADEMIC-SEARCH (cari + saring + verifikasi sumber ilmiah)
- **Lokasi**: repo `jarvis`, `skills/academic-search/`. Deploy: `scripts/deploy_academic_search.sh` (no-restart).
- **Alur (VERIFIED)**: SEARCH multi-database -> KONSOLIDASI -> RELEVANCE FILTER (`relevance_filter.py`, stdlib, substring match ID) -> VERIFY DOI -> cite-only-verified.

## 4. STATUS PR (semua RAMPUNG per 2026-07-01)
- **Joki-tugas-**: PR #10 MERGED. PR #1-#6 CLOSED (arsip). **0 PR terbuka.** Commit langsung: `4fbf6c2`, `2324405`, `a6dff05`, `d366824`.
- **jarvis**: PR #2 merged. PR #3-#7 CLOSED sebagai superseded. **0 PR terbuka.**

## 5. STATUS KEMAMPUAN (terbukti)
- **jarvis-document-factory** PROVEN: routing, gate PASS, citation PPTX-aware, validate_spec, anti-fallback, template makalah 4 bab.
- **Relevance filter** PROVEN: selftest PASS, dummy 2 relevan/1 tangensial.
- **Word-count** PROVEN: PDF 793 exact match, DOCX 772. Jarvis baca dari JSON, nggak nebak.
- **Routing akademik, web-grounding, mistake-logger, PIPA4, humanizer** — PROVEN.

## 6. GAP / OPEN ITEMS (prioritas, evidence-based)
1. ~~RELEVANSI sumber~~ SELESAI + VERIFIED.
2. **action-gate v2 naik LIVE**: masih shadow; nunggu data organik + GO Arif.
3. ~~WORD-COUNT akurasi~~ SELESAI + VERIFIED (PDF 793 exact match, DOCX 772).
4. (opsional) **PDF presentasi landscape**: ekspor LibreOffice pasca-gate PPTX.
5. (opsional) **office-academic redundan**.

> Semua item kritis (validate, anti-fallback, template, relevance, word-count) VERIFIED live di Acer. Sisa: action-gate v2 LIVE (#2, nunggu GO Arif) + opsional #4, #5.

## 7. DEPLOY & ROLLBACK (tiap fitur, semua idempotent + backup)
Pola: `cd ~/<repo> && git checkout main && git pull && bash scripts/<deploy>.sh`.
- Skill factory: `cd ~/Joki-tugas- && bash jarvis_document_factory/deploy_document_factory.sh`
- Jarvis: `deploy_docfactory_routing.sh`, `deploy_anti_fallback.sh`, `deploy_academic_search.sh`, `deploy_academic_ppt_routing_fix.sh`, `deploy_web_search_ddgs.sh`, `deploy_mistake_logger.sh`, `deploy_pipa4_final_gate.sh`.
- Rollback: backup file. Kill-switch: MISTAKE_LOGGER_OFF, ACTION_GATE_MODE=off.

## 8. KALAU PAKAI AGENT SELAIN KIRO
- Skill produksi = repo Joki-tugas-. Tuning/infra/checkpoint = repo jarvis. Baca RESUME + CHECKPOINT + LANJUTAN + jarvis-conventions.
- Eksekusi tetap lewat Jarvis(Telegram)/SSH Arif. Observe-before-patch, patuhi konvensi.
