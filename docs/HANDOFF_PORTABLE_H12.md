# HANDOFF PORTABEL JARVIS H12

Dokumen ini ditulis untuk pembaca yang belum pernah melihat workspace Notion
manapun. Tidak ada kalimat di sini yang bergantung pada sumber luar.
Kalau Arif berpindah akun atau model, file ini saja cukup untuk melanjutkan.

## 0. Cara memakai dokumen ini

Urutan mengikuti design final Jarvis, bukan urutan sejarah penemuan.
Kalau waktu terbatas, baca Bagian 1 dan Bagian 11.

Tiga aturan membaca:
- Setiap angka status disertai tanggal dan cara pembuktiannya.
  Tanpa cara pembuktian, itu bukan fakta.
- Kata TERBUKTI hanya dipakai bila ada output mentah yang bisa diulang.
  Selain itu tertulis BELUM TERVERIFIKASI.
- Bila dokumen ini bertentangan dengan laporan Jarvis, dokumen ini yang
  menang sampai ada bukti mentah baru.

### 0.1 Cold start untuk agent baru
1. Baca Bagian 1 dan Bagian 2. Jangan dilewat.
2. Baca Bagian 11. Ada item yang tidak bisa dibatalkan.
3. Jangan jalankan perintah apa pun di host sebelum Arif memberi ACC
   eksplisit untuk perintah itu.
4. Jangan percaya laporan Jarvis mentah-mentah. Hitung ulang dari nol.
   Ini bukan sinisme. Auditor sendiri sudah 18 kali menarik kesimpulannya,
   dan laporan Jarvis berkali-kali terbukti melenceng.

## 1. Definisi SELESAI

Jarvis selesai bila berjalan sebagai sistem personal branding otonom yang
grounded, bukan bot posting. Delapan syarat, semuanya wajib:

1. Riset kompetitor dan tren berjalan otomatis dan hasilnya benar-benar
   menyuapi materi konten.
2. Materi hanya dari empat sumber sah: repo buku, riset web dan tren,
   data kompetitor, dan pengalaman nyata Arif yang terverifikasi.
   Ingatan Jarvis BUKAN sumber.
3. Setiap draft lewat Pos 1, Humanizer, Pos 2, Guardian, dengan kartu
   provenance yang mencatat asal tiap klaim.
4. Volume posting ditentukan dari data kompetitor terukur, bukan angka
   default satu per hari.
5. NIHIL adalah keluaran sukses. Hari tanpa bahan layak berarti tidak
   posting, dan itu benar.
6. Jumlah follower dilarang menjadi input keputusan konten. Boleh diukur
   dan dilaporkan, tidak boleh menjadi alasan membuat konten.
7. Reply engine berjalan dengan gate dua lapis.
8. Learning loop terkalibrasi pada data organik nyata, bukan data uji.

Syarat 5 dan 6 paling mudah dilanggar diam-diam, dan keduanya pembeda utama
Jarvis dari agent automation kebanyakan. Sistem yang mengejar follower akan
selalu menemukan alasan untuk posting. Sistem yang boleh mengatakan NIHIL
tidak.

## 2. Peran, transport, dan aturan keras

### 2.1 Siapa mengerjakan apa

| Pihak | Boleh | Dilarang |
|---|---|---|
| Arif | Memberi arah, ACC, keputusan akhir | - |
| Jarvis (di host Acer) | Patch, build, jalankan perintah yang sudah di-ACC, push ke GitHub | Memajukan state tanpa ACC, berinisiatif sendiri, mengubah harness/rubrik/regex agar winner lolos |
| Auditor (Notion AI atau model pengganti) | Audit independen, hitung ulang dari nol, baca repo read-only | Menulis ke host, mempercayai laporan Jarvis |

Loop resminya: Jarvis patch dan build di lokal, Arif merelay hasilnya,
auditor mengaudit independen, dan state hanya maju setelah Arif memberi
ACCEPT eksplisit.

### 2.2 Transport, sumber kekacauan yang paling sering

Jarvis tidak terhubung ke Notion. Alurnya Jarvis ke Telegram, Arif ke
Notion, manual. Auditor tidak dapat mengirim apa pun ke Jarvis langsung.

Bukti hanya lewat git, berlaku sejak 27 Jul 2026 pukul 17.10 WIB. Jarvis
menyimpan output mentah sebagai file di docs/evidence/<YYYYMMDD>/ lalu
menempelkan hanya sha256sum ke chat. Alasannya kanal Telegram terbukti
memotong isi panjang, dan potongan itu berulang kali ditambal dengan
tebakan.

Repo adalah CATATAN, bukan sumber kebenaran runtime. Sinkronisasi hanya
satu arah, dari LIVE ke repo. Jangan pernah memulihkan host dari repo
tanpa pemeriksaan terpisah.

### 2.3 Aturan keras pada host

- Hanya dua combo model yang boleh dipakai: jarvis-agent dan jarvis-reason.
  Combo ketiga bernama DailyFree sudah pensiun dan dilarang dihidupkan.
  Isolasi dilarang dilakukan dengan membuat atau mengganti nama combo.
- kill, pkill, dan killall DILARANG. Hanya systemctl --user stop.
- Urutan menghentikan layanan: Gateway lalu Guardian.
  Urutan memulihkan: Guardian lalu Gateway.
- Dilarang git push --force, gc, prune, reset, rebase, checkout.
- Dilarang menghapus, memotong, atau merotasi log apa pun.
- Dilarang menyentuh ~/.hermes/memories/.
- Dilarang menjalankan layanan di foreground.
- Dilarang menjalankan hermes gateway run di luar systemd.
- Dilarang mengedit ~/.hermes/cron/jobs.json secara langsung.
- Dilarang menyentuh atau menunda hermes-artefak-backup.timer.
- Dilarang mengubah HOSTNAME, unit file, atau guardian_router.py tanpa ACC.
- Dilarang menghidupkan kembali cron pipeline tanpa prosedur yang disetujui.
- Dilarang tcpdump, iptables, dan perubahan routing atau Tailscale.
- Jangan memakai curl pada port 9119 sebagai uji kesehatan gateway.
  Port itu milik dashboard. Uji yang benar:
  systemctl --user is-active hermes-gateway.service

### 2.4 Protokol laporan Jarvis

- FAKTA TERBUKTI berarti output mentah yang ditempel apa adanya.
- Kata terlarang: DONE, READY, LOLOS, PASS, TERKONFIRMASI, SELESAI,
  BERHASIL, dan sinonimnya seperti TUNTAS.
- Status tertinggi yang boleh ditulis adalah AWAITING_GATE.
- Data tidak ada ditulis verbatim sebagai
  DATA TIDAK TERSEDIA - TIDAK DIVERIFIKASI. Dilarang menebak.
- Satu verdict per pesan.
- Laporan wajib bahasa Indonesia. Output mentah tidak diterjemahkan.
- Bila sebuah langkah gagal, berhenti dan laporkan apa adanya.
  Dilarang memperbaiki sendiri atau melanjutkan ke langkah berikutnya.

## 3. Arsitektur: enam lapis, bukan empat

Master Plan menyebut empat stage. Itu benar untuk loop konten, tetapi tidak
lengkap sebagai peta sistem. Ada dua lapis lain yang nyata, punya kode, dan
punya penghambatnya sendiri.

| Lapis | Nama | Status per 29 Jul 2026 | Penghambat utama |
|---|---|---|---|
| 1 | Recon Engine | 70 persen | Cron di-pause, mesinnya sendiri pernah terbukti jalan penuh |
| 2 | Content Pipeline dan Gate | 35 persen | Gate 2 merah, jembatan materi repo ke Jarvis belum ada |
| 3 | Posting | 25 persen | Jalur B terpasang, kode poster nol |
| 4 | Engagement dan Reply | 10 persen | Spesifikasi lengkap sejak 7 Jul, kode nol |
| 5 | Learning Loop | 15 persen | DRAFT_NOT_CALIBRATED, evaluasi DISABLED |
| 6 | Governance | 57 persen | Gate menghitung benar tetapi tidak menahan |

Persentase di atas menggambarkan KEADAAN SEKARANG, bukan kemampuan tertinggi
yang pernah dicapai. Lapis 1 pernah berjalan penuh pada 19 Jul 2026: enam
target ter-scrape, semuanya MATCH, laporan harian terkirim dengan angka
asli. Yang mati sekarang hanya penjadwalnya. Ini penting agar tidak ada yang
membangun ulang sesuatu yang sudah jadi.

### 3.1 Keputusan terkunci, jangan dibuka lagi

- n8n TIDAK DIPAKAI. Dikunci 9 Jul 2026. Orkestrasi memakai Hermes native
  berupa cron, webhook, dan kanban dispatch. n8n diparkir, tidak dihapus.
- Tidak memakai Meta API. Jalur B berupa browser automation dan scraping
  adalah jalur utama, sehingga tidak memerlukan App Review. Wajib pelan dan
  memakai jeda yang natural seperti manusia.
- Jalur A berupa API resmi hanya opsional menyusul bila volume membesar.
- Skill lewat Composio atau Rube MCP DITOLAK karena jalannya lewat API resmi
  dan App Review, sehingga menabrak keputusan Jalur B.
- Dua skill Humanizer tetap terpisah dan tidak digabung, yaitu global
  strict-safe dan creative overlay.
- Winner Humanizer adalah Global atau Candidate A, dipilih Arif eksplisit
  pada 24 Jul 2026.
- Hanya dua combo: jarvis-agent dan jarvis-reason.
- URL tidak perlu dipublikasikan di dalam konten.
- Repo jarvis bersifat publik atas keputusan sadar Arif pada 29 Jul 2026,
  konsekuensinya dipahami. Ini bukan blocker.

### 3.2 Humanizer berjangkauan global

Humanizer melekat pada SELURUH output Jarvis, bukan hanya konten media
sosial. Cakupannya termasuk artefak, docfactory, tugas, laporan, deep
analysis, dan output umum.

Konsekuensinya keras: dilarang mempromosikan patch Humanizer yang hanya
diuji pada konten Threads. Setiap perubahan wajib melewati workspace
terisolasi dengan matriks kompatibilitas lintas kelas output, kontrol
negatif anti-halusinasi, uji preservasi format, canary per kelas output,
dan bukti rollback yang dapat diulang.

### 3.3 Empat sumber materi yang sah

1. Repo buku milik Arif, berisi naskah, framework, dan SOP kompetitor.
2. Riset web dan tren.
3. Data kompetitor hasil recon.
4. Pengalaman nyata Arif yang terverifikasi.

Ingatan Jarvis BUKAN sumber. Prinsip ini sudah punya wujud teknis berupa
state/task_state.py dengan pola blackboard, yang menyatakan bahwa kebenaran
hidup di struktur data, bukan di ingatan model.

## 4. Lapis 1: Recon Engine, 70 persen

### 4.1 Yang sudah terbukti berjalan

Ekstraksi jumlah follower memakai dua sumber sekaligus. Sumber primer
adalah JSON Relay pada jalur .__bbox.result.data.user.follower_count yang
memberi angka bulat eksak. Sumber pembanding adalah og:description dengan
toleransi pembulatan K, M, dan B. Bila keduanya berbeda di luar toleransi,
hasilnya di-FLAG dan TIDAK ditulis ke CSV.

Prinsipnya: lebih baik kosong daripada salah.

Pada 19 Jul 2026 seluruh rantai ini berjalan penuh. Enam target ter-scrape,
semuanya MATCH, dan laporan harian terkirim dengan angka asli. Akun Arif
tercatat 2 follower, dan angka itu hasil scrape sungguhan yang terverifikasi
dua sumber, bukan data contoh.

OCR sebagai jalur cadangan berstatus TERKUNCI dan tidak dipakai.

### 4.2 Watchlist

Seed penelitian mencatat 31 akun, terbagi menjadi Tier 1 sebanyak 22 akun,
Tier 2 sebanyak 6 akun, dan Tier 3 sebanyak 3 akun.

Watchlist operasional yang terkunci berisi 8 akun: productivityboi,
tommyteja, argitendo, rubyabdullah.ai, dimasyoga.pw, Raymond Chin,
Fellexandro Ruby, dan RevoU. Aturan tertulis pada watchlist ini adalah
JANGAN auto-reply.

Angka pembanding yang tercatat: hanifmuh_ 165991, lifeastechbro 128952,
tommyteja 118969, productivityboi 94048, dimasyoga.pw 65839, dan arifb.id 2.

Satu-satunya data irama posting yang pernah terukur adalah hanifmuh_ yang
kira-kira harian. Semua angka volume lain masih perkiraan.

### 4.3 Tiga modul

Modul A melakukan rotasi seed mingguan, mengambil 3 post per akun.
Modul B melakukan penemuan dinamis dengan penilaian tujuh dimensi, dan
mempromosikan akun secara otomatis setelah muncul 3 kali.
Modul C menambang register bahasa untuk disalurkan ke Humanizer.

Keluarannya berupa Hook Bank, amunisi balasan, dan digest mingguan.

### 4.4 Lima aturan anti-peniru

Aturan yang paling sering dilanggar adalah aturan 48 jam, yaitu dilarang
membahas sudut yang sama dengan kompetitor dalam 48 jam. Selain itu berlaku
uji pembeda dan uji Google lima menit, yaitu bila jawabannya bisa ditemukan
lewat pencarian lima menit maka konten itu tidak layak terbit.

### 4.5 Cara menjalankan

Virtual environment berada di ~/.hermes/recon-venv dengan Python 3.12.3.

cd /home/arif/.hermes/skills/devops/modular-competitive-monitoring
~/.hermes/recon-venv/bin/python3 scripts/run_monitoring.py \
  .../templates/monitoring-config-arif-competitors.yaml

### 4.6 Kenapa sekarang mati, dan apa yang harus diperbaiki lebih dulu

Blocker bernama RECON-DEAD. Tidak ada data masuk sejak 19 Jul 2026.

Dua cron yang bersangkutan berstatus paused, yaitu 179b39bf2020 bernama
competitor-recon-daily dan 647df6288f79 bernama daily-report. Keduanya
terakhir berjalan 26 Jul 2026 lalu berhenti serentak bersama enam job lain,
dan penghentian itu BUKAN dilakukan Arif.

Ada satu job lain bernama competitor_daily_monitor dengan id 8cacea44ccee
yang mati lebih awal, yaitu sejak 8 Jul 2026. Penyebabnya berbeda: tujuan
pengirimannya adalah whatsapp:arif budiman, dan platform itu tidak
terkonfigurasi. Barisnya sendiri berbunyi
delivery failed: platform 'whatsapp' not configured/enabled.

Konsekuensi praktis: menghidupkan kembali cron saja TIDAK cukup. Tujuan
pengiriman harus diperbaiki lebih dulu, jika tidak hasilnya akan jatuh ke
tujuan yang tidak ada.

Pemulihan wajib memakai perintah absolut yang deterministik, bukan prompt
kepada agent.
