# Arsitektur & Flow

Dari pesan masuk sampai verdict. Balik ke [`START_HERE.md`](../START_HERE.md).

---

## Flow utama

```
USER (Telegram)
  │
  ▼
HERMES GATEWAY
  │
  ▼
SHADOW RESOLVER ......... log mismatch, non-blocking
  │
  ▼
ROUTING DECISION TABLE .. skill → forbidden paths
  │
  ▼
SEMANTIC ROUTER ......... pilih KAPABILITAS          [router/]
  ├─ L0 rule/regex .............. ~0ms
  ├─ L1 fastembed multiling ..... ~30ms  (sqlite-vec)
  └─ L2 groq-8b classifier ...... ~224ms (via 9router)
  │   confidence: threshold 0.75, margin top1−top2 ≥ 0.10
  ▼
9ROUTER @ :20128 ........ pilih KETERSEDIAAN (provider fallback chain)
  │
  ▼
EKSEKUSI + MEMORY LOOP                                [memory/, state/]
  ├─ BEFORE : retrieve context
  ├─ DURING : TaskState blackboard + ledger append-only
  └─ AFTER  : context-annotated ingestion → consolidate → dream cycle
  │
  ▼
ACTION GATE ............. boleh gak aksi ini dieksekusi   [action_gate/]
  │
  ▼
PIPA4 GATE (Python murni) ... 7 cek deterministik         [pipelines/pipa4/]
  │
  ▼
PIPA4 COUNCIL ........... LLM audit auto-fire via hook    [scripts/pipa4_hook.py]
  │
  ▼
VERDICT — cuma PIPA4 yang boleh set DONE
```

---

## Dua keputusan yang gampang ketuker

| | Semantic Router | 9router |
|---|---|---|
| Nanya | "Ini butuh kemampuan apa?" | "Model mana yang lagi hidup?" |
| Output | nama combo | provider konkret |
| Diatur di | `router/exemplars.py` | `combos.json` + dashboard |

---

## 9 branch → 4 combo

| Branch | Fungsi | Combo |
|---|---|---|
| R1 triage | chit-chat, intent | `jarvis-fast` |
| R2 coding | bedah kode, patch, log | `jarvis-coder` |
| R3 extract (PIPA1) | unstructured → JSON | `jarvis-reason` (temp=0, json_schema) |
| R4 writer (PIPA2) | draf panjang | `jarvis-longform` |
| R5 gate (PIPA4) | verdict deterministik | NONE — Python murni |
| R6 audit (PIPA3) | NLI reasoning | `jarvis-reason` (thinking mode) |
| R7 digest | ringkas dokumen besar | `jarvis-longform` |
| R8 vision | parse gambar/PDF | DEFERRED |
| R9 memory | RAG artefak historis | `jarvis-fast` + embedding |

---

## Empat prinsip anti-amnesia

1. **State di luar model** — TaskState blackboard, bukan ingatan LLM.
2. **Context capsule deterministik** — handoff bawa ringkasan fakta dari ledger, bukan history mentah.
3. **Authority deterministik** — cuma PIPA4 (Python) boleh set `DONE`; LLM cuma `proposed_status`.
4. **Ledger append-only** — sejarah gak bisa di-overwrite atau dihalusinasi.

---

## Memory 3 lapis

| Lapis | Umur | Isi |
|---|---|---|
| WORKING | 1 sesi | TaskState aktif |
| EPISODIC | decay | spekulasi 7h, keputusan 30h, fakta 90h |
| CRYSTALLIZED | permanen | aturan, pola, deliverable |

---

## FABLE vs MYTHOS

| | FABLE (default) | MYTHOS (`/mythos`) |
|---|---|---|
| Gate | ON | BYPASS |
| Output | disiplin | kreativitas liar |
| Neuro-Arc | standar | senjata |

Jalur naik kelas: `/crystallize` → review Arif → Lock → produksi.

---

## Batas repo

Document factory (SPEC → humanizer + citation + images → validate → render → gate) **tinggal di `Joki-tugas-`**, bukan di sini. Repo ini nyediain hook, gate, dan deploy script yang manggil factory itu.
