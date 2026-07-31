# Indeks Handoff & Checkpoint

Repo ini punya banyak dokumen handoff dari sesi berbeda. Ini urutan dan otoritasnya, biar lo gak baca yang basi. Balik ke [`START_HERE.md`](../../START_HERE.md).

---

## Mana yang harus dipercaya

Urutkan dari yang paling baru — **yang lebih baru menang** kalau bertentangan.

| Urutan | Dokumen | Tanggal | Isi |
|---|---|---|---|
| 1 (terbaru) | [`../progress-2026-07-10.md`](../progress-2026-07-10.md) | 10 Jul 2026 | Progress terakhir yang tercatat. |
| 2 | [`../INFRA-JALUR-B.md`](../INFRA-JALUR-B.md) | 7 Jul 2026 | Scrapling + agent-browser + n8n (Docker), bridge n8n→9router terverifikasi. |
| 3 | [`../../state/CHECKPOINT_20260704.md`](../../state/CHECKPOINT_20260704.md) | 4 Jul 2026 | Snapshot state. |
| 4 | [`../../HANDOFF_CHECKPOINT_2026-07-02_SESSION.md`](../../HANDOFF_CHECKPOINT_2026-07-02_SESSION.md) | 1–2 Jul 2026 | **Grand Design: 18 komponen + arsitektur akhir.** Paling berguna buat paham gambaran besar. |
| 5 | [`../../RESUME_HANDOFF.md`](../../RESUME_HANDOFF.md) | 1 Jul 2026 22:15 | Ringkasan padat 4 PIPA + aturan pemisahan repo. |
| 6 | [`../../HANDOFF_CHECKPOINT_2026-07-01_LANJUTAN.md`](../../HANDOFF_CHECKPOINT_2026-07-01_LANJUTAN.md) | 1 Jul 2026 | Lanjutan sesi. |
| 7 | [`../../HANDOFF_CHECKPOINT_2026-07-01.md`](../../HANDOFF_CHECKPOINT_2026-07-01.md) | 1 Jul 2026 | Checkpoint sesi. |
| 8 (tertua) | [`../../HANDOFF_CHECKPOINT.md`](../../HANDOFF_CHECKPOINT.md) | s/d 30 Jun 2026 | Arsip besar (~69 KB). Rujuk kalau butuh sejarah, jangan dibaca dari awal. |

Juga ada arsip di [`../checkpoints/`](../checkpoints).

---

## Kalau mau lanjut kerja

Baca **#4 (Grand Design)** buat gambaran besar, lalu **#1 dan #2** buat kondisi terkini. Sisanya cuma buat arkeologi.

---

## Catatan kerapian

`RESUME_HANDOFF.md` mengklaim dirinya "sumber kebenaran tunggal", tapi terakhir di-update 1 Jul — sementara ada empat dokumen yang lebih baru. Sebelum lanjut kerjaan, sebaiknya salah satu dilakukan:

- **update `RESUME_HANDOFF.md`** biar beneran jadi sumber tunggal, atau
- **turunkan statusnya** jadi arsip dan tunjuk `docs/progress-*.md` sebagai yang otoritatif.

Saran lanjutan: pindahkan keempat `HANDOFF_CHECKPOINT*.md` dari root ke `docs/handoff/` biar root cuma nyisain `START_HERE.md`, `README.md`, dan satu dokumen status yang hidup.
