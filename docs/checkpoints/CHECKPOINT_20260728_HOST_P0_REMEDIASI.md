# CHECKPOINT: Remediasi Host P0 — 28 Juli 2026

**Tanggal:** 28 Juli 2026
**Sesi:** Remediasi Host P0, BUKAN Stage 4E
**Status:** Menunggu bukti Langkah 23 (pagi 29 Jul)

---

## Temuan: BACKUP-SILENT-FAIL

Dua sebab independen:

1. **Leash subprocess.run timeout 120 detik.** Fungsi `_run_script_process()` menggunakan `subprocess.run(timeout=120)`. Timeout ini membunuh proses anak langsung (bash), tetapi TIDAK membunuh cucu (tar). Akibatnya: script mati di 02:02:05, tetapi arsip tar selesai ditulis pada 03:58 — hampir dua jam kemudian, tanpa pengawasan scheduler.

2. **set -euo pipefail bertemu tar rc=1 pada "file changed as we read it".** Peringatan ini dari tar menghasilkan exit code 1. `set -e` menganggap rc=1 sebagai kegagalan fatal dan membunuh script sebelum baris sha256sum tercapai. Akibat: nol file .sha256 dari 55 arsip yang ada.

### Bukti proses yatim
- Job dimulai: 02:00 (berdasarkan `last_run_at`)
- Script dibunuh oleh timeout: 02:02:05
- mtime file arsip: 03:58 (berdasarkan `stat`)
- `subprocess.run` membunuh bash, bukan cucu tar.

---

## Temuan: SECRETS-WORLD-READABLE

- File `artefak_backup.sh` baris 15: `echo "Secrets included inside archive; do not share publicly."`
- Izin sebelum remediasi: direktori `drwxrwxr-x`, file `rw-rw-r--`
- Ditutup pada 28 Jul 15:02: direktori menjadi `drwx------` (700), file menjadi `-rw-------` (600)

---

## Data arsip

- Jumlah arsip: 55
- Total ukuran: 112,897,430,096 byte (~105 GiB)
- Nol file .sha256 sebelum sesi ini. Tiga sha256 dibuat 28 Jul untuk arsip terbaru (26, 27, 28 Jul).

---

## Perbaikan script: dua edit saja

1. **Penjaga TAR_RC:** Baris `|| TAR_RC=$?` ditambahkan setelah perintah tar, diikuti pengecekan: archive kosong (exit 1), tar rc > 1 (exit 1), dan logging `tar selesai rc=`. Rc=1 dari "file changed" tidak lagi membunuh script.
2. **Retensi:** `head -n -14` diubah menjadi `head -n -30` pada ketiga baris find. Arsip terlama (Juni) akan terhapus secara alami saat backup berikutnya berjalan penuh.

Backup lama: `artefak_backup.sh.PRE_P0_20260728_150304`

---

## Opsi C: systemd user timer

- **Service:** `hermes-artefak-backup.service` — Type=oneshot, ExecStart=artefak_backup.sh, TimeoutStartSec=4h
- **Timer:** `hermes-artefak-backup.timer` — OnCalendar=*-*-* 02:00:00, Persistent=true
- Izin kedua unit: `-rw-------` (600)
- Cron job `543737d9e6b1` dipause lewat CLI resmi (`hermes cron pause`). Status: enabled=False, state=paused.
- Linger sudah aktif sejak sebelum sesi ini (dibuktikan Langkah 20b).

---

## Temuan: GATE-NEVER-ENFORCED

- 70 blokir dari `action_gate`, semuanya fixture pengembangan tanggal 18 dan 19 Juli.
- Nol blokir produksi.
- Sebab: `ACTION_GATE_ENFORCE=refuse_only`. Penegakan tidak pernah dinyalakan. Tuas `full` masih utuh.

---

## Status blocker yang BELUM ditutup

| Blocker | Status | Catatan |
|---------|--------|---------|
| BACKUP-SILENT-FAIL | MENUNGGU BUKTI | Perlu bukti Langkah 23: arsip 30, sha256 30, log "tar selesai rc=" |
| SECRETS-WORLD-READABLE | DITUTUP | Izin 600/700 terpasang 28 Jul |
| BACKUP-NO-CHECKSUM | MENUNGGU BUKTI | 3 sha256 dibuat, 52 lainnya menunggu backup penuh pertama |
| BACKUP-RETENTION-DEAD | MENUNGGU BUKTI | Perlu bukti Langkah 23: arsip berkurang dari 55 ke 30 |
| BACKUP-NO-OFFSITE | RED | rclone diparkir atas keputusan Arif. Token Google Drive belum disambungkan. |
| GATE-NEVER-ENFORCED | DITAHAN | 70 blokir fixture, nol produksi. Tuas full utuh. |
| CRON-CANNOT-APPROVE | RED | Belum disentuh sesi ini |
| GATE-FAIL-OPEN | RED | Belum disentuh sesi ini |

---

## Gate 2 Stage 4E

TETAP RED. Tidak disentuh sesi ini.

## Tujuh job cron pipeline

Masih OFF sejak 26 Jul. Belum dipulihkan. Bukan scope sesi ini.

---

## Yang menunggu besok pagi (Langkah 23, setelah 04:00 WIB 29 Jul)

- arsip 30 (bukan 55)
- sha256 30
- log memuat "tar selesai rc="
- service Succeeded
- arsip tertua bukan Juni lagi

---

*Checkpoint ini berisi HANYA fakta yang terbukti dari sesi remediasi 28 Juli 2026.*
*Tidak ada klaim Stage 4E, tidak ada klaim go-live.*
