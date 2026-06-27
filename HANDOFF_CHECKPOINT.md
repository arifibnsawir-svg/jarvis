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
