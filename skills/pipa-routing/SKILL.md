---
name: pipa-routing
description: "Lapis ROUTER Jarvis (pilih jalur, JANGAN pernah blok input). Dipakai PALING AWAL pada tiap permintaan untuk menentukan KEDALAMAN dan PENDEKATAN sebelum NEURO-ARC/ARSI jalan. Skala effort ke bobot masalah (adaptive depth) - chat trivial dijawab langsung; riset/brainstorm internal mode bebas (gate BYPASS); tugas artefak/keputusan lewat NEURO-ARC lalu ARSI lalu gate PIPA4 (gate NYALA). Cocokkan pendekatan ke artifact_type - kode jadi coding; dokumen/slide/sheet jadi Structure-Before-Render (keluarkan spec lalu render+verify, JANGAN one-shot freehand); web/riset jadi cite-or-abstain (verifikasi sumber, jangan ngarang); audit/QA jadi gate deterministik. Router bukan gate - ringan, tidak memvonis, tidak menolak."
category: core
version: 0.1.0
author: Arif
license: proprietary
metadata:
  layer: routing
  framework: ARSI
  always_on: adaptive
  precedes: neuro-arc
  emits: RouteDecision
---

# PIPA-ROUTING — Lapis Router (Pilih Jalur, Jangan Blok)

## Overview
Router adalah hal PERTAMA yang jalan pada tiap input: ia memilih KEDALAMAN dan PENDEKATAN, lalu
menyerahkan ke lapis berikut. Prinsip kunci (separation of concerns): **router ringan dan TIDAK PERNAH
memblok/menolak input**; vonis "lolos/DONE" itu wewenang GATE (PIPA4), bukan router. Menggabung
router + gate = over-blocking (pelajaran Guardian lama). Router cuma mengarahkan.

Output router = **RouteDecision**: kedalaman (berapa banyak lapis dipakai) + pendekatan (cara kerja
sesuai artifact_type) + konteks (Fable/Mythos). Bukan jawaban, bukan vonis.

## When to Use
- PAKAI: pada SETIAP permintaan masuk, sebagai langkah nol. Murah dan cepat.
- Output-nya menentukan apakah NEURO-ARC + ARSI penuh dipakai, atau cukup jawaban langsung.

## Prosedur: scan niat -> pilih kedalaman -> pilih pendekatan
1. **SCAN NIAT** — baca permintaan apa adanya. Tentukan: ini obrolan, riset, atau minta artefak?
2. **PILIH KEDALAMAN (adaptive — jangan paksa 4-pipa):**
   - *Trivial* (sapaan, tanya fakta singkat, konfirmasi) -> jawab LANGSUNG. 0 pipa. Jangan
     nyalain mesin berat untuk input ringan (itu lambat + over-engineering).
   - *Riset / brainstorm internal* -> berpikir bebas, eksploratif. Gate brand BYPASS (Mythos-mode):
     boleh bahas ide mentah / sacred IP secara internal. Tetap jujur soal ketidakpastian.
   - *Tugas artefak / keputusan berisiko* -> jalur penuh: NEURO-ARC (struktur dulu) -> ARSI
     (Audit->Rancang->Sistemasi->Iterasi) -> GATE PIPA4 (Fable-mode, gate NYALA).
3. **PILIH PENDEKATAN (cocokkan ke artifact_type):**
   - *Kode / debug* -> mindset coding; minta error/konteks dulu sebelum nambal.
   - *Dokumen / slide / spreadsheet* -> **Structure-Before-Render**: keluarkan SPEC terstruktur
     (JSON/outline) lebih dulu, lalu render via tool (python-docx/pptx), lalu VERIFY file jadi.
     JANGAN one-shot freehand (itu sumber halu struktur & isi).
   - *Web / riset sumber* -> **cite-or-abstain**: cari -> ekstrak -> verifikasi sumber/URL resolve ->
     kutip dengan link. Kalau gak nemu bukti, bilang "belum nemu", JANGAN mengarang sumber/angka.
   - *Audit / QA / "apakah ini lolos?"* -> serahkan ke gate deterministik (PIPA4), bukan opini LLM.
4. **TETAPKAN KONTEKS (saklar Fable/Mythos)** untuk diteruskan ke TaskState:
   - `internal_research` / `code_patching` -> gate brand BYPASS.
   - `public_social` / `book_draft` -> gate NYALA.

## Catatan: routing perilaku vs routing model
Skill ini = routing PERILAKU (kedalaman + pendekatan), berlaku tanpa ubah infra. Routing MODEL
(ganti combo 9router per tugas: coder/longform/reason) itu lapis INFRA terpisah; jangan diasumsikan
aktif. Kalau infra itu belum ada, tetap pakai pendekatan yang benar pada combo default.

## Pitfalls
- Router memblok/menolak/menunda input -> SALAH. Itu kerjaan gate, bukan router. Router selalu lolos ke depan.
- Maksa semua input lewat 4-pipa penuh -> lambat, over-engineering. Hormati adaptive depth.
- One-shot dokumen/slide tanpa spec+render -> halu struktur/isi. Selalu Structure-Before-Render.
- Ngarang sumber web demi "kelihatan jawab" -> langgar cite-or-abstain. Lebih baik ngaku belum nemu.
- Menyatakan "selesai/lolos" di router -> DILARANG. Router tidak memvonis.

## Verification Checklist
- [ ] Sudah ditentukan: kedalaman (trivial / riset / artefak) sebelum lapis lain jalan.
- [ ] Pendekatan cocok dengan artifact_type (kode/dokumen/web/audit).
- [ ] Konteks Fable/Mythos di-set untuk TaskState.
- [ ] Untuk dokumen/slide: rencana Structure-Before-Render, bukan one-shot.
- [ ] Untuk web: komitmen cite-or-abstain (tidak mengarang sumber).
- [ ] Router tidak memblok/menolak input apa pun.
