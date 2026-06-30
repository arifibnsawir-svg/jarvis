# JARVIS / HERMES — SESSION HANDOFF CHECKPOINT
_Dibuat: 2026-06-27 · Sumber kebenaran buat lanjut di sesi Kiro baru._

> CARA PAKAI: di sesi Kiro baru, paste isi file ini di pesan pertama (atau simpan di Acer / repo GitHub lo). Kiro gak inget antar-sesi — dokumen ini memorinya.

---

## 0. RINGKASAN 1 PARAGRAF
Jarvis = AI assistant di server Acer, framework Hermes Gateway (Telegram), pakai 9router sebagai model gateway. Sesi ini: verifikasi 16 provider, bikin 6 combo, swap otak gateway dari `DailyFree` ke `jarvis-agent` (hang 21menit→5menit), desain arsitektur NEURO-ARC/ARSI/GUARDIAN, dan coba bangun NLI router plugin (BELUM kelar — hook gak ke-invoke, lihat Bagian 7). Phase berikutnya: pivot ke skill ATAU benerin hook, lalu PIPA 1-3 + brand gate.

---

## 1. PETA SISTEM (Acer)
- Server Jarvis: hostname `arif-aspire-5551` (Tailscale). Laptop chat = "Balqis laptop" (`100.96.122.82`), di tailnet sama.
- **Kiro (cloud) GAK ada di tailnet** — gak bisa akses Acer langsung. Semua eksekusi lewat Jarvis (Telegram) atau SSH oleh user.
- Ports:
  - `9119` = Hermes Gateway (dashboard + service)
  - `20128` = 9router (manual, systemd disabled karena restart-loop — terminal jangan ditutup)
  - `20129` = Guardian (health/circuit-breaker monitor — BUKAN brand gate)
- Paths penting:
  - Gateway core: `~/.hermes/hermes-agent/gateway/run.py` (~18rb baris)
  - Config: `~/.hermes/config.yaml` (key `model.default`)
  - Runtime model resolve: `~/.hermes/hermes-agent/hermes_cli/runtime_provider.py:228` (baca `model_cfg.get("default")`)
  - Plugin loader: `~/.hermes/hermes-agent/hermes_cli/plugins.py`
  - Plugins: `~/.hermes/plugins/` (pipa4_review, pipa4_bridge_plugin, command-plane-v0, nli_router)
  - PIPA4: `~/.hermes/pipelines/pipa4/phase7a/pipa4_review_local.py`
  - Constraints: `~/.hermes/pipelines/pipa4/constraints/academic_book.json`, `phase5c/constraint_mini_book_pkn.json`

## 1b. RESTART / RELOAD (penting — pernah nyiksa)
- `systemctl --user restart hermes-gateway` → **NYANGKUT ~210s** ("deactivating") karena `TimeoutStopSec=210` + proses gak exit cepat di SIGTERM. Recover sendiri, tapi lama.
- **Workaround**: `kill -9 <PID port 9119>` lalu `systemctl --user start` (atau auto-restart). Balik ~15s.
- `systemctl --user reload` = SIGUSR1 = graceful, ~5s — TAPI gak rediscover plugin baru (cuma config). 
- `load_config()` cached by mtime/size → **edit config.yaml auto-kebaca** request berikutnya, gak perlu restart.
- **TODO follow-up**: turunin `TimeoutStopSec` 210→15 di systemd unit biar restart gak nyiksa.

---

## 2. 9ROUTER — PROVIDER (16 connected, verified)
> KEYS TIDAK DITULIS DI SINI (security). Keys ada di 9router dashboard (Acer) + router key di env `NINEROUTER_KEY`/`ROUTER_KEY`. Endpoint: `http://arif-aspire-5551:20128/v1`.

Prefix → provider:
`groq` Groq · `qwen` Qwen Official · `cerebras` Cerebras · `mistral` Mistral · `cf` Cloudflare(@cf/...) · `kr` Kiro(free unlimited) · `cx` OpenAI Codex(OAuth) · `gh` GitHub Copilot(OAuth) · `gemini` Google AI Studio · `smb` SambaNova · `mimo` Xiaomi MiMo(token beli) · `nv`/`nv2` NVIDIA NIM(2 key) · `nvidia` NVIDIA custom(6 model) · `ag` Antigravity · `Nara` Naraya(paid/402)

Catatan provider:
- `gh/` (Copilot): CUMA `gpt-4o`, `gpt-4o-mini`, `gpt-4.1` jalan. Claude/gpt-5/gemini via gh = 400.
- `cx/` (Codex): `gpt-5.5`, `gpt-5.4`(+mini/review) jalan. `gpt-5.3-codex` = 400.
- `ag/` (Antigravity): `claude-opus-4-6-thinking` 5/5 STABIL. `claude-sonnet-4-6` flaky(hang). **Semua `ag/gemini-*` MATI (timeout)**. RISIKO BAN kalau di-proxy — user pakai di CLI native aja; di 9router cuma break-glass.
- `nv`/`nv2`: ~37 model jalan tiap-tiap, banyak 404 (model gak diserve free tier). Hindari yg latency >5s.
- `Nara`: kebanyakan 402 (butuh top-up) — skip.
- **JANGAN PAKAI** (biang lemot, >10-30s): `*/minimax-m2.7`, `nv/google/gemma-4-31b-it`(33s), `nv/deepseek-v4-flash`(28s), `cf/gpt-oss-120b`(10s), `openrouter/laguna-m.1`(24s).

## 2b. MODEL TERCEPAT (verified, buat referensi)
qwen/qwen-flash 214ms · groq/llama-3.1-8b-instant 224ms · qwen/qwen3-30b-a3b-instruct-2507 234ms · qwen/qwen-turbo 283ms · nv/meta/llama-3.1-8b-instruct 342ms · groq/llama-4-scout 350ms · qwen/qwen3-235b-a22b-instruct-2507 362ms(!) · mistral/codestral 456ms · groq/llama-3.3-70b-versatile 452ms · qwen/qwen3-235b-a22b-thinking-2507 617ms(!) · qwen/qwen3-coder-480b 830ms

---

## 3. COMBO (dibuat di dashboard — dashboard = sumber kebenaran)
> Round Robin: ON = load-balance (model selatency), OFF = priority fallback (kepastian).

**jarvis-agent** (RR OFF) — OTAK GATEWAY DEFAULT:
```
kr/claude-sonnet-4.5-agentic
cx/gpt-5.5
qwen/qwen3-235b-a22b-instruct-2507
kr/claude-sonnet-4.5
groq/llama-3.3-70b-versatile
```
**jarvis-fast** (RR ON) — triage/chat/router-classify:
```
groq/llama-3.1-8b-instant, qwen/qwen-flash, qwen/qwen3-30b-a3b-instruct-2507, qwen/qwen-turbo,
nv/meta/llama-3.1-8b-instruct, groq/meta-llama/llama-4-scout-17b-16e-instruct,
mistral/ministral-8b-latest, cf/@cf/meta/llama-3.1-8b-instruct-fp8-fast,
gemini/gemini-3.1-flash-lite-preview, gh/gpt-4o-mini
```
**jarvis-coder** (RR OFF):
```
cx/gpt-5.5, qwen/qwen3-coder-480b-a35b-instruct, cerebras/zai-glm-4.7,
mistral/codestral-latest, kr/qwen3-coder-next, cf/@cf/qwen/qwen2.5-coder-32b-instruct
```
**jarvis-reason** (RR OFF) — R3 extract + R6 audit:
```
kr/claude-sonnet-4.5-thinking, qwen/qwen3-235b-a22b-thinking-2507,
ag/claude-opus-4-6-thinking  (#3 break-glass, jarang kepukul = akun aman),
cx/gpt-5.5, qwen/qwen3-235b-a22b-instruct-2507, groq/llama-3.3-70b-versatile,
cf/@cf/qwen/qwq-32b, mimo/mimo-v2.5-pro
```
**jarvis-longform** (RR OFF) — R4 writer + R7 digest:
```
kr/claude-sonnet-4.5, qwen/qwen3-max, gemini/gemini-3-flash-preview, mimo/mimo-v2.5-pro,
gh/gpt-4o, mistral/mistral-large-latest, kr/glm-5, smb/DeepSeek-V3.2
```
**jarvis-bulk** (RR ON) — kerja volume/internal (rumah token MiMo beli):
```
mimo/mimo-v2.5-pro, mimo/mimo-v2.5, mimo/mimo-v2-flash,
nvidia/minimaxai/minimax-m3, qwen/glm-5.2, qwen/qwen3-30b-a3b-instruct-2507, smb/DeepSeek-V3.2
```

---

## 4. CONFIG CHANGE — SUDAH DONE ✅
`~/.hermes/config.yaml` → `model.default: jarvis-agent` (dari `DailyFree`). Backup ada (`config.yaml.bak.*`).
Bukti: `/new` banner nunjukin "Model: jarvis-agent, Provider: custom (9router), Context: 256K". Benchmark tugas berat 5 menit/18 iterasi (dulu 21 menit/stuck).
> TODO terpisah: PIPA4 mini-council masih hardcode `model='DailyFree'` di `phase6a/6c/6d` + `phase7a/pipa4_review_local.py:104`. Ganti ke `jarvis-reason` nanti.

---

## 5. ARSITEKTUR (keputusan locked)
- **NEURO-ARC** = lapis representasi/berpikir: narasi→entitas→ukuran→relasi→output. Dipakai SEBELUM eksekusi. = schema TaskState.
- **A.R.S.I** = lapis eksekusi (4 PIPA): Audit→Rancang→Sistemasi→Iterasi. Ini "arsi engine".
- **GUARDIAN** = gate deterministik (PIPA4). Authority "DONE" CUMA di sini. (Guardian lama user = niatnya smart-router+filter, tapi jadi over-blocking → diturunin. Pelajaran: PISAH router(ringan, gak blok input) dari gate(minimal, di output saja)).
- **SOFT vs HARD**: PIPA1-3 = soft (agent+combo, boleh skill). PIPA4 gate = hard (Python, deterministik, gak bisa ditawar).
- **SAKLAR KONTEKS**: target `internal_research`/`code_patching` → gate BYPASS (boleh ngobrol liar sacred IP). `public_social`/`book_draft` → gate NYALA.
- **Brand gate** (sacred IP/voice/hype) → jadi CONSTRAINT PROFILE di PIPA4 (artifact_type: social_post), BUKAN engine baru. JANGAN dinamai "Guardian" (bentrok service 20129).
- **Renderer**: "Structure Before Render" — LLM keluarin spec JSON → python-pptx/python-docx bikin file → gate verify. Gambar wajib via model image asli + verify file ada.
- **9 router branch → map ke combo**: R1 triage→fast, R2 code→coder, R3 extract→reason(temp0+json), R4 writer→longform, R5 gate→PIPA4(no LLM), R6 audit→reason(thinking), R7 digest→longform, R8 vision→(deferred), R9 memory→fast+embedding.

## 5b. Kode arsitektur (ada di workspace sesi ini, di /projects/sandbox/jarvis/ — TIDAK persist ke Acer; perlu re-create atau push GitHub):
- `state/task_state.py` (TaskState blackboard + authority enforcement) — TESTED
- `state/capsule.py` (context capsule anti-bloat, role-scoped) — TESTED
- `guardian/guardian.py` + `guardian/brand_rules.json` (brand gate config-driven + saklar konteks) — TESTED
- `renderer/spec_schema.py` + `render_pptx.py` + `render_docx.py` — TESTED (bikin file PPTX/DOCX asli)
- `router/router.py` + `router/exemplars.py` (cascade L0/L1/L2) — skeleton
- `router_config.yaml` / `.json` (9 branch + combo mapping)
- Embedding L1 = `paraphrase-multilingual-MiniLM-L12-v2` (multilingual, BUKAN BGE-en). Vector store = SQLite + sqlite-vec. Threshold 0.75 + margin 0.10.

---

## 6. PIPA STATUS
- PIPA4 = engine NYATA + plugin Telegram `/pipa4-review-dryrun <pdf> <constraint>` + gate deterministik. JALAN. (audit Mini_Book PKN: NEEDS_TEXT_CLEANUP, 46.939 flag `[placeholder]`, urgent_buzzword 6x).
- PIPA 1-3 = workflow proven (manual/semi), TAPI belum ada engine otomatis. Rencana: skill + combo, BUKAN bangun 4 engine.

---

## 7. NLI ROUTER PLUGIN (nli_router) — STATUS: BUNTU di hook-invoke
Tujuan: NL "audit buku ini" + PDF → auto rewrite ke `/pipa4-review-dryrun` (deterministik).
- ✅ Kode plugin 100% SEHAT (isolated test: load, register, hook `pre_gateway_dispatch` keisi, no error). `register()` final: `ctx.register_hook("pre_gateway_dispatch", pre_gateway_dispatch)`.
- ✅ Butuh `plugin.yaml` manifest (loader discover via itu). File `__init__.py` (BUKAN init.py — markdown sering makan underscore).
- ✅ `pre_gateway_dispatch` ADA di VALID_HOOKS; `invoke_hook` baca `_manager._hooks` (registry sama).
- ❌ **MASALAH**: di gateway HIDUP, hook `REGISTERED` tapi `HOOK FIRED` GAK PERNAH muncul — buat plain text MAUPUN PDF. Kode invoke ada di `run.py:7543-7577` tapi gak kepanggil.
- 🔍 Dugaan utama: **singleton PluginManager mismatch** (plugin register di instance A, `_handle_message` baca instance B) ATAU `is_internal` flag ATAU handler beda. PENDING grep: cek `skip: reason`/`is_internal`/`invocation failed` di journalctl + apakah `_handle_message` kepanggil.
- Debug-file ada: `~/.hermes/nli_router_debug.log` (nulis REGISTERED/HOOK FIRED/REWRITE/NO MATCH).

### KEPUTUSAN PENDING (lanjut di sesi baru):
- **Agent udah routing audit→PIPA4 BENAR 3/3** dari natural language (tanpa plugin). Safety dijamin GATE (PIPA4), bukan routing.
- **Rekomendasi Kiro: PIVOT ke SKILL** (`pipa-routing` + `arsi-engine` + `neuro-arc-thinking`) — no restart, leverage agent, gate jamin safety. Plugin di-shelf (disable, jangan hapus) buat kalau-kalau butuh determinism absolut (auto-posting).
- ALT: kalau grep nunjukin fix sepele (is_internal/skip) → benerin plugin. Kalau singleton-mismatch → pivot.

---

## 8. QUIRKS / GOTCHA 9ROUTER & HERMES
- Combo 9router = SEQUENTIAL fallback (bukan "fusion"). "Fusion" itu fitur OpenRouter, bukan 9router.
- Round Robin ON di combo campur-kualitas = output gacha/lemot (ini biang DailyFree lemot dulu).
- 9router `/v1/models` punya endpoint terpisah: `/models/image` `/models/tts` `/models/stt` `/models/embedding` `/models/image-to-text` `/models/web`.
- Response field `model` kadang kosong tergantung provider (cx isi, kr/mimo kosong) — bukan error.
- Reasoning model (cerebras gpt-oss, mimo) taruh output di `reasoning`/`reasoning_content`, content bisa kosong kalau max_tokens kecil → set max_tokens >=200 buat test.
- Jarvis (agent) kadang MISREPORT saat audit infra (pernah: port 20129 vs 9119; "register crash" padahal kode gak crash). Verifikasi infra sensitif via eksekusi langsung, jangan cuma ringkasan agent.
- Plugin loading log = DEBUG level, gak nongol di journalctl INFO standar.

---

## 9. OPEN ITEMS / NEXT (prioritas)
1. [PENDING] Selesaikan keputusan NLI router: grep invoke-path → fix sepele ATAU pivot skill.
2. Re-verify model 9router yang "gak jalan" (lihat Bagian 10) — model bisa stale (provider deprecate/quota).
3. Bikin skill ARSI/NEURO-ARC/pipa-routing (butuh contoh skill existing sebagai template: `evidence-claim-status-guard` / `llm-gateway-debugging`).
4. PIPA4: ganti hardcode `DailyFree`→`jarvis-reason` di mini-council scripts.
5. Brand gate sebagai PIPA4 constraint profile (social_post) — butuh: daftar signature phrase, sacred IP (847.000/347 prompt/Februari 2024/340%/Neuro-Arc/A.R.S.I — time-bound, matikan pas buku rilis), anti-hype, voice DINAMIS dari ukuran.
6. Renderer PPTX/DOCX wiring ke PIPA2 (+ PDF nanti).
7. Fix restart-hang permanen (TimeoutStopSec 210→15).
8. Multimodal intake (vision/STT) — test `/v1/models/image-to-text` & `/v1/models/stt` dulu.
9. Cleanup buku: 46.939 `[placeholder]` noise + variasiin "sangat penting" 6x di Mini_Book PKN.

## 10. MODEL "GAK JALAN" — RE-VERIFY DI SESI BARU
User lapor beberapa model di dashboard gak jalan. Model BISA stale (deprecate/quota reset). Sesi baru: jalanin ulang test (PowerShell smoke test per provider — script ada di sesi ini, atau `curl /v1/models` + ping per model). Update combo: buang model mati, ganti dari pool verified (Bagian 2b). Cek khusus: `ag/gemini-*` (mati), `Nara/*` (402), `*/minimax-m2.7` (jangan dipakai), `nv/*` yg >5s.

## 11. SECURITY
- JANGAN tulis API key mentah di mana pun (chat/doc/repo). Keys hidup di 9router dashboard (Acer) + env.
- Router key fragment pernah ke-paste di chat (`sk-ef2ad2c...`) → ROTATE kalau belum.
- `brand_rules.json` isinya sacred IP → repo PRIVATE kalau di-push.
- Jangan ngakalin moderation Kiro (pernah kena false-positive saat upload screenshot bertubi — pakai teks ringkas, bukan evasion).


---

## 12. ADDENDUM SESI 2026-06-27 (lanjutan — keputusan terkunci)
_Ditulis Kiro sesi grounding-2. Nge-overtake beberapa poin di atas. Sumber kebenaran terbaru._

### 12.1 Status update (nge-overtake Bagian 5b & 7)
- **Bagian 5b RESOLVED**: kode arsitektur UDAH ke-push ke repo `arifibnsawir-svg/jarvis` (17 file, ke-clone OK). Bukan lagi "perlu push".
- **Bagian 7 OVERTAKEN**: hook `nli_router` SEKARANG **FIRED** (lapor Jarvis). Dugaan "singleton mismatch" TUMBANG.
  - Gap REAL pindah ke **media-ingestion**: PDF mendarat di `~/.hermes/cache/documents/` TAPI gak masuk `event.media_urls` (`media=[], doc=None, intent=True`). Bukan masalah hook.
  - Status: Jalur B (fix media_urls) = DEFER. Belum kebukti sepele (perlu grep run.py:7543-7577 + extractor). Auto-route = nice-to-have, bukan blocker (audit manual PIPA4 jalan).
- **PIPA4 live** (phase7a/pipa4_review_local.py) ≠ guardian.py repo — by design. guardian.py = prototipe brand-gate; live = gate audit dokumen. Audit buku V4 = NEEDS_STRUCTURE_CLEANUP + NEEDS_EVIDENCE_REVIEW (production_ready=False -> gate nahan = anti-False-READY bekerja).

### 12.2 Terminologi TERKUNCI (jangan dicampur lagi)
- **A.R.S.I = ATURAN** (doktrin/hukum cara kerja: Audit->Rancang->Sistemasi->Iterasi). Dipatuhi, gak "jalan".
- **arsi engine = MESIN** (runtime/kode yang MENJALANKAN aturan A.R.S.I di atas TaskState). Punya PID, hidup/mati.
- **NEURO-ARC = lapis REPRESENTASI** (narasi->entitas->ukuran->relasi->output). Dipakai SEBELUM eksekusi. Output = TaskState. ("ukuran" = dimensi terukur -> jembatan ke assert gate).
- Urutan: NEURO-ARC (bentuk peta) -> A.R.S.I (aturan nyetir) -> arsi engine (mobil+sopir jalan).

### 12.3 Workflow ADAPTIF (BUKAN paksa-4-pipa)
- ROUTER nentuin kedalaman (ringan, gak pernah blok):
  - trivial -> jawab langsung (jarvis-fast), 0 pipa.
  - riset/brainstorm internal -> mikir bebas, GATE BYPASS (Mythos-mode).
  - task/artefak -> NEURO-ARC -> ARSI 4-pipa -> GATE PIPA4 (Fable-mode, gate NYALA).
- Maksa semua lewat 4-pipa = lemot + over-engineering (biang DailyFree dulu). Adaptive = skalain effort ke bobot masalah.

### 12.4 PENEMPATAN LLM (terkunci)
- LLM ditaro di lapis SOFT: ROUTER-L2 (fallback ambigu; L1 = embedding), NEURO-ARC (ekstrak->TaskState), PIPA1-3 (intake/rancang/tulis), ARSI Iterasi (perbaiki dari feedback gate).
- LLM **DILARANG** di PIPA4 GATE -> Python deterministik murni. LLM cuma boleh usul `AWAITING_GATE`, vonis DONE ditolak via PermissionError di kode.
- Prinsip: LLM dilepas LIAR di soft, dirantai NON-LLM di output. = "Fable: buas tapi dirantai".

### 12.5 Pemetaan Fable/Mythos (BELUM TERBUKTI produknya nyata — pola-nya valid)
- Adaptive thinking always-on = NEURO-ARC + jarvis-reason.
- Long-horizon autonomy = ARSI loop + workspace habitat + memory persisten.
- Proactive self-verification = GATE PIPA4 + Iterasi (loop produksi->vonis->perbaiki->re-gate sampai lolos).
- Classifier + silent fallback = ROUTER + combo priority-fallback.
- Fable (dirantai) vs Mythos (lepas di lab) = SAKLAR KONTEKS (public=gate ON / internal_research=bypass).
- NOTE keamanan: bagian "matiin safeguard buat exploit/zero-day/senjata" = TIDAK dibangun. Desain ini gak butuh itu.

### 12.6 VISI: Jarvis = OTAK KEDUA ARIF
- Implikasi: MEMORI PERSISTEN naik prioritas (otak kedua tanpa ingat = chatbot). 
  Pakai `~/.hermes/state/ARIF_STACK_EVENT_LOG.md` + memory schema sebagai recall lintas sesi.
- Skill harus encode CARA MIKIR ARIF (NEURO-ARC/ARSI), bukan generik.

### 12.7 RENCANA SKILL (Jalur A — DNA monster, SOFT, no restart)
- `neuro-arc`     -> think-first always-on (narasi->struktur->TaskState).
- `arsi-doctrine` -> patuhi A.R.S.I + LOOP ITERASI self-healing (produksi->gate->perbaiki->ulang sampai lolos).
- `pipa-routing`  -> router/classifier: scan niat -> pilih jalur -> saklar Fable/Mythos.
- CATATAN: "arsi engine" BUKAN skill (itu runtime/kode). Skill cuma nanamin ATURAN-nya.
- Gate PIPA4 = TIDAK disentuh skill (rantai tetap deterministik).
- BLOCKER mulai nulis: (1) path folder skill (`~/.hermes/skills/`? belum kebukti), (2) 1 template skill existing.

### 12.8 Habitat workspace Jarvis (dikonfirm sesi ini)
- Lab terkontrol: `~/.hermes/pipelines/pipa4/phase7a/runs/<ts>/` (per-run isolation, original NEVER modified).
- Tangan: `~/.hermes/outbox/{long_outputs,presentations,spreadsheets,documents}`.
- Indera: `~/.hermes/cache/{documents,audio_cache,browser_downloads}`.
- Perkakas: `~/.hermes/scripts/`. Mata: `~/.hermes/logs/{gateway,agent,errors}.log`.
- Memori: `~/.hermes/state/ARIF_STACK_EVENT_LOG.md`.
- Safety invariants = rantai Fable: original never modified, service/config BLOCKED by gate, per-run isolation, rollback-ready.


### 12.9 ALWAYS-ON DEPLOYED & VERIFIED (2026-06-27 ~22:45 WIB) — DONE
Status: neuro-arc + arsi-doctrine = ALWAYS-ON, TERBUKTI aktif di session baru tanpa restart.

MEKANISME (penting, beda dari dugaan awal):
- `enabled_default_skills` di config.yaml = KNOB MATI (0 referensi di seluruh .py hermes-agent). 
  Sempat di-edit, lalu DI-REVERT balik ke `['smart-router']` (housekeeping). JANGAN pakai key ini buat always-on.
- Always-on SEJATI Hermes = direktif behavioral di `~/.hermes/memories/USER.md` yang di-INJECT ke 
  system prompt tiap turn (pola sama dgn guard existing: casual-chat-mode L512, evidence-claim-status-guard L572).
- conversation_loop.py: system prompt = "territory Hermes", di-cache antar-turn TAPI dibangun per-session 
  -> session BARU langsung kebaca, gak perlu restart/reload.

YANG DILAKUKAN:
- Append 2 direktif ke USER.md (L618 neuro-arc, L619 arsi-doctrine) via scripts/deploy_alwayson.sh (idempotent, auto-backup).
- Skill full ada di ~/.hermes/skills/{neuro-arc,arsi-doctrine}/SKILL.md (deployed, lolos _validate_frontmatter, 
  on-demand depth). neuro-arc 3639B/10cebf13. arsi-doctrine 3806B/c465c25f (sha setelah fix YAML quote).

BUKTI (session baru):
- TES1 quote: Jarvis ngutip PERSIS dua direktif -> ada di system prompt.
- TES2 behavioral (task under-specified): Jarvis struktur dulu (nanya ukuran/PIN-POINT FACTS), audit-first, 
  gak self-declare DONE -> NEURO-ARC + ARSI(Audit) + authority aktif.

BELUM TERBUKTI: loop ARSI penuh (Iterasi->gate end-to-end) belum diuji sampai artefak kelar.

ROLLBACK: cp ~/.hermes/memories/USER.md.bak.20260627_224419 ~/.hermes/memories/USER.md
DEPLOY ULANG / IDEMPOTEN: cd ~/jarvis && git pull && bash scripts/deploy_alwayson.sh

LESSON OPERASIONAL (kepakai sepanjang sesi ini):
- Jarvis sering MISREPORT konten file panjang (ngeringkas `cat`), tapi command pendek (ls/grep/sha) raw. 
  -> verifikasi file panjang via wc -c + sha256, JANGAN percaya "match"/"lengkap" tanpa angka.
- Jarvis kemungkinan GAK persist cwd antar-command -> pakai PATH ABSOLUT.
- Paste heredoc panjang via Telegram/SSH-mobile KEPOTONG -> deploy file via git (byte-exact), bukan paste.


### 12.10 PIPA4 GATE AUDIT — VERIFIED SEHAT (2026-06-27) + rencana langkah B
- PIPA4 = orchestrator (phase7a/pipa4_review_local.py, 234 baris): jalanin phase6a (audit+LLM review) & 
  phase6c/6d (council) sbg subprocess, lalu aggregate_results merge JSON. production_ready HARDCODE False.
- synthesize_final (phase6a:131-155) = BUKTI prinsip kepatuh: docstring "deterministic gate is authority, 
  LLM is advisory". gate_overall=='FAIL' -> final=gate (FAIL), LLM yg bilang READY di-OVERRIDDEN_BY_GATE + 
  false_ready_risk=HIGH. gate PASS -> LLM cuma boleh downgrade (NEEDS_*). LLM GAK BISA naikin FAIL->READY.
- VONIS: PIPA4 gate sehat, anti-False-READY solid, JSON/deterministik = otoritas. TIDAK perlu fix korektif.
- LANGKAH B (opsional, pending): DailyFree ke-hardcode di phase6a:73, phase6c:16, phase6d:35&194, phase7a:104.
  Rencana swap -> 'jarvis-reason' (combo audit/reasoning) buat naikin kualitas ADVISORY. 
  PRA-SYARAT: verifikasi guardian_router (~/.hermes/scripts/guardian_router.py) nerima nama combo 'jarvis-reason'.
- Checkpoint utk Jarvis ditulis ke ~/.hermes/state/ARIF_STACK_EVENT_LOG.md via scripts/log_session_checkpoint.sh.


### 12.11 PIPA4 COUNCIL MODEL SWAP -> jarvis-reason (2026-06-29) — DONE & VERIFIED
- Combo audit `jarvis-reason` (RR-off, model reasoning/thinking) GANTIIN `DailyFree` (50-model RR gacha, maxtok 800) di council PIPA4 (lapis ADVISORY; gate deterministik TIDAK berubah).
- guardian_router: jarvis-reason didaftarin (COMBO_MODEL_MAP L86 "jarvis-reason":"jarvis-reason", COMBO_TIMEOUTS L102 =150, COMBO_MAX_TOKENS L112 =3000). Guardian (hermes-guardian.service) di-restart biar map kebaca. Backup: guardian_router.py.bak.20260629_005231.
- Council files di-swap DailyFree->jarvis-reason (5 titik): phase6a:73, phase6c:16, phase6d:35 & 194, phase7a/pipa4_review_local.py:104. Backup tiap file .bak.20260629_013417.
- VERIFIED: (a) jarvis-reason via Guardian 20129 -> 200 + "43"; (b) call_llm_via_guardian default -> ERR None, OUT 43.
- CATATAN: enabled_default_skills = DEAD knob (jangan dipakai). always-on lewat USER.md. 
- CATATAN: jarvis-reason via Guardian agak lambat variabel (fallback chain + ~2000 tok system prompt inject); curl pakai -m>=120. phase6a timeout=120 nampung. OPEN: cek model mati di combo jarvis-reason (re-verify).
- BELUM TERBUKTI: kualitas council jarvis-reason vs DailyFree di artefak nyata (uji pas audit berikut).
- ROLLBACK council: cp <file>.bak.20260629_013417 -> file asli (4 file). ROLLBACK guardian_router: cp guardian_router.py.bak.20260629_005231 + restart hermes-guardian.service.


### 12.12 ACTION-GATE v1 + MISTAKE-MEMORY (2026-06-29) — DEPLOYED & SELF-TEST 10/10
- Tujuan: bikin Jarvis AUTO-AGENT terkendali (auto di aman, escalate di bahaya, refuse di suicidal, belajar dari salah).
- Lokasi: ~/.hermes/action_gate/{action_gate.py, action_gate_rules.json, lessons_logger.py}. Repo: action_gate/.
- VONIS gate: AUTO_OK | AUTO_OK_W_BACKUP | NEEDS_APPROVAL | REFUSE. assert_allowed() lempar PermissionError di REFUSE (anti-bypass, kayak PIPA4).
- Tier (tunable di rules.json): git push main non-force=AUTO_OK; force-push main=NEEDS_APPROVAL; restart PROTECTED_SERVICE=AUTO_OK_W_BACKUP (+backup config+health-check+auto-rollback); modify/delete PROTECTED_PATHS=NEEDS_APPROVAL; rm protected / tamper safety-mechanism / exfil secret=REFUSE; default tak-dikenal=NEEDS_APPROVAL (konservatif).
- MISTAKE-MEMORY: L1 auto-log kegagalan/refuse/rollback/koreksi -> ~/.hermes/memories/LESSONS.md; L2 recall sebelum task sejenis; L3 promosi jadi aturan always-on = WAJIB review Arif (anti skill-rot, BUKAN auto).
- ENFORCEMENT v1 = via DIREKTIF always-on di USER.md (advisory-strong, kayak DNA). v2 (nanti) = wire ke lapis eksekusi hermes-agent biar gak bisa bypass (nyentuh core, observe dulu).
- Self-test 10/10 PASS (ls/push/force-push/restart-guardian/stop-gateway/rm-config/rm-gate/rm-workspace/pip/exfil).
- BELUM TERBUKTI: behavioral test (gate dikonsultasi di turn percakapan nyata).
- Deploy ulang/idempoten: cd ~/jarvis && git pull && bash scripts/deploy_action_gate.sh
- ROLLBACK direktif: cp ~/.hermes/memories/USER.md.bak.<ts> USER.md.


### 12.13 RESUME POINT (2026-06-29 ~14:45) — lanjut di SESI BARU dari sini
> Sesi chat penuh. Ini state lengkap + langkah berikut. Sesi baru: clone repo, baca file ini, lanjut.

#### YANG SUDAH LIVE & TERBUKTI (hari ini):
- Skills always-on: neuro-arc + arsi-doctrine (via USER.md L618/619). Verified.
- Council PIPA4: DailyFree -> jarvis-reason (5 file council + guardian_router map). Verified (served claude-sonnet-4.5-thinking).
- Action-gate v1 (deterministik classifier + mistake-memory LESSONS.md): deployed, self-test 10/10, behavioral PASS.
- Repo arifibnsawir-svg/jarvis (branch main) = sumber kebenaran. Semua script di scripts/, gate di action_gate/.

#### ACTION-GATE v2 (IN-PROGRESS — INI YANG DILANJUT):
Tujuan: enforce gate di LAPIS EKSEKUSI tool (gak bisa bypass). Fase: shadow -> mock -> live.
- Sisi software SIAP & teruji: action_gate/action_gate.py (classify_command + classify_tool + to_unified),
  action_gate/gate_hook.py (gate_tool, mode off|shadow|mock|live, default shadow, log ke ~/.hermes/action_gate/decisions.jsonl).
  Skema SELARAS guardian_gate v0 (SAFE/IMPACT_LIGHT/IMPACT_HEAVY/DANGER/AMBIGUOUS).
- Deployed di Acer: ~/.hermes/action_gate/ (semua file). Module TERBUKTI jalan di venv (manual test bikin decisions.jsonl).
- WIRING SALAH TEMPAT (harus dibenerin): patch ada di ~/.hermes/hermes-agent/agent/tool_executor.py:317-324 
  (di execute_tool_calls_CONCURRENT) -> CUMA firing buat multi-tool, TIDAK kena single/sequential. 
  Backup: tool_executor.py.bak.20260629_142400. Patch ini HARMLESS (shadow, gak blokir) tapi gak guna -> COPOT.
- CHOKEPOINT SEJATI ketemu: _invoke_tool (run_agent.py:4814) = FORWARDER ke 
  **agent/agent_runtime_helpers.py::invoke_tool()**. SEMUA tool (concurrent _run_tool + sequential) lewat sini.

#### LANGKAH BERIKUT (urut, sesi baru):
1. RESTORE tool_executor.py dari backup: cp ~/.hermes/hermes-agent/agent/tool_executor.py.bak.20260629_142400 ~/.hermes/hermes-agent/agent/tool_executor.py
2. BACA chokepoint: sed -n '1,60p' (cari def invoke_tool) di ~/.hermes/hermes-agent/agent/agent_runtime_helpers.py 
   -> liat signature invoke_tool(agent/self, function_name, function_args, ...) + apa yg di-RETURN (buat block-path live).
3. PATCH invoke_tool di AWAL: sisip hook gate_tool (shadow=log+proceed; live=return blocked-result). 
   Pola import: sys.path.insert ~/.hermes/action_gate ; from gate_hook import gate_tool ; except: pass (fail-open shadow).
4. py_compile agent_runtime_helpers.py -> auto-restore kalau gagal.
5. RESTART gateway (BUTUH GO Arif, ~210s tergantung combo) -> mode default shadow.
6. VERIFY: Telegram kasih Jarvis tugas pakai terminal tool -> tail ~/.hermes/action_gate/decisions.jsonl HARUS keisi 
   (decision_mode:shadow, allow_execution:true walau action_class DANGER).
7. Observe shadow beberapa hari -> kalau klasifikasi bener (gak false-block) -> set ACTION_GATE_MODE=live di env gateway -> enforce.

#### MEKANISME PENTING (jangan lupa):
- Gateway load tool_executor/run_agent dari ~/.hermes/hermes-agent/ (BUKAN venv site-packages) -> patch source = kepake. (terverifikasi via t.__file__)
- Restart gateway cepet/lambat tergantung kecepatan combo nge-drain request in-flight (combo bersih = cepet). 210s = batas atas, bukan default.
- guardian_gate v0 (command-plane-v0, slash commands) = SHADOW jalan, KOMPLEMENTER (beda chokepoint), JANGAN diutak-atik.
- KILL-SWITCH: ACTION_GATE_MODE=off di env gateway. ROLLBACK: restore .bak + restart.

#### TIER ATURAN ACTION-GATE (di action_gate_rules.json, udah final di-approve Arif):
- git push main non-force=AUTO; force-push main=NEEDS_APPROVAL; restart protected svc=AUTO_OK_W_BACKUP(+healthcheck+rollback);
  modify/delete protected paths=NEEDS_APPROVAL; rm protected/tamper-safety/exfil-secret=REFUSE; unknown=NEEDS_APPROVAL.
- Mistake-memory: auto-log gagal/refuse/rollback/koreksi ke LESSONS.md; promosi jadi aturan = review Arif (anti skill-rot).



### 12.14 ACTION-GATE v2 — WIRING LIVE DI SHADOW (2026-06-29 ~15:57 WIB) — DONE (shadow), belum enforce
> Nge-overtake 12.13 "ACTION-GATE v2 IN-PROGRESS". Wiring ke chokepoint eksekusi tool SELESAI di mode shadow.

#### PENDEKATAN FINAL (berubah dari rencana 12.13):
- BUKAN patch core. Pakai **PLUGIN `action_gate_v2`** (hook `pre_tool_call`).
- `tool_executor.py` di-RESTORE ke CLEAN (patch salah-tempat dicopot; sha256 `50da34d16e2cb790df5d3c3d66fa2a00f18316eee182c79e6d0ecfb424590a99`).
- Kenapa plugin menang: `get_pre_tool_call_block_message()` dipanggil di SEMUA jalur tool — concurrent `tool_executor.py:274`, sequential `tool_executor.py:749`, `invoke_tool` `agent_runtime_helpers.py:1634` → coverage PENUH tanpa nyentuh core. `pre_tool_call` ada di `VALID_HOOKS` (plugins.py:129).

#### FILE (repo, branch `feat/action-gate-v2-plugin`, PR #2):
- `plugins/action_gate_v2/plugin.yaml` + `__init__.py` = adapter tipis: `pre_tool_call(tool_name,args)` -> `~/.hermes/action_gate/gate_hook.gate_tool(...)`. shadow/mock -> return None (observe). live -> `{"action":"block"}` kalau NEEDS_APPROVAL/REFUSE. FAIL-OPEN di shadow.
- `scripts/deploy_action_gate_v2_plugin.sh` = deploy idempotent (sinkron engine + copy plugin + py_compile + smoke-test + ENABLE di config.yaml). TIDAK restart.

#### ROOT CAUSE plugin gak load (pertama kali) + FIX:
- Discovery = **OPT-IN** via `config.yaml` key `plugins.enabled` (plugins.py:1174-1178: enabled=False -> register() gak jalan). Plugin baru WAJIB didaftarin.
- FIX: tambah `action_gate_v2` ke `plugins.enabled` (deploy script step [5], idempotent, +backup config.yaml.bak.*, +YAML sanity check). 

#### BUKTI LIVE (shadow):
- Restart 15:56 (PID 465085, port 9119 hidup). Log: "Plugin action_gate_v2 registered hook: pre_tool_call". Discovery: 41 found, 34 enabled.
- `~/.hermes/action_gate/decisions.jsonl` nambah entri REAL dari tool-call Jarvis: read-only -> AUTO_OK/SAFE; `systemctl restart` -> AUTO_OK_W_BACKUP; protected path -> NEEDS_APPROVAL. SEMUA `decision_mode:shadow`, `allow_execution:true` (observe-only, zero blocking).

#### STATUS & NEXT:
- STATUS: shadow OBSERVE-ONLY LIVE. Zero production impact. BELUM enforce.
- BELUM TERBUKTI: akurasi klasifikasi di tugas NYATA & BERAGAM (sample baru ~13 entri, mayoritas command infra sendiri). Sebelum live: pastikan gak false-block kerja legit (nulis ke outbox/workspace, edit file biasa).
- NEXT (urut): (1) observe shadow beberapa hari di tugas beragam; (2) opsional dry-run accuracy sweep via `python3 ~/.hermes/action_gate/action_gate.py "<cmd>"` (klasifikasi murni, TANPA eksekusi); (3) baru `ACTION_GATE_MODE=live` di env gateway + restart buat enforce.
- KILL-SWITCH: `ACTION_GATE_MODE=off`. ROLLBACK plugin: `rm -rf ~/.hermes/plugins/action_gate_v2` + restart. ROLLBACK config: `cp ~/.hermes/config.yaml.bak.<ts> ~/.hermes/config.yaml`.
- ANTI-FALSE-READY: "shadow live" != "DONE/enforce". Naik live butuh bukti shadow bersih + GO Arif.



### 12.15 ACTION-GATE v2 — TUNING SHADOW + TEMUAN PRE-LIVE (2026-06-29 ~16:1x WIB)
> Dari dry-run akurasi + distribusi trafik shadow. Tetap SHADOW; tuning aman aja, JANGAN live dulu.

#### BUKTI (dry-run klasifikasi murni, tanpa eksekusi):
- Kasus bahaya AKURAT 8/8: rm-protected & exfil .env -> REFUSE; force-push & pip -> NEEDS_APPROVAL; read-only & tulis-outbox -> AUTO_OK.
- Default-deny: command dev/build tak-dikenal (python3/node/make/tar/jq/awk/docker/./run.sh) -> NEEDS_APPROVAL.
- Distribusi 17 entri shadow (TERCEMAR command diagnostik sendiri, blm representatif): AUTO_OK 3, AUTO_OK_W_BACKUP 5, NEEDS_APPROVAL 5, REFUSE 4.
- Command majemuk (loop/;/heredoc) diklasifikasi sbg 1 blob via substring -> dry-run loop sendiri kena REFUSE krn stringnya memuat "rm -rf config.yaml" (errs-safe, tapi nunjukin batas regex-gate).

#### TUNING SUDAH DIKERJAIN (commit di branch, SHADOW = zero-risk):
- `action_gate.py` section 7: READ-list diperluas (echo/printf/env/jq/cut/sort/uniq/tr/column/basename/dirname/realpath/readlink/file/diff/cmp/type/id/groups/hostname/uptime/free/tree/less/more/rg/git remote) -> util baca jelas-aman jadi AUTO_OK (turunin friction).
- TUTUP LUBANG: kalau ada redirect '>' -> TIDAK lagi dianggap read-only, jatuh ke section 8 (write) biar path-nya dinilai. Fix `cat rahasia > ~/.hermes/config.yaml` yg dulu lolos AUTO_OK -> sekarang NEEDS_APPROVAL.
- Interpreter (python3/bash/sh/node/make/...) SENGAJA TETAP NEEDS_APPROVAL. Test lokal 17/17 PASS.

#### MUST-FIX / PUTUSKAN SEBELUM LIVE (jangan live tanpa ini beres):
1. INTERPRETER BYPASS: auto-allow `python3 -c "..."`/`bash -c` = kode arbitrer lolos gate pola. Keputusan Arif: (a) biarin NEEDS_APPROVAL (aman, friction) atau (b) skema lain (mis. cuma allow di workspace + backup). DEFAULT sekarang = (a).
2. COMMAND MAJEMUK: [DONE 2026-06-29] split top-level (;/&&/||/|/newline) hormati kutip, heredoc tak dipecah, verdict PALING KETAT menang. Nutup prefix-masking ('echo x && ./run.sh' dulu AUTO_OK -> NEEDS_APPROVAL) & 'cat f | tee protected' (dulu lolos read -> NEEDS_APPROVAL). Test 21/21 PASS. Implement di classify_command (wrapper) + _classify_single (body lama).
3. FRICTION NYATA: kumpulin trafik shadow ORGANIK (bukan command diagnostik) bbrp hari -> ukur % NEEDS_APPROVAL pada kerja legit -> tuning dari DATA, bukan tebakan.

#### KEPUTUSAN: tetap SHADOW. Live cuda setelah (1) diputuskan, friction organik terukur OK, dan GO Arif.



### 12.16 LESSON: VERIFY LIVENESS GATE != PORT 9119 (2026-06-29 ~16:55) + shadow final CONFIRMED
- KOREKSI asumsi Bagian 1: port 9119 = proses **DASHBOARD** (`hermes dashboard --port 9119`, PID lama, hidup sejak boot). Proses **GATEWAY messaging** (`python -m hermes_cli.main gateway run`) = PROSES TERPISAH, ini yg restart pas reload plugin & TEMPAT action-gate hook fire.
- JEBAKAN: cek `ss -ltnp | grep 9119` -> nunjukin PID dashboard, BUKAN gateway. PID listener 9119 beda dari PID yg nge-load plugin = NORMAL (dua proses beda), bukan error.
- CARA VERIFY GATE LIVE yg BENAR (behavioral, anti-bingung-PID):
  - proses gateway: `pgrep -af "hermes_cli.main gateway run"`.
  - bukti engine action-gate kepake di proses yg melayani: `grep -c "majemuk" ~/.hermes/action_gate/decisions.jsonl` + cek timestamp entri > waktu restart. Marker `[majemuk]` cuma diproduksi engine compound-aware -> bukti ruleset final aktif.
- STATUS FINAL (terbukti): ruleset action-gate final (READ-list tuned + redirect-fix + compound-aware) AKTIF di gateway PID 466207 sejak 16:51. Shadow, allow_execution:true semua. 4 entri `[majemuk]` post-restart = bukti behavioral.
- PARKIR: kumpulin trafik ORGANIK bbrp hari -> baca distribusi -> whitelist data-driven -> keputusan interpreter -> baru live (GO Arif).



### 12.17 PIPA-ROUTING SKILL (D-soft) — dibuat, siap deploy (2026-06-29)
> Lanjutan dari pertanyaan Arif "router biar model+jalur bener" (pilihan D). D dipecah: soft (skill) vs hard (infra).

- KEPUTUSAN: garap **D-soft** (skill pipa-routing) dulu; **D-hard** (routing combo per-request di 9router) DITUNDA sampai (a) kebukti gateway dukung override model per-request, (b) ada data jarvis-agent kurang per-tugas. Anti-over-engineering.
- D-soft = `skills/pipa-routing/SKILL.md` (4610B) + direktif always-on di USER.md (pola deploy_alwayson.sh). Router PERILAKU: scan niat -> pilih KEDALAMAN (trivial/riset/artefak, adaptive) -> pilih PENDEKATAN per artifact_type (kode; dokumen/slide=Structure-Before-Render JANGAN one-shot; web=cite-or-abstain; audit=gate). Router TIDAK pernah blok/vonis (separation router!=gate). precedes neuro-arc.
- Kenapa ini fondasi: ini "Router yang menentukan kedalaman" yg dirujuk skill neuro-arc tapi belum ada. Langsung nolong 2 pain Arif: web-halu (cite-or-abstain) & doc one-shot (Structure-Before-Render mindset).
- BATAS JUJUR: skill ini memperbaiki PENDEKATAN. Doc kelar total tetap butuh A (wiring renderer python-docx/pptx, OPEN item #6). Web kelar butuh tool search + verify (B). Skill = fondasi, bukan solusi penuh.
- Deploy: `scripts/deploy_pipa_routing.sh` (copy SKILL.md + inject direktif USER.md, idempotent+backup, validasi frontmatter). TIDAK restart; aktif di SESSION BARU (/new). ROLLBACK: restore USER.md.bak + rm -rf skills/pipa-routing.
- Repo: branch feat/action-gate-v2-plugin (PR #2). TEST: behavioral di session baru (kasih tugas doc -> harus minta spec dulu/structure; kasih tugas web -> harus cite-or-abstain, gak ngarang sumber). BELUM TERBUKTI sampai diuji di session nyata.
- SISA OPEN (urut rekomendasi): A wiring renderer (doc/ppt) -> B web-grounding skill+tool -> C deterministik mistake-logging via post_tool_call hook -> D-hard combo routing (kalau perlu). Mistake-memory (LESSONS.md) saat ini = CLI + direktif advisory (belum deterministik).



### 12.18 PIPA-ROUTING D-soft — TERBUKTI (behavioral) + temuan Acer>repo (2026-06-29 ~17:30)
- Frontmatter SKILL.md sempat GAGAL yaml.safe_load (ada ': ' di description tak-dikutip) -> FIX: description di-quote + ':' inline jadi '-'. Verified parse OK pakai PyYAML asli (neuro-arc/arsi/pipa-routing semua OK). Redeploy: RESULT_FRONTMATTER OK.
- UJI BEHAVIORAL (session baru):
  - DOC ("bikin slide 5 hal"): Jarvis skill_view pipa-routing+neuro-arc+pptx-slides-creation-guard -> struktur dulu -> execute_code python-pptx render -> terminal ls verify (32KB). = Structure-Before-Render JALAN (bukan one-shot). PASS.
  - WEB ("data 2025" lalu ralat "2026"): untuk 2026 Jarvis ABSTAIN ("belum terkonfirmasi dipublikasikan"), pisah FAKTA TERVERIFIKASI vs BELUM TERBUKTI + NEXT SAFE ACTION, gak ngarang angka. cite-or-abstain JALAN. PASS inti.
- CAVEAT JUJUR (belum kelar):
  1. WEB drift angka: sumber sama (DataReportal) dua jawaban beda (221,6jt/79,5% vs 212,9jt/77,0%) -> salah-atribusi APJII->DataReportal. cite-or-abstain nangkep yg besar, detail angka masih meleset. B perlu aturan "angka WAJIB dikutip dari halaman ter-fetch, bukan ingatan".
  2. DOC: file ke-render+verify ADA, tapi ISI/akurasi belum dinilai (perlu buka PPTX).
- TEMUAN PENTING (koreksi asumsi repo-based): Acer punya skill yg TIDAK ADA di repo: `pptx-slides-creation-guard`, `arif-realtime-evidence-protocol-v2` (+ kemungkinan lain). Penilaian "renderer gak wired / web belum dibangun" tadi BASI (itu dari repo). Acer lebih maju.
  -> RISIKO: skill-skill itu cuma di Acer, gak ke-backup/version-control. GAP: perlu tarik semua ~/.hermes/skills/* ke repo (backup + bisa diff/iterate).
- REVISI PRIORITAS SISA: (0) BACKUP skill Acer->repo dulu (cheap, anti-kehilangan + bikin penilaian akurat). (B') perketat web fact-binding (angka dari fetched page). (A') nilai kualitas pptx-slides-creation-guard yg udah ada, baru perbaiki kalau perlu (jangan bikin ulang renderer dari nol -> over-engineering). (C) mistake-logging deterministik via post_tool_call.



### 12.19 PPTX DESIGN-SYSTEM RENDERER — TERBUKTI VISUAL (2026-06-29 ~20:10)
- Masalah: output pptx Jarvis "standar banget" (hitam-putih, font default, gap mati) -> guard pptx cuma atur struktur/keamanan, GAK atur desain; render ad-hoc python-pptx blank.
- FIX (live & verified visual via screenshot WPS): `renderer/render_deck.py` (deploy ke ~/.hermes/scripts/) = design-system 16:9: accent bar atas, garis bawah judul, bullet marker biru, bold lead keyword ("Lead: detail"), layout section (band biru), two_col, closing, footer+nomor halaman, palet #2563EB/#1E40AF/#EEF2FF. Deterministik, anti-halu image.
- skill `pptx-slides-creation-guard` V2: WAJIB render lewat render_deck.py (spec JSON -> render), larang build-from-blank. Skill lama di-backup + di-mirror ke repo.
- BUKTI: deck "manfaat tidur" 7 slide ke-render ulang -> Arif lihat di WPS -> VERDICT naik kelas dari "standar" jadi clean-profesional. PASS.
- SISA OPSIONAL (bukan keharusan): ikon/ilustrasi/gambar (butuh set ikon kurasi, jaga anti-halu), heading font lebih tegas, tema varian. JANGAN bikin engine desain raksasa (over-engineering) sebelum diminta.
- BELUM DIUJI: skill V2 wiring otomatis (apakah Jarvis di /new beneran keluarin spec -> render_deck.py sendiri, bukan ad-hoc). Uji: /new lalu minta bikin deck dari nol.
- CARA KIRIM FILE: render via command langsung TIDAK auto-kirim ke Telegram; minta Jarvis "kirim file <path> sebagai dokumen" (alur normal pptx-creation yg auto-attach).



### 12.20 ADOPSI office-academic-skill (lane joki kuliah) — DEPLOYED, pending uji (2026-06-29)
- Sumber: zLanqing/codex-claude-academic-skills (MIT). SCOPED: cuma `office-academic-skill` (skip scientific-toolkit & research-writing & guizang/AGPL). Alasan pilih: output .pptx/.docx EDITABLE + anti-fabrikasi + tag sumber + template-clone + overflow scan = pas buat tugas akademik.
- Deploy via scripts/deploy_office_academic_skill.sh: clone upstream -> copy folder ke ~/.hermes/skills/office-academic-skill (2.7M, references+scripts+agents) -> sisip override BAHASA INDONESIA (upstream default China) -> install deps venv (python-pptx/Pillow/PyMuPDF/pypdf) -> verifikasi. commit upstream 7ed6377.
- VERIFIED teknis: frontmatter name=office-academic-skill, template_tools import OK, override ID kesisip (SKILL.md baris 5-6). LICENSE.upstream dijaga (atribusi MIT).
- KLASIFIKASI ARSITEKTUR (penting, jangan kabur): skill ini = lapis PRODUKSI artefak (keluarga A', sodara render_deck.py), BUKAN router D. D cuma kesentuh nanti via +1 rute di pipa-routing.
- BELUM TERBUKTI: (a) Hermes loader auto-surface skill ini (skill_view) di /new; (b) output beneran Indonesia+editable; (c) DISAMBIGUASI vs pptx-slides-creation-guard/render_deck (sekarang ADA 2 jalur pptx -> rawan Jarvis bingung pilih). Uji /new dulu, baru wiring pipa-routing buat misahin: akademik/template -> office-academic-skill; deck cepat -> render_deck; pamer HTML -> (nanti) guizang.
- ROLLBACK: rm -rf ~/.hermes/skills/office-academic-skill (+ _src_academic).



### 12.21 HUMANIZER-DEFAULT done + BOTTLENECK = SKILL SELECTION (2026-06-29 ~23:45)
- HUMANIZER jadi DEFAULT semua artefak: direktif di USER.md L623 (via scripts/deploy_humanizer_default.sh). KEBUKTI jalan: tes deck HTML -> Jarvis `skill_view: humanizer`. (catatan: script sempat lapor false-FAIL krn MARK apostrof; udah difix, direktif tetap tertulis L623). Humanizer kini 3 lapis: sosmed (L5/508/510) + akademik (L564/568/570/579) + semua artefak (L623).
- TEMUAN UTAMA (kebukti 3x): masalah BUKAN kurang skill (Acer ~200 skill, banyak bagus: academic-document-factory, claude-design, popular-web-designs, baoyu-infographic, powerpoint, office-document-ops). Masalah = **SELEKSI/ROUTING**: Jarvis freehand / ambil guard generik, GAK milih spesialis.
  - PPT akademik -> pptx-slides-creation-guard/render_deck (bukan academic-document-factory)
  - Word -> document-preservation-guard + docx ad-hoc
  - wow HTML -> write_file freehand (bukan claude-design/popular-web-designs)
- KONSEKUENSI: nambah skill (guizang/office-academic) PERCUMA tanpa fix routing. office-academic-skill REDUNDAN vs academic-document-factory (saran hapus). guizang DITAHAN.
- NEXT (prioritas): wiring pipa-routing (D) mapping eksplisit intent->skill spesialis + humanizer selalu. Sebelum nunjuk skill "wow", VERIFIKASI kualitas output (freehand HTML Jarvis vs claude-design) via screenshot browser (HTML content:// gak bisa diakses Kiro; user buka di browser + kirim PNG).
- Skill discovery: config skill_dirs kosong = SEMUA skill di ~/.hermes/skills/ auto-available (skill.py iterdir + auto_load). Jadi bukan masalah discovery, murni SELEKSI.



### 12.22 ACADEMIC SOURCING works + PPTX quality ceiling = HTML vs pptx (2026-06-30 ~01:00)
- ACADEMIC SOURCING rule (USER.md L625) JALAN: tes PPT sidang -> Jarvis delegate_task cari sumber -> dapet 5 sumber Indonesia ASLI (Bire 2014 Jurnal Kependidikan, Ghufron&Risnawita 2012, Hartati 2015 Formatif, Papilaya&Huliselan 2016 J.Psikologi Undip, Widayanti 2013 ERUDIO), dikutip di Daftar Pustaka. Indonesia-first + no-halu = TERBUKTI. Learning 1260e8e6.
- MASALAH SELEKSI (lagi): Jarvis utk PPT sidang pilih skill `powerpoint` -> bikin **pptxgenjs (Node.js)** freehand, BUKAN render_deck.py v2 kita. Bahkan nyangkut crash `sharp` (CPU Acer lama: "Illegal instruction"), workaround buang sharp. Jadi render_deck v2 gak kepake. Ada 2 jalur pptx bersaing (powerpoint/pptxgenjs vs render_deck) -> routing belum misahin.
- AKAR "belum seperti Kiro buat": kualitas tinggi Kiro = jalur HTML/CSS (book via WeasyPrint, deck parfum via claude-design). HTML/CSS jauh lebih ekspresif dari engine pptx mana pun (python-pptx ATAU pptxgenjs) -> PPTX punya PLAFON. pptxgenjs (161K, cards/shadow/flow) udah "lebih baik" dari render_deck v1 tapi tetap di bawah HTML.
- KEPUTUSAN PENDING (nentuin arah): sidang WAJIB .pptx editable, atau PDF cakep diterima?
  - PDF ok -> HTML/CSS -> PDF (Kiro-grade, achievable now). REKOMENDASI.
  - .pptx wajib -> dekat plafon: html2pptx (HTML->editable pptx, verify fidelity) ATAU terima render_deck v2 clean (deterministik, no Node/sharp).
- TODO routing: arahkan academic pptx ke 1 jalur DETERMINISTIK (hindari pptxgenjs+sharp yg crash di Acer). Catatan: sharp/native-binary CRASH di CPU Acer lama -> hindari skill yg butuh sharp.
- render_deck v2 (renderer/render_deck.py) udah dibuat (preset academic/business/dark + layout big_stat/quote/timeline/section-bernomor) tapi BELUM kepakai Jarvis (kalah routing vs powerpoint/pptxgenjs). Perlu wiring eksplisit kalau jalur pptx dipilih.



### 12.23 DUAL-OUTPUT TEST (sidang gaya belajar) — DIRECTIVE WORKS, web-grounding GAP terekspos (2026-06-30)
> Nge-overtake keputusan PENDING di 12.22 (PDF cakep vs .pptx wajib). Diputuskan: KEDUANYA (dual-output). Commit bffc55b. Tes pertama dijalankan, dievaluasi dari file asli (di-download dari Drive Arif, di-render Kiro). Ini lensa TUNING, bukan penilaian dokumen.

#### KEPUTUSAN TERKUNCI (overtake 12.22):
- Sidang TIDAK harus pilih salah satu. Dari 1 konten+sumber SAMA, Jarvis bikin DUA file: (1) HTML claude-design -> PDF landscape print-ready (versi "wow"); (2) .pptx editable via render_deck.py. LARANG pptxgenjs/sharp (crash Illegal instruction CPU Acer).
- Tool: scripts/html_to_pdf.sh (chromium headless --print-to-pdf utama + soffice fallback). deploy_dual_output.sh = deploy tool + direktif always-on "DUAL-OUTPUT DECKS" ke USER.md. Idempotent, no restart.

#### TES PROBE: "presentasi sidang pengaruh gaya belajar terhadap prestasi, DUA versi PDF wow + PPTX editable, sumber Indonesia dulu"
File hasil (Drive "Hasil jarvis"): sidang_gaya_belajar_prestasi.pdf (144KB, 15 hal), Sidang_Gaya_Belajar_Prestasi.pptx (51KB render_deck, 15 slide), sidang_gaya_belajar.pptx (161KB pptxgenjs versi LAMA, pembanding).

#### FAKTA TERBUKTI (sinyal tuning POSITIF):
1. DUAL-OUTPUT DIRECTIVE NGUBAH ROUTING. Jarvis bikin DUA file lewat tool BENAR: PDF via html_to_pdf.sh + .pptx via render_deck.py. TIDAK pakai pptxgenjs, TIDAK crash sharp. Ini persis yang 12.22 bilang belum kejadian (dulu Jarvis pilih powerpoint/pptxgenjs). Seleksi-skill utk artifact dual-output = BERHASIL diarahkan.
2. ANTI-HALU SUMBER BEKERJA. Web gagal (lihat GAP) -> Jarvis nge-LABEL ref [6][7] sebagai NEEDS_VERIFICATION + tandai data korelasi r=0,35-0,42 sebagai "ILUSTRASI", BUKAN ngarang DOI/temuan palsu. Cite-or-abstain nahan.
3. PDF "wow" = bagus secara visual (Kiro render PDF->PNG, lihat langsung): tema navy gradient, accent bar, flow diagram kerangka berpikir (kotak+panah+box dashed), tabel hasil header berwarna, callout box. Konfirmasi jalur HTML/CSS->PDF = Kiro-grade (selaras 12.22).

#### GAP TEREKSPOS (sinyal tuning, INI yang dikerjain berikut):
1. GAP-WEB (BESAR): web-grounding Jarvis MATI di run ini. delegate_task subagent TIDAK punya akses web; curl Scholar -> CAPTCHA; Garuda -> tidak responsif. Akibat: aturan Indonesia-first benar secara PERILAKU tapi tidak punya TOOL eksekusi -> selalu jatuh ke placeholder. Ini OPEN-item B (web-grounding skill+tool) yang belum kelar. CATATAN: tes 12.22 LAPOR dapet 5 sumber Indonesia asli, tapi run ini GAGAL -> kapabilitas web Jarvis TIDAK konsisten/andal. Perlu diagnosa di Acer: kenapa subagent gak punya web, apakah ada tool search lain yang gak kepilih, kenapa kadang dapet kadang gagal.
2. GAP-WRITE (sedang): write-pipeline rapuh. CHUNKED WRITE PROTOCOL (max 350 baris) + heredoc parsing error + file HTML corrupt (konten di luar </body></html>) + nulis ulang berkali-kali. ~10 iterasi / 6+ menit utk 1 HTML. Jalur build HTML berkelahi dgn constraint chunked-write. Reliability signal -> pertimbangkan pola spec->render yg lebih atomik utk HTML, bukan append heredoc bertahap.

#### TEMUAN KUALITAS PPTX (objektif, struktur XML; LibreOffice TIDAK ADA di sandbox Kiro AL2023 jadi gak bisa pixel-render pptx):
- render_deck (51KB, NEW) vs pptxgenjs (161KB, OLD): shadow 0 vs 19; border/line 30 vs 78; palet navy-monokrom vs multi-warna (biru+teal+hijau); bg putih (preset academic) vs gelap (slate). Arif nilai OLD lebih "wow".
- AKAR: (a) render_deck.py SENGAJA matiin shadow (sp.shadow.inherit=False di tiap shape); (b) Jarvis pilih preset "academic" (putih polos), padahal render_deck PUNYA preset "dark"/"business" yang lebih nendang tapi gak kepilih.
- KLASIFIKASI: ini PRIORITAS RENDAH dalam konteks tuning (estetika artefak, bukan blocker kapabilitas). Anti-over-engineering (steering #8): JANGAN buru-buru upgrade engine desain. Yang ngebatesin Jarvis = GAP-WEB, bukan shadow slide. Kalau nanti mau, upgrade bedah render_deck (nyalain shadow + layout flow + default preset wow) = murah, tapi tahan sampai gap fungsional beres.

#### STATUS & NEXT:
- STATUS: dual-output PROVEN bekerja (routing + tool benar). Web-grounding = gap fungsional utama berikutnya.
- NEXT (urut): (1) checkpoint ini [DONE]; (2) DIAGNOSA GAP-WEB di Acer (kenapa subagent gak web + apakah ada tool search + kenapa inkonsisten vs 12.22); (3) opsional GAP-WRITE; (4) estetika render_deck = paling akhir / kalau diminta.
- BELUM TERBUKTI: deploy_dual_output.sh udah dijalanin di Acer atau belum (aksi runtime, gak kelihatan dari repo). Verifikasi: cek direktif "DUAL-OUTPUT DECKS" ada di ~/.hermes/memories/USER.md + html_to_pdf.sh ada di ~/.hermes/scripts/.
- Lensa proyek: dokumen-dokumen ini = PROBE TES tuning Jarvis, bukan deliverable. Nilai dari "apa yang dibuktikan tentang perilaku Jarvis", bukan kerapian slide.



### 12.24 KOREKSI: grounding penuh dari transkrip sesi + pembatalan fix salah (2026-06-30)
> Sesi Kiro baru baca FULL transkrip sesi sebelumnya (1917 baris). Mengoreksi kesimpulan keliru yang sempat di-commit lalu di-revert. Lensa TUNING.

#### KESALAHAN YANG DIKOREKSI (lesson, anti-ulang):
- Commit 2ec45c8 (deploy_doc_routing_fix.sh + 12.24 versi lama) DI-REVERT (commit revert 4fd3666). Sebabnya: disimpulkan dari output `ls -1 ~/.hermes/skills/` yang cuma 48 folder bahwa academic-document-factory = "skill hantu" -> SALAH. Transkrip penuh + inventory ~200 skill yang di-paste user nunjukin academic-document-factory ADA dan justru skill akademik UTAMA (4-pipa, ID-native, + humanizer-protocol). office-academic-skill yang REDUNDAN (rencana hapus). Script lama nge-rename ke arah kebalik = berbahaya. Untung belum dideploy.
- LESSON: JANGAN simpulkan "skill tidak ada" dari satu `ls` yang mungkin parsial. Verifikasi via find rekursif + cocokkan dengan inventory penuh. Discrepancy 48 vs ~200 skill antar-output BELUM diselesaikan -> wajib re-grounding sebelum sentuh routing.

#### STATE ASLI (terbukti dari transkrip, semua di PR #2 / branch feat/action-gate-v2-plugin, BELUM merge main):
- Action-gate v2 shadow live + tuned + compound-aware (12.14-12.16). Event log Acer APPENDED.
- pipa-routing D-soft terbukti behavioral (12.17-12.18).
- render_deck v2 design-system (12.19).
- humanizer-default USER.md L623 (12.21) - kebukti fire (skill_view: humanizer di deck).
- artifact-routing L624, academic-sourcing L625 (kebukti: 5 sumber Indonesia asli), dual-output L626 + html_to_pdf.sh + render_deck (12.22, commit bffc55b).
- WIN: auto-select "wow" -> claude-design JALAN otomatis tanpa disuruh.

#### BUG ASLI yang masih kebuka (prioritas tuning sebenarnya):
1. ROUTING AKADEMIK MELESET: pas auto-select PPT sidang, Jarvis pilih skill `powerpoint` -> pptxgenjs (CRASH sharp "Illegal instruction" di CPU Acer), BUKAN academic-document-factory / render_deck / jalur dual-output. Directive L624 belum cukup kuat utk lane akademik (kalah tarikan "PPT editable -> powerpoint"). INI bug doc-routing yang ASLI.
2. WEB-GROUNDING INKONSISTEN: delegate_task subagent TIDAK punya akses web; curl Scholar=CAPTCHA, Garuda=mati. Kadang dapet sumber (12.22), kadang gagal+placeholder (dual-output run). = item B belum kelar.
3. PPTX < HTML (plafon engine): editable pptx (render_deck) selalu di bawah HTML/PDF (claude-design). dual-output = kompromi. User masih rasa pptx "menurun".
4. office-academic-skill + _src_academic = REDUNDAN, belum dihapus (rencana: rm -rf, pakai academic-document-factory).

#### NEXT (urut):
1. MERGE PR #2 ke main - terus ketunda sepanjang sesi lama, PALING penting (persist + kebaca sesi depan).
2. Re-grounding inventory skill Acer (resolve 48 vs ~200) - find rekursif SKILL.md.
3. Fix routing akademik: pertegas L624 / pipa-routing biar academic -> academic-document-factory atau dual-output, JAUHIN powerpoint/pptxgenjs (crash). Observe dulu.
4. (opsional) web-grounding (B): kasih jalur fetch+verify yang andal; hapus skill redundan.
- Humanizer-default sudah aktif (L623) - reinforcement gate di pptx skill BATAL (ikut revert); kalau mau, taruh ulang nanti setelah routing akademik beres.



### 12.25 FIX ROUTING AKADEMIK: pisah akademik-WORD vs akademik-PPT (2026-06-30)
> Lanjutan setelah PR #2 MERGED ke main (semua 12.14-12.24 + skrip + skill udah di main, merge commit 5e44756). Branch baru: fix/academic-ppt-routing.

#### GROUNDING (inspect read-only Acer, terbukti):
- Total skill ASLI = 224 (find rekursif SKILL.md). `ls -1 ~/.hermes/skills/` cuma nampak 48 karena skill NESTED di subfolder kategori (productivity/, creative/, dll). -> discrepancy 48-vs-200 RESOLVED. LESSON: jangan simpulin inventaris dari ls top-level.
- academic-document-factory ADA di productivity/academic-document-factory, TAPI DOCX-ONLY: description+pipeline+references semua DOCX/PDF (mini book/makalah/laporan, python-docx, modul formatting). grep pptx|slide|presentation|powerpoint|render_deck|deck = ZERO. Skill ini TIDAK punya kapabilitas PPT.
- powerpoint (productivity/powerpoint) trigger sangat luas ("any .pptx involved") -> gampang menang utk request PPT.

#### AKAR BUG (terbukti):
- USER.md L624 nge-rute "defense/seminar PPT" -> academic-document-factory (MISMATCH: skill DOCX-only). Konflik dgn L626 (dual-output: akademik deck -> render_deck.py PPTX + claude-design PDF). Akibat: PPT akademik POLOS (yg gak minta dual) bisa nyasar ke powerpoint+pptxgenjs -> CRASH sharp (Illegal instruction CPU Acer). Test 12.22 = bukti (pptxgenjs crash). Test 12.23 dual-output BENAR pakai render_deck (krn L626).

#### FIX (commit ini):
- scripts/deploy_academic_ppt_routing_fix.sh: append 1 direktif "ACADEMIC ROUTING PRECEDENCE" ke USER.md (idempotent + backup, NO restart). Isi: akademik WORD/makalah/laporan/mini-book -> academic-document-factory; akademik PPT/slides/sidang -> render_deck.py (+ dual-output kalau perlu dua versi); JANGAN PPT akademik ke academic-document-factory (DOCX-only) atau powerpoint+pptxgenjs/sharp (crash); humanizer SELALU pass terakhir.
- Bukan nulis ulang L624 (rawan) -- direktif presedensi yang menimpa, lebih aman.

#### STATUS & NEXT:
- BELUM TERBUKTI sampai deploy + uji /new: apakah PPT akademik polos sekarang konsisten ke render_deck (bukan pptxgenjs). DEPLOY: cd ~/jarvis && git fetch origin && git checkout fix/academic-ppt-routing && git pull && bash scripts/deploy_academic_ppt_routing_fix.sh ; lalu /new + "buatkan PPT sidang tentang X, editable" -> cek skill_view (harus render_deck, BUKAN powerpoint/pptxgenjs) + humanizer jalan.
- ROLLBACK: cp USER.md.bak.<ts> USER.md.
- SISA (prioritas lebih rendah): humanizer enforcement masih inkonsisten (ke-skip di run dual-output 12.23, nyala di run lain) -> pantau; web-grounding (B) subagent no-web; office-academic-skill + _src_academic redundan (bisa dihapus, academic-document-factory yg dipakai utk Word).
- Lensa: ini tuning routing (lapis SOFT), bukan bikin dokumen. Dokumen2 = probe tes.
