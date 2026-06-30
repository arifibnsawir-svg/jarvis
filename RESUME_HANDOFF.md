# RESUME / HANDOFF — Jarvis Tuning (sumber kebenaran tunggal)
_Update: 2026-06-30. Dibuat biar sesi baru (Kiro ATAU agent lain) tinggal baca file INI + HANDOFF_CHECKPOINT.md, langsung lanjut._

> Baca urutan: (1) file ini buat peta cepat, (2) HANDOFF_CHECKPOINT.md bagian 12.x buat detail teknis tiap langkah, (3) .kiro/steering/jarvis-conventions.md buat aturan kerja.

---

## 0. TL;DR — di mana kita sekarang
Jarvis = AI assistant di server Acer (Hermes Gateway, Telegram interface, model via 9router). Sesi-sesi terakhir = TUNING biar Jarvis jadi agent joki-kuliah/akademik yang andal. Roadmap A/B/C/D + wiring PIPA SELESAI dibangun & sebagian besar TERBUKTI. Semua perubahan = lapis SOFT (skill/plugin/direktif USER.md), idempotent, ada rollback. Yang tersisa = poles kualitas (relevansi sumber) + konsolidasi + 1 ide besar (skill dari deliverable joki yang sudah PASS).

## 1. CARA KERJA INFRA (penting buat agent mana pun)
- Server: Acer `arif-aspire-5551` (Tailscale). Kiro/agent cloud **TIDAK** di tailnet -> SEMUA eksekusi di Acer lewat **Jarvis (Telegram)** atau SSH oleh Arif. Agent cuma nulis kode/skrip ke repo; Arif/Jarvis yang jalanin di Acer lalu paste output balik.
- Live system di Acer: `~/.hermes/` (skills/, plugins/, scripts/, pipelines/, memories/USER.md, config.yaml). Repo `arifibnsawir-svg/jarvis` = working copy + sumber skrip (BUKAN sistem hidup).
- Gateway messaging = proses `hermes_cli.main gateway run` (BUKAN port 9119 itu DASHBOARD). Verify gate-liveness via behavioral (log/decisions.jsonl), bukan PID listener 9119.
- Restart gateway ~210s (berat). Skill/direktif USER.md = aktif di sesi BARU (/new) TANPA restart. Plugin BARU = butuh restart (discover saat startup) + opt-in di config.yaml `plugins.enabled`.
- Model council/reasoning = combo `jarvis-reason` (via guardian_router port 20129). TERBUKTI sehat.
- JANGAN tulis API key mentah. JANGAN restart/edit config core tanpa approval Arif.

## 2. ATURAN KERJA (jarvis-conventions.md — wajib dipatuhi)
VERDICT format (FAKTA TERBUKTI/BELUM TERBUKTI/RISIKO/NEXT) · evidence-first (jangan klaim tanpa bukti command) · observe-before-patch (baca dulu, jangan nebak) · anti-False-READY (LLM gak boleh deklarasi DONE, itu wewenang gate) · anti-over-engineering (ingetin Arif "udah cukup") · SOFT vs HARD (PIPA1-3 = skill, PIPA4 = gate) · humanizer DEFAULT semua artefak (no em-dash/kutip keriting/emoji).

## 3. YANG SUDAH DIBANGUN SESI INI (7 PR, semua pushed)
| PR | Branch | Isi | Status |
|----|--------|-----|--------|
| #2 | feat/action-gate-v2-plugin | action-gate v2 (shadow) + checkpoint 12.14-12.24 | **MERGED ke main** |
| #3 | fix/academic-ppt-routing | routing akademik: PPT->render_deck (anti pptxgenjs crash) | pushed, deployed Acer, **belum merge** |
| #4 | feat/web-search-ddgs | search_backend=ddgs (no-key) buat web umum | pushed, deployed Acer, **belum merge** |
| #5 | feat/academic-search | skill cari+verify sumber ilmiah (multi-DB+Scholar+verify DOI) | pushed, deployed Acer, **belum merge** |
| #6 | feat/mistake-logger | plugin post_tool_call -> auto-log error ke LESSONS.md | pushed, deployed+restart, **PROVEN live**, belum merge |
| #7 | feat/pipa4-final-gate | pipa4_gate.sh + direktif gate wajib final akademik | pushed, deployed Acer, belum merge |
| (ini) | chore/consolidate-handoff | gabung semua file + checkpoint 12.25-12.29 + RESUME ini | konsolidasi |

> CATATAN MERGE: PR #3-#7 di-branch dari main yang sama -> kalau merge satu-satu bakal konflik di HANDOFF_CHECKPOINT.md (semua append di ekor). **Branch `chore/consolidate-handoff` ini sudah berisi SEMUA kode + checkpoint urut** -> merge INI saja sudah bawa semuanya ke main (paling bersih). Atau merge #3->#4->#5->#6->#7 berurutan + resolve konflik checkpoint (keep semua section).

## 4. STATUS KEMAMPUAN (terbukti vs belum)
- **Routing akademik** ✅ PROVEN: PPT sidang -> render_deck (bukan pptxgenjs). Bug "academic-document-factory DOCX-only" sudah dipisah via direktif PIPA4... lihat 12.25.
- **Web-grounding** ✅ PROVEN: academic-search pakai OpenAlex/Crossref (no-key) -> sumber Indonesia ASLI + DOI resolve; verify_citations nolak DOI halu. Google Scholar (scholarly) best-effort.
- **mistake-logger** ✅ PROVEN LIVE: auto-log error read_file ke LESSONS.md (17:28).
- **PIPA4 gate** ✅ engine sehat (audit+council jarvis-reason+deterministik), pipa4_gate.sh wrapper proven; ⚠️ caveat: page-count DOCX "not implemented" -> render PDF dulu buat hitung halaman (lihat 12.29 + GAP).
- **humanizer** ✅ default semua artefak (USER.md). ⚠️ ada 2 humanizer (ambiguous) -> load pakai path eksplisit `~/.hermes/skills/humanizer/SKILL.md`.

## 5. GAP / OPEN ITEMS (prioritas, evidence-based)
1. **RELEVANSI sumber (kualitas joki #1)**: academic-search verify "DOI resolve" tapi BELUM cek relevansi topik. Tes makalah gaya-belajar: 4/6 sumber TANGENSIAL (resiliensi/motivasi/SRL, bukan gaya belajar). FIX: filter relevansi (judul/abstract wajib match kata kunci inti), sumber tangensial -> "pendukung" bukan inti. (PIPA4 sudah flag NEEDS_EVIDENCE_REVIEW = benar.)
2. **IDE BESAR (rekomendasi Arif)**: distill skill dari deliverable joki yang SUDAH PASS (repo `arifibnsawir-svg/Joki-tugas-`: aturan-buku-pkn.md + _generator WeasyPrint/python-docx + qa_*.py PASS/FAIL). Bikin skill `academic-deliverable-method` (multi-mode: mini-book/modul/makalah/laporan). Resep proven mereka HITUNG HALAMAN DARI PDF (pypdf) = solusi gap page-count PIPA4. STATUS: Arif lagi ngerapiin sumbernya; tunggu aba-aba "gas distill".
3. **PIPA4 gate semantics DOCX**: NEEDS_RENDER_AUDIT (page-count caveat) harus jadi advisory, bukan blocker; blocker = placeholder/struktur/evidence. Render PDF buat page-count.
4. **action-gate v2 naik LIVE**: masih shadow; nunggu data organik + keputusan interpreter + GO Arif.
5. **Word-count akurasi**: Jarvis suka misreport panjang (klaim 1264 vs aktual 919 kata) -> verify via wc/PDF, jangan percaya klaim LLM.
6. **Housekeeping**: merge PR (lihat #3) ; office-academic-skill redundan (boleh hapus, pakai academic-document-factory) ; em-dash marker render_deck (kalau humanizer mau super-strict).

## 6. NEXT SAFE ACTION (buat sesi/agent berikut)
1. (housekeeping) Merge `chore/consolidate-handoff` ke main -> repo lengkap + checkpoint utuh.
2. Tunggu Arif kelar rapiin repo `Joki-tugas-` -> distill skill `academic-deliverable-method` dari resep PROVEN (aturan + pipeline WeasyPrint/docx + QA gate PASS/FAIL + DNA anti-Turnitin + 2 format). Ini nyatuin academic-search/humanizer/gate di bawah 1 metode terbukti + mecahin gap relevansi & page-count.
3. (opsional) relevance filter academic-search ; PIPA4 gate advisory-fix.
JANGAN nambah fitur baru sebelum konsolidasi + distill joki-method beres (anti-over-engineering).

## 7. DEPLOY & ROLLBACK (tiap fitur, semua idempotent + backup)
Pola: `cd ~/jarvis && git fetch origin && git checkout <branch> && git pull && bash scripts/<deploy>.sh`. Skrip:
- `deploy_academic_ppt_routing_fix.sh` (USER.md direktif) · `deploy_web_search_ddgs.sh` (config.yaml core, butuh approval) · `deploy_academic_search.sh` (skill+pip requests/scholarly+USER.md) · `deploy_mistake_logger.sh` (plugin+config.yaml enable, butuh RESTART) · `deploy_pipa4_final_gate.sh` (helper+USER.md).
- Rollback tiap skrip cetak path backup (`USER.md.bak.<ts>` / `config.yaml.bak.<ts>`) + cara revert. Kill-switch mistake-logger: `MISTAKE_LOGGER_OFF=1`. Kill-switch action-gate: `ACTION_GATE_MODE=off`.

## 8. KALAU PAKAI AGENT SELAIN KIRO
- Repo `arifibnsawir-svg/jarvis` = semua skrip/skill/plugin + checkpoint. Clone, baca file ini + HANDOFF_CHECKPOINT.md (12.x) + jarvis-conventions.md.
- Eksekusi tetap lewat Jarvis(Telegram)/SSH Arif (agent cloud gak di tailnet Acer).
- Patuhi konvensi (§2). Observe-before-patch: SELALU baca state Acer (skrip inspect read-only) sebelum patch. Jangan percaya checkpoint lama buat status infra -> verify ulang dengan command.
