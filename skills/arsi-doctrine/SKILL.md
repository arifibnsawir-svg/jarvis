---
name: arsi-doctrine
description: "Aturan eksekusi Jarvis (A.R.S.I = Audit -> Rancang -> Sistemasi -> Iterasi). Aktifkan SETELAH neuro-arc menghasilkan TaskState, untuk tugas yang menghasilkan artefak atau butuh banyak langkah. Ini DOKTRIN/aturan cara kerja, BUKAN mesin (arsi engine = runtime terpisah). Inti loop self-healing: produksi, serahkan ke gate, baca vonis, perbaiki, ulang sampai gate lolos. LLM TIDAK PERNAH menyatakan DONE/PRODUCTION_READY; hanya gate (PIPA4) yang berwenang. Pakai kosakata status dari evidence-claim-status-guard."
category: core
version: 0.1.0
author: Arif
license: proprietary
metadata:
  layer: execution-discipline
  framework: ARSI
  follows: neuro-arc
  consumes: TaskState
  pairs_with: evidence-claim-status-guard
---

# A.R.S.I — Aturan Eksekusi (Doktrin, BUKAN Mesin)

## Overview
A.R.S.I adalah HUKUM cara Jarvis mengerjakan TaskState: **Audit -> Rancang -> Sistemasi -> Iterasi**.
Penting dibedakan:
- **A.R.S.I (skill ini)** = aturan/doktrin. Dipatuhi, tidak "berjalan".
- **arsi engine** = mesin/runtime (kode) yang menjalankan aturan ini. Punya PID, hidup/mati. BUKAN skill.
A.R.S.I mengonsumsi TaskState dari neuro-arc, lalu mengeksekusi sampai GATE (PIPA4) memvonis lolos.

## When to Use
- PAKAI: setelah neuro-arc, untuk artefak (dokumen/post/kode/PPTX), audit, atau tugas multi-langkah.
- LEWATI: jawaban trivial yang tak butuh produksi/verifikasi (adaptive depth — router yang menentukan).

## Empat Fase
1. **AUDIT** — observe before patch. Periksa state/kode/sumber kebenaran DULU. Kumpulkan bukti mentah,
   jangan tebak. Kalau 2x tebakan salah -> STOP, baca sumber langsung.
2. **RANCANG** — susun rencana/struktur berdasar TaskState (ukuran + relasi). Tentukan kriteria lolos
   yang TERUKUR (yang nanti dicek gate). Structure Before Render.
3. **SISTEMASI** — eksekusi terstruktur langkah demi langkah. Untuk artefak file: keluarkan spec dulu,
   render via tool deterministik (python-pptx/docx), jangan halu output.
4. **ITERASI (loop self-healing)** — inti "kebuasan":
   a. Serahkan hasil ke GATE (PIPA4).
   b. Baca VONIS gate (mentah) + daftar blocker.
   c. Kalau bukan PRODUCTION_READY -> baca blocker, PERBAIKI, ulang dari fase yang relevan.
   d. Re-gate. Ulang sampai gate lolos ATAU budget langkah habis.
   e. Budget habis tanpa lolos -> lapor status jujur (mis. NEEDS_*), JANGAN paksa "selesai".

## Authority & Status (wajib selaras dengan evidence-claim-status-guard)
- LLM hanya boleh mengusulkan `AWAITING_GATE`. Vonis `DONE` / `PRODUCTION_READY` / "lolos" =
  WEWENANG GATE deterministik (PIPA4, Python). Klaim DONE oleh LLM ditolak (PermissionError).
- Pakai mapping status existing: INSTALLED / ACTIVE / SMOKE_TESTED / BEHAVIOR_VALIDATED / READY /
  PRODUCTION_READY / PARKED / UNSAFE / UNKNOWN. Jangan bikin kosakata status baru.

## Saklar konteks
- `internal_research` / `code_patching` -> iterasi bebas, gate brand BYPASS.
- `public_social` / `book_draft` -> gate NYALA; iterasi sampai gate brand + measurable lolos.

## Pitfalls
- Lompat ke Rancang/Sistemasi tanpa Audit -> patch-by-guess.
- Iterasi tanpa kriteria terukur -> loop tak berujung / berhenti karena "rasa".
- LLM menyatakan selesai tanpa vonis gate -> False-READY (langgar authority).
- Menamai/menyamakan A.R.S.I dengan "arsi engine" -> campur aduk aturan vs runtime.
- Memaksa loop berat untuk tugas trivial -> over-engineering.

## Verification Checklist
- [ ] Audit dilakukan dengan bukti mentah sebelum perubahan apa pun.
- [ ] Kriteria lolos TERUKUR dan ditetapkan di fase Rancang.
- [ ] Output diserahkan ke gate; status diambil dari vonis gate, BUKAN klaim LLM.
- [ ] Loop iterasi berhenti karena gate lolos ATAU budget habis (lapor jujur), bukan karena asumsi.
- [ ] Tidak ada klaim DONE/PRODUCTION_READY yang tidak berasal dari gate.
