# RESUME / HANDOFF - Jarvis Tuning (sumber kebenaran tunggal)
_Update: 2026-07-01 (sesi lanjutan malam). Sesi baru (agent mana pun) tinggal baca file INI + HANDOFF_CHECKPOINT.md + HANDOFF_CHECKPOINT_2026-07-01_LANJUTAN.md + .kiro/steering/jarvis-conventions.md, langsung lanjut._

> Baca urutan: (1) file ini buat peta cepat, (2) HANDOFF_CHECKPOINT.md bagian 12.x + HANDOFF_CHECKPOINT_2026-07-01_LANJUTAN.md buat detail teknis, (3) .kiro/steering/jarvis-conventions.md buat aturan kerja.

---

## 0. TL;DR - di mana kita sekarang
Jarvis = AI assistant di server Acer (Hermes Gateway, Telegram interface, model via 9router). Fokus sesi-sesi terakhir = TUNING biar Jarvis jadi agent joki-kuliah/akademik yang andal. Semua perubahan = lapis SOFT (skill/plugin/direktif USER.md), idempotent, ada rollback.

MILESTONE (2026-07-01): skill **jarvis-document-factory** SELESAI + 4 PIPA TERSAMBUNG (PIPA1-3 skills + PIPA4 auto-wiring). Semua PR merged. 6 item VERIFIED live di Acer.

SESI LANJUTAN (2026-07-01 malam): **6 ITEM VERIFIED:**
1. ✅ validate_spec.py — validator pra-render (EXIT=0)
2. ✅ ANTI-FALLBACK — larangan freehand (deploy exit 0)
3. ✅ Contoh makalah 4 bab — template SPEC (gate PASS PDF+DOCX 8 hal)
4. ✅ Relevance filter — saring sumber tangensial (selftest PASS)
5. ✅ Word-count — dihitung dari file jadi (PDF 793 exact match)
6. ✅ PIPA4 auto-wiring — council auto-picu setelah factory gate PASS (hook loaded True, fail-open OK, kill-switch work)

SEMUA 4 PIPA TERSAMBUNG: PIPA1-3 (skills advisory) + PIPA4 (gate factory + council auto-hook).

## 1. CARA KERJA INFRA
- Server: Acer `arif-aspire-5551` (Tailscale). Agent cloud TIDAK di tailnet -> eksekusi di Acer via Jarvis/SSH Arif.
- Live: `~/.hermes/`. Repo `jarvis` = source skrip + handoff + infra (pipa4_hook.py, deploy scripts). Repo `Joki-tugas-` = factory skill.
- Gateway: proses `hermes_cli.main gateway run`. Restart ~210s. Skill/direktif = /new, no restart. Plugin BARU = restart.

## 2. ATURAN KERJA (jarvis-conventions.md)
VERDICT format, evidence-first, observe-before-patch, anti-False-READY, anti-over-engineering, SOFT vs HARD, humanizer default.

## 3. JARVIS-DOCUMENT-FACTORY (skill produksi utama)
- **Kode**: repo `Joki-tugas-`, `jarvis_document_factory/`. Deploy: `bash jarvis_document_factory/deploy_document_factory.sh`
- **Prinsip**: Structure-Before-Render, gate 7-cek deterministik = DONE, reuse render_deck+humanizer.
- **Render**: PDF (WeasyPrint A4) + DOCX (python-docx) + PPTX (render_deck 16:9).
- **PIPA4 AUTO-WIRING (VERIFIED 2026-07-01 22:03)**: Setelah factory gate PASS + `is_academic=true` → auto-picu PIPA4 council (`pipa4_gate.sh`, LLM audit jarvis-reason). Hook di `~/.hermes/scripts/pipa4_hook.py` (repo jarvis/scripts/). Factory import via dynamic `_load_pipa4_hook()` — fail-open (PIPA4 gak ada → skip). Kill-switch: `PIPA4_AUTO=off` (default).

## 3b. ACADEMIC-SEARCH (cari + saring + verifikasi, VERIFIED)

## 4. 4 PIPA — STATUS KONEKSI (VERIFIED)
- **PIPA1-3**: skills advisory (pipa-routing, neuro-arc, arsi-doctrine) — VERIFIED behavioral
- **PIPA4 gate factory**: 7 cek deterministik (structure, citation, humanizer, blank, dangling, toc, images) — VERIFIED PASS
- **PIPA4 council**: LLM audit via jarvis-reason (phase6a+6c+6d) — VERIFIED manual, now AUTO-WIRED via hook

## 5. STATUS KEMAMPUAN (semua PROVEN/VERIFIED)
- Document factory: validate + anti-fallback + template + word-count (793 exact) + PIPA4 hook (fail-open)
- Academic-search: relevance filter + verify DOI
- Routing akademik, web-grounding, mistake-logger, PIPA4 council swap, humanizer, dual-output

## 6. GAP / OPEN ITEMS
1. ~~RELEVANSI sumber~~ VERIFIED
2. ~~WORD-COUNT~~ VERIFIED
3. ~~PIPA4 auto-wiring~~ VERIFIED (hook loaded True, fail-open, kill-switch work)
4. **action-gate v2 naik LIVE** — shadow, nunggu data + GO Arif
5. (opsional) PDF presentasi landscape, office-academic redundan
6. **BELUM (checkpoint 9.x)**: brand gate constraint profile, NLI router auto-invoke, model re-verify, restart-hang fix, multimodal intake, cleanup buku PKN, memory persistence, D-hard router (tunda)

## 7. DEPLOY & ROLLBACK
- Skill factory: `cd ~/Joki-tugas- && git pull && bash jarvis_document_factory/deploy_document_factory.sh`
- PIPA4 hook: `cp -f ~/jarvis/scripts/pipa4_hook.py ~/.hermes/scripts/pipa4_hook.py && chmod +x ~/.hermes/scripts/pipa4_hook.py`
- Deploy scripts: `deploy_docfactory_routing.sh`, `deploy_anti_fallback.sh`, `deploy_academic_search.sh`, `deploy_pipa4_final_gate.sh`, dll.
- Rollback: backup file. Kill-switch: PIPA4_AUTO=off, MISTAKE_LOGGER_OFF, ACTION_GATE_MODE=off.

## 8. KALAU PAKAI AGENT LAIN
- Skill produksi = Joki-tugas-, tuning/infra/PIPA4 = jarvis. Baca RESUME + CHECKPOINT + LANJUTAN + jarvis-conventions.
