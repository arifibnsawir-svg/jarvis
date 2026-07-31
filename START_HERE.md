# START HERE — Jarvis Tuning

> Entry point repo ini. Kalau lo (atau sesi AI baru) mau lanjut kerjaan, baca file ini dulu — 3 menit — baru lompat ke dokumen lain.

---

## 1. Repo ini apa

`jarvis` = **INFRA / TUNING**. Isinya router, memory, gate, plugin, skill, dan deploy script untuk ekosistem Monster Jarvis yang jalan di server lokal (Acer, via Tailscale), diakses lewat Hermes Gateway (Telegram).

## 2. Repo ini BUKAN apa

Ada repo kedua: **`Joki-tugas-` = FACTORY / PRODUKSI** (renderer, gate, SPEC, contoh deliverable, `jarvis_document_factory/`).

**Aturan yang udah dikunci: jangan campur dua repo ini.**

| | `jarvis` | `Joki-tugas-` |
|---|---|---|
| Peran | infra, tuning, scripts, deploy, handoff | skill produksi dokumen |
| Isi khas | router, memory, action_gate, guardian, pipa4_hook | validate_spec, renderer, word-count, citation |

Kalau lo mau ubah cara dokumen **diproduksi** → itu di `Joki-tugas-`. Kalau lo mau ubah cara request **dirutekan, diingat, atau digate** → itu di sini.

## 3. Urutan baca yang disarankan

1. **`START_HERE.md`** ← lo di sini
2. **[`docs/MAP.md`](docs/MAP.md)** — folder mana isinya apa, file kunci di mana
3. **[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)** — flow end-to-end, dari pesan Telegram sampai verdict DONE
4. **[`docs/RUNBOOK.md`](docs/RUNBOOK.md)** — perintah deploy + kill-switch
5. **[`docs/handoff/README.md`](docs/handoff/README.md)** — riwayat sesi, mana checkpoint yang otoritatif
6. **[`README.md`](README.md)** — desain asli router + tabel 9 branch → 4 combo

## 4. Empat konsep yang wajib dipahami sebelum ngoding

- **Router 2 layer** — Semantic Router milih *kapabilitas*, 9router milih *ketersediaan provider*. Dua keputusan berbeda, jangan digabung.
- **PIPA1–4** — PIPA1 extract, PIPA2 writer, PIPA3 audit, PIPA4 gate. Cuma **PIPA4 (Python murni)** yang boleh nyetel status `DONE`. LLM cuma boleh ngajuin `proposed_status`.
- **Anti-amnesia** — state hidup di `state/` dan `memory/`, bukan di ingatan model. Ledger append-only, gak boleh di-overwrite.
- **FABLE vs MYTHOS** — FABLE = output disiplin, gate ON (default). MYTHOS = eksplorasi liar, gate bypass. Perpindahan ke produksi lewat crystallization gateway.

## 5. Kondisi terkini (per commit `main` 13 Jul 2026)

**Jalan & terverifikasi:** document factory + PIPA4 gate 7-cek + council auto-fire, academic-search, action-gate v2, mistake-logger, shadow resolver, temporal tiered memory, dream cycle, infra Jalur B (Scrapling + agent-browser + n8n Docker, bridge n8n→9router).

**Masih terbuka:** transkrip 4 combo ke dashboard 9router (manual), sub-agent architecture, action-gate v2 masih mode shadow (nunggu GO).

> ⚠️ **Peringatan konsistensi.** Checklist Status di `README.md` masih nandain PIPA4 Gate, router module, dan TaskState sebagai *belum jadi* — padahal `state/task_state.py`, `pipelines/pipa4/`, dan `action_gate/` udah ada isinya dan checkpoint Juli nyatain VERIFIED. **Percayai `docs/handoff/` + kode, jangan checklist README.** Belum gua ubah karena status live di Acer cuma bisa lo konfirmasi sendiri.

## 6. Mau lanjut kerja? Mulai dari sini

| Tujuan | Buka |
|---|---|
| Nambah/ubah rute intent | `router/exemplars.py` lalu `router/router.py` |
| Ubah aturan lolos/gagal deliverable | `pipelines/pipa4/`, `scripts/pipa4_hook.py` |
| Ubah apa yang boleh dieksekusi agent | `action_gate/action_gate_rules.json` |
| Ubah cara Jarvis inget sesuatu | `memory/temporal_tiered_memory.py`, `memory/schema.sql` |
| Deploy perubahan ke Acer | `docs/RUNBOOK.md` |
| Matiin komponen yang ngamuk | `docs/RUNBOOK.md` → Kill-switch |
