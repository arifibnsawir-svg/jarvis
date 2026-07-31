# Peta Repo

Folder mana isinya apa, dan file mana yang penting. Balik ke [`START_HERE.md`](../START_HERE.md).

---

## Root

| File | Isi |
|---|---|
| `START_HERE.md` | Entry point. Baca duluan. |
| `README.md` | Desain asli: arsitektur router, tabel 9 branch → 4 combo, keputusan stack. |
| `RESUME_HANDOFF.md` | Ringkasan status sesi (update terakhir 1 Jul 2026 22:15). |
| `HANDOFF_CHECKPOINT*.md` | Checkpoint historis. Diindeks di [`handoff/README.md`](handoff/README.md). |
| `combos.json` | Source of truth 4 combo, ditranskrip manual ke dashboard 9router. |
| `router_config.json` / `.yaml` | Konfigurasi router. |

---

## Folder kode

### `router/` — pemilihan kapabilitas
| File | Fungsi |
|---|---|
| `router.py` | Cascade L0 (regex) → L1 (fastembed + sqlite-vec) → L2 (groq-8b classifier). |
| `exemplars.py` | Kalimat contoh per branch, Bahasa Indonesia. **Di sinilah lo nambah intent baru.** |

### `memory/` — ingatan lintas sesi
| File | Fungsi |
|---|---|
| `schema.sql` | Skema sqlite-vec: `route_exemplars` (routing) + `artifact_memory` (RAG R9). |
| `temporal_tiered_memory.py` | Memory 3 lapis: working → episodic (decay) → crystallized (permanen). |
| `jarvis_filing_protocol.md` | Aturan penyimpanan artefak. |

### `state/` — anti-amnesia
| File | Fungsi |
|---|---|
| `task_state.py` | Blackboard TaskState + ledger append-only. |
| `capsule.py` | Context capsule deterministik untuk handoff antar model. |
| `CHECKPOINT_20260704.md` | Snapshot state 4 Jul. |

### `pipelines/pipa4/` — gate deliverable
Jalur PIPA4: cek deterministik, evidence policy, constraint sadar-`doc_type` (akademik vs umum/bisnis/kreatif/personal).

### `action_gate/` — pembatas aksi agent
| File | Fungsi |
|---|---|
| `action_gate.py` | Logika gate utama. |
| `action_gate_rules.json` | **Aturan boleh/tidaknya sebuah aksi.** Edit di sini. |
| `gate_hook.py` | Hook `pre_tool_call`. |
| `lessons_logger.py` | Catat pelanggaran jadi pelajaran. |

### `guardian/` — penjaga mutu & brand
`guardian.py` + `brand_rules.json`.

### `plugins/` — komponen pasang-copot
`action_gate_v2/` (plugin `pre_tool_call`, masih mode shadow), `mistake_logger/` (mistake-memory deterministik).

### `skills/` — DNA perilaku
`pipa-routing/` (PIPA1–3 advisory), `neuro-arc/` (narasi → TaskState), `arsi-doctrine/` (Audit→Rancang→Sistemasi→Iterasi), `academic-search/` (sumber ilmiah terverifikasi, anti-halu), `pptx-slides-creation-guard/`.

### `renderer/`
Lapisan render output.

### `scripts/` — ~58 file, gerbang operasional
Pola penamaan yang konsisten:

| Prefiks | Arti | Contoh |
|---|---|---|
| `deploy_*.sh` | Pasang komponen ke Acer. Idempoten, marker-guarded. | `deploy_temporal_memory.sh` |
| `log_*.sh` | Rekam kejadian. | `log_action_gate_v2.sh` |
| `*_check.sh` / `verify_*` | Verifikasi. | `integrity_check.sh`, `proof_check.sh` |

File non-deploy yang penting: `pipa4_hook.py` (auto-fire council), `pipa4_gate.sh`, `jarvis_citation_helper.py`, `deep_analysis_evaluator.py`, `context_annotated_ingestion.py`, `dream_cycle.sh`, `crystallize_gateway.sh`, `model_health_check.sh`.

### `docs/`
`INFRA-JALUR-B.md` (Scrapling + agent-browser + n8n), `progress-2026-07-10.md`, `checkpoints/`, plus dokumen navigasi ini.

### `.kiro/`
Konfigurasi tooling.
