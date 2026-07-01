# RESUME / HANDOFF - Jarvis Tuning (sumber kebenaran tunggal)
_Update: 2026-07-01 (sesi lanjutan malam). Sesi baru (agent mana pun) tinggal baca file INI + HANDOFF_CHECKPOINT.md + HANDOFF_CHECKPOINT_2026-07-01_LANJUTAN.md + .kiro/steering/jarvis-conventions.md, langsung lanjut._

> Baca urutan: (1) file ini buat peta cepat, (2) HANDOFF_CHECKPOINT.md bagian 12.x + HANDOFF_CHECKPOINT_2026-07-01_LANJUTAN.md buat detail teknis, (3) .kiro/steering/jarvis-conventions.md buat aturan kerja.

---

## 0. TL;DR - di mana kita sekarang
Jarvis = AI assistant di server Acer (Hermes Gateway, Telegram interface, model via 9router). Fokus sesi-sesi terakhir = TUNING biar Jarvis jadi agent joki-kuliah/akademik yang andal. Semua perubahan = lapis SOFT (skill/plugin/direktif USER.md), idempotent, ada rollback.

MILESTONE (2026-07-01): skill **jarvis-document-factory** SELESAI + semua PR merged. 5 item VERIFIED live di Acer. PIPA4 auto-wiring **COMMITTED** (PENDING deploy+verify).

SESI LANJUTAN (2026-07-01 malam): **5 ITEM VERIFIED + 1 ITEM COMMITTED:**
1. ✅ validate_spec.py
2. ✅ ANTI-FALLBACK
3. ✅ Contoh makalah 4 bab (template)
4. ✅ Relevance filter (#1)
5. ✅ Word-count (#3)
6. 🔄 PIPA4 auto-wiring — COMMITTED (Joki-tugas- `bea2083`), PENDING deploy+verify di Acer

## 1. CARA KERJA INFRA
- Server: Acer `arif-aspire-5551` (Tailscale). Agent cloud TIDAK di tailnet -> eksekusi di Acer via Jarvis/SSH Arif.
- Live: `~/.hermes/`. Repo `jarvis` = source skrip + handoff. Repo `Joki-tugas-` = factory skill.
- Gateway: proses `hermes_cli.main gateway run`. Restart ~210s. Skill/direktif = /new, no restart. Plugin BARU = restart.

## 2. ATURAN KERJA (jarvis-conventions.md)
VERDICT format, evidence-first, observe-before-patch, anti-False-READY, anti-over-engineering, SOFT vs HARD, humanizer default.

## 3. JARVIS-DOCUMENT-FACTORY
- **Kode**: repo `Joki-tugas-`, folder `jarvis_document_factory/`. Deploy: `bash jarvis_document_factory/deploy_document_factory.sh`.
- **Prinsip**: Structure-Before-Render, gate deterministik = DONE, reuse render_deck+humanizer, anti-halu gambar.
- **Render**: PDF (WeasyPrint A4) + DOCX (python-docx) + PPTX (render_deck 16:9). Gate 7-cek.
- **VERIFIED**: routing fix, citation PPTX-aware, validate_spec, anti-fallback, contoh makalah, word-count (PDF 793 exact match).
- **PIPA4 AUTO-WIRING (BARU, COMMITTED, PENDING VERIFY)**: Setelah factory gate PASS + `is_academic=true` → auto-trigger PIPA4 council (`pipa4_gate.sh`, LLM audit via jarvis-reason). Fail-open (PIPA4 gak ada → skip graceful). Kill-switch: `PIPA4_AUTO=off`. Joki-tugas- `bea2083`.

## 3b. ACADEMIC-SEARCH (VERIFIED)
- Search multi-DB → relevance filter → verify DOI → cite-only-verified.

## 4. STATUS PR
- **0 PR terbuka** di kedua repo.

## 5. STATUS KEMAMPUAN
- Document factory: PROVEN (validate, anti-fallback, template, word-count, gate PASS).
- Academic-search: PROVEN (relevance filter, verify DOI).
- Routing akademik, web-grounding, mistake-logger, PIPA4 council swap, humanizer: PROVEN.
- PIPA4 auto-wiring: COMMITTED (PENDING verify).

## 6. GAP / OPEN ITEMS
1. ~~RELEVANSI sumber~~ VERIFIED
2. **action-gate v2 naik LIVE** — shadow, nunggu data + GO Arif
3. ~~WORD-COUNT~~ VERIFIED
4. ~~PIPA4 auto-wiring~~ COMMITTED (PENDING verify)
5. (opsional) PDF presentasi landscape, office-academic redundan
6. **BELUM dari checkpoint**: brand gate constraint profile, NLI router auto-invoke, model re-verify, restart-hang fix, multimodal intake, cleanup buku PKN, memory persistence, D-hard router (tunda)

## 7. DEPLOY & ROLLBACK
- Skill factory: `cd ~/Joki-tugas- && git pull && bash jarvis_document_factory/deploy_document_factory.sh`
- Jarvis scripts: `deploy_docfactory_routing.sh`, `deploy_anti_fallback.sh`, `deploy_academic_search.sh`, `deploy_action_gate.sh`, `deploy_pipa4_final_gate.sh`, dll.
- Rollback: backup USER.md/config.yaml. Kill-switch: MISTAKE_LOGGER_OFF, ACTION_GATE_MODE=off, PIPA4_AUTO=off.

## 8. KALAU PAKAI AGENT LAIN
- Skill produksi = Joki-tugas-, tuning/infra = jarvis. Baca RESUME + CHECKPOINT + LANJUTAN + jarvis-conventions.
