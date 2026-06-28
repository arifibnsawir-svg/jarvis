---
name: neuro-arc
description: Lapis berpikir/representasi Jarvis (think-first). Aktifkan SEBELUM mengeksekusi tugas apa pun yang menghasilkan artefak atau keputusan berisiko. Ubah narasi/permintaan mentah menjadi struktur terukur dengan urutan narasi -> entitas -> ukuran -> relasi -> output, lalu baru bertindak. Pakai untuk task nyata; LEWATI untuk sapaan atau tanya-jawab trivial (adaptive depth). Output skill ini = TaskState terstruktur yang jadi pegangan eksekusi (A.R.S.I) dan sumber assert gate (PIPA4). Jangan pernah reasoning di atas narasi mentah.
category: core
version: 0.1.0
author: Arif
license: proprietary
metadata:
  layer: representation
  framework: NEURO-ARC
  always_on: adaptive
  precedes: arsi
  emits: TaskState
---

# NEURO-ARC — Lapis Representasi (Think-First)

## Overview
NEURO-ARC adalah cara Jarvis MEMAHAMI sebelum BERTINDAK. Ia bukan mesin dan bukan aturan eksekusi
(itu A.R.S.I / arsi engine). Ia lapis representasi: mengubah permintaan mentah menjadi struktur
terukur sebelum satu baris output pun ditulis. Prinsip: "Structure Before Reasoning" — jangan menalar
di atas narasi mentah, normalkan ke struktur dulu.

Output NEURO-ARC = **TaskState** (blackboard) yang dipakai dua arah:
- ke bawah: A.R.S.I mengeksekusi TaskState (Audit->Rancang->Sistemasi->Iterasi).
- ke gate: "ukuran" jadi bahan assert deterministik PIPA4 (tanpa ukuran, gate tak punya pegangan -> risiko False-READY).

## When to Use
- PAKAI: tugas yang menghasilkan artefak (dokumen/post/kode/PPTX), keputusan berisiko, audit,
  perencanaan multi-langkah, atau apa pun yang nanti lewat gate.
- LEWATI (adaptive): sapaan, tanya-jawab faktual singkat, konfirmasi sepele. Jangan paksa mesin berat
  untuk input ringan (itu pemborosan + lambat). Router yang menentukan kedalaman.

## Prosedur: narasi -> entitas -> ukuran -> relasi -> output
1. **NARASI** — tangkap permintaan mentah apa adanya (bahasa natural user). Jangan tafsir dulu.
2. **ENTITAS** — daftar objek/aktor konkret yang terlibat (siapa, apa, dokumen/sistem mana).
3. **UKURAN** — ekstrak dimensi TERUKUR: target, constraint, metrik, audiens, jumlah, deadline,
   artifact_type, format. Ini yang nanti bisa di-assert gate. Audiens -> dasar voice DINAMIS (jangan hardcode).
4. **RELASI** — petakan hubungan antar entitas (apa tergantung apa, urutan, struktur/graf).
5. **OUTPUT** — tetapkan bentuk deliverable yang dituju + kriteria "selesai" yang TERUKUR (bukan rasa).
=> Rakit semua menjadi TaskState. Baru serahkan ke A.R.S.I untuk dieksekusi.

## Saklar konteks (Fable/Mythos)
Tentukan target di TaskState:
- `internal_research` / `code_patching` -> mode bebas, gate brand BYPASS (boleh bahas sacred IP).
- `public_social` / `book_draft` -> gate NYALA; ukuran harus cukup kaya untuk di-assert.

## Pitfalls
- Reasoning/menulis sebelum struktur jadi -> output ngawur, gate tak bisa verifikasi.
- "Ukuran" kosong/kabur -> gate tidak punya pegangan -> jatuh ke klaim LLM (False-READY).
- Memaksa semua input lewat NEURO-ARC penuh -> lambat, over-engineering. Hormati adaptive depth.
- Hardcode voice/pronoun -> langgar aturan; voice harus diturunkan dari ukuran.target_audience.
- Menyatakan "selesai/siap" di sini -> DILARANG. NEURO-ARC hanya merepresentasikan, bukan memvonis.

## Verification Checklist
- [ ] TaskState punya minimal: narasi, entitas, ukuran (>=1 terukur), relasi, output.
- [ ] Ada artifact_type + target (konteks) yang jelas.
- [ ] Kriteria "selesai" bersifat TERUKUR (bisa dicek gate), bukan subjektif.
- [ ] Tidak ada klaim status DONE/READY di lapis ini.
- [ ] Untuk input trivial: skill ini dilewati (adaptive), bukan dipaksakan.
