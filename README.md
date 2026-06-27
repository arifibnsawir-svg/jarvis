# Monster Jarvis — Router + PIPA Orchestration

Personal AI ecosystem di server lokal (Acer), interface via Hermes Gateway (Telegram).
Arsitektur 2-layer: **Semantic Router** (pilih kapabilitas) → **9router Combo** (pilih ketersediaan).

## Arsitektur

```
Telegram -> Hermes Gateway -> Router (lokal, Acer)
                                |- L0 rule/regex        (~0ms)
                                |- L1 fastembed multiling (~30ms, sqlite-vec)
                                |- L2 groq-8b classifier  (~224ms, via 9router)
                                      |
                                      v  (nama combo)
                              9router @ :20128 -> provider fallback chain
                                      |
                              TaskState (blackboard) + sqlite-vec memory
                                      |
                              PIPA4 Gate (Python murni = authority "DONE")
```

## 9 Router Branches -> 4 Combos

| Branch | Fungsi | Combo |
|--------|--------|-------|
| R1 triage | chit-chat, intent | `jarvis-fast` |
| R2 coding | bedah kode, patch, log | `jarvis-coder` |
| R3 extract | unstructured -> JSON (PIPA1) | `jarvis-reason` (temp=0, json_schema) |
| R4 writer | draf panjang (PIPA2) | `jarvis-longform` |
| R5 gate | verdict deterministik (PIPA4) | NONE (Python murni) |
| R6 audit | NLI reasoning (PIPA3) | `jarvis-reason` (thinking mode) |
| R7 digest | ringkas dokumen besar | `jarvis-longform` |
| R8 vision | parse gambar/PDF | DEFERRED (test endpoint dulu) |
| R9 memory | RAG artefak historis | `jarvis-fast` (synth) + embedding |

## Keputusan stack (locked)

- **Embedding L1**: fastembed multilingual (CPU Acer). MiniLM-L12-multilingual / e5-small. NOT BGE-en (English-only, bakal misroute konten ID).
- **Vector store**: SQLite + sqlite-vec. Dua koleksi: `route_exemplars` (routing) + `artifact_memory` (R9 RAG).
- **Confidence**: threshold 0.75 + margin 0.10 (top1 - top2). Kalibrasi pakai 50 log Telegram historis.

## Prinsip anti-amnesia

1. **State di luar model** — TaskState blackboard, bukan ingatan LLM.
2. **Context capsule deterministik** — handoff antar model bawa ringkasan dari ledger (fakta), bukan history mentah.
3. **Authority deterministik** — HANYA PIPA4 (Python) boleh set status=DONE. LLM cuma `proposed_status`.
4. **Append-only ledger** — sejarah gak bisa di-overwrite/halusinasi.

## Layout

```
jarvis/
  combos.json        # source of truth 4 combo (transkrip ke 9router dashboard)
  router/
    router.py        # cascade L0->L1->L2
    exemplars.py     # kalimat contoh per branch (Bahasa Indonesia)
  memory/
    schema.sql       # sqlite-vec: route_exemplars + artifact_memory
  state/
    task_state.py    # blackboard TaskState + append-only ledger (TODO)
  gate/
    pipa4_gate.py    # deterministic verdict gate (TODO)
```

## Status

- [x] Provider farming + verifikasi (16 provider, 225 model PASS)
- [x] 4 combo design (verified models)
- [ ] Transkrip combo ke dashboard  <- LAGI DIKERJAIN (manual)
- [ ] Router module (L0/L1/L2)       <- scaffold ada, perlu flesh-out + test di Acer
- [ ] TaskState + ledger
- [ ] PIPA4 Gate
- [ ] Wiring ke Hermes
