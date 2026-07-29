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

## 5. Lapis 2: Content Pipeline dan Gate, 35 persen

### 5.1 Rantai produksi delapan langkah

1. Pilih ide.
2. Terapkan lensa NEURO-ARC dan A.R.S.I.
3. Terapkan lensa strategi branding, yaitu 3 Pilar dengan bobot 60, 30, dan
   10, tangga nilai, kompas tujuan, dan 7 pakem.
4. Kumpulkan data grounding.
5. Susun draft transaksional, yaitu satu anchor menjadi 5 sampai 7 post
   Threads, satu carousel, dan satu reel.
6. Tambahkan sauce layer. WAJIB.
7. Lewatkan Humanizer. WAJIB dan tidak dapat dilewati.
8. Lewatkan Content Gate, lalu masuk outbox.

NEURO-ARC adalah singkatan Neural Orchestration and Relational Architecture
dengan tiga prinsip yaitu Representasi, Perspektif, dan Sistem. A.R.S.I.
adalah Audit, Rancang, Sistemasi, dan Iterasi.

Nada suara dikunci 6 Jul 2026: kata ganti cair, anti-hype, dan minimal satu
frasa tanda tangan seperti "Sistem bukan tools", "Arsitek bukan pengguna",
atau "Tools berubah framework abadi". Kalibrasi rasanya casual tetapi
kredibel.

### 5.2 Content Gate tiga lapis

Pos 1 memakai content_gate_rules.json bersama content_gate_pos1.py. Sifatnya
regex deterministik dan fail-closed. Pos 1 BUKAN LLM.

Pos 2 memakai content_gate_pos2.py. Di sinilah juri LLM dipanggil melalui
combo jarvis-reason ke Guardian pada 127.0.0.1 port 20129. Keluarannya
wajib JSON. Bila gagal, verdict jatuh ke REFUSE.

Guardian adalah lapis ketiga.

Delapan pemeriksaan gate: IP sakral, filter empat lapis, suara, anti-peniru
termasuk aturan 48 jam dan uji Google lima menit, anti-halusinasi, uji orang
asing, gerbang wawasan 3-YA, dan pertanyaan "ada take lo?".

Combo jarvis-reason berisi model flagship yaitu Opus 4.8, GPT 5.5, Mistral
Large 3, dan Qwen 3.5. Dikunci 6 Jul 2026 dan berlaku untuk SEMUA post.
Tujuannya agar konten benar-benar berbobot.

### 5.3 IP sakral yang otomatis ditolak

Daftar blokir mencakup kombinasi Februari 2024 dengan angka 847 ribu, klaim
347 prompt beserta rinciannya, angka pemulihan 12 jam menjadi 4 jam, klaim
omset naik 340 persen, sisa 12 dari 347, kalimat tentang kolektor prompt,
serta tokoh Riko, Citra, Adi, Dina, Ibu Sari, Pak Hendra, dan Prof. Bagus
Mulyadi.

Penegakannya lewat content_gate_rules.json versi 1.0.0 dengan tiga
mekanisme yaitu blocked_exact_phrases, blocked_regex_patterns, dan
blocked_characters_combination.

Sudut aman yang boleh dipakai: peta bukan wilayah, User lawan Architect,
kritik vibe-coding, AI sebagai mesin simulakrum, serta kolektor lawan koki
tanpa menyebut angka apa pun.

### 5.4 Gate 2, duduk perkaranya

Gate 2 BUKAN sekadar memilih skill. Memilih skill adalah Gate 1. Gate 2
mencakup penentuan council JSON dan juri, termasuk pemanggilan LLM, karena
itu bagian dari filter. Inilah sebabnya Gate 2 memanggil jarvis-reason.

Status: MERAH.

Akar masalahnya DUA cacat pada runner, bukan pada winner.

Cacat pertama, tiga literal isolasi yang dipaku di dalam kode, yaitu jalur
log pada baris 11 dan baris 137, serta endpoint pada baris 12. Runner tidak
membaca environment maupun argumen, sehingga tidak dapat dijalankan secara
terisolasi.

Cacat kedua, baris 315 membandingkan angka tetap 60 terhadap jumlah POST
fisik, padahal manifest berisi 60 RECORD. Satu percobaan ulang saja sudah
membuat hitungan menjadi 61 dari 60 dan sekaligus memunculkan satu baris
asing palsu.

Target yang sah setelah amandemen: verdict_match 30 dari 30, refuse_match
4 dari 4, dan distribusi 15 PASS, 11 REVISE, 4 REFUSE. Fixture h4_15
DIKUNCI pada REFUSE.

Dilarang keras mengubah harness, rubrik, regex, atau fixture agar winner
lolos. Bila winner gagal, yang gugur adalah winner, bukan alatnya.

### 5.5 Yang benar-benar belum ada

Jembatan dari empat sumber materi ke Jarvis belum dibangun. Repo buku,
hasil recon, dan riset tren belum tersambung otomatis ke langkah 4 pada
rantai produksi. Inilah alasan utama lapis ini berhenti di 35 persen.

## 6. Lapis 3: Posting, 25 persen

Jalur yang dipakai adalah Jalur B, yaitu browser automation dan scraping.
Bukan Meta API. Keputusan ini terkunci dan tidak perlu App Review.

Yang sudah ada: spesifikasi Stage 3 tertulis lengkap, dan perkakas browser
sudah terpasang di host.

Yang belum ada: kode poster itu sendiri. Nol baris. Blocker bernama
STAGE-3-POSTING-ZERO.

Kode poster DILARANG ditulis sebelum jendela remediasi host selesai dan
Arif memberi ACC. Alasannya sederhana: menulis kode posting saat gate belum
menahan berarti membangun jalan keluar sebelum penjaganya bekerja.

### 6.1 Pagar hari pertama posting

- Dua puluh post pertama WAJIB disetujui manual satu per satu oleh Arif.
- Harus tersedia kill switch satu perintah yang TIDAK me-restart gateway.
  Restart gateway memakan sekitar 210 detik dan pernah menggantung.
- NIHIL adalah keluaran sukses.
- Plafon volume diambil dari data kompetitor terukur, bukan angka default.
- Jumlah follower dilarang menjadi input keputusan konten.
- Kartu provenance wajib diarsipkan SEBELUM publikasi, bukan sesudah.

### 6.2 Tangga volume

Minggu pertama 2 post per hari. Minggu kedua 3 sampai 4 post per hari.
Minggu ketiga mengikuti median kompetitor.

Tangga ini TERBLOKIR oleh RECON-DEAD, karena median kompetitor belum
terukur. Satu-satunya data irama yang pernah ada adalah satu akun dengan
irama kira-kira harian. Angka 3 sampai 10 post per hari yang sering
disebut masih perkiraan, bukan hasil pengukuran.

## 7. Lapis 4: Engagement dan Reply, 10 persen

Spesifikasi Reply Engine versi 1 sudah ada sejak 7 Jul 2026 dan isinya
lengkap. Yang nol adalah kodenya. Blocker bernama STAGE-4-REPLY-ZERO.

Urutan yang dirancang: deteksi, susun draft, Humanizer yang tidak dapat
dilewati, Reply Gate, outbox, persetujuan Arif secara batch, lalu eksekusi
lewat browser agent dengan throttle.

Triase mengenal enam jenis balasan. Pos 1 memakai ulang
content_gate_rules.json. Pos 2 memakai juri jarvis-reason yang menilai
anti-halusinasi, kesesuaian suara, larangan rage-bait, uji orang asing, dan
kecocokan dengan tujuan. Verdict berupa OK, REVISE, atau REFUSE.

Catatan penting: watchlist kompetitor bertanda JANGAN auto-reply. Reply
engine tidak boleh menyasar delapan akun itu secara otomatis.

## 8. Lapis 5: Learning Loop, 15 persen

Status kalibrasi DRAFT_NOT_CALIBRATED dan evaluasi berstatus DISABLED.
Loop ini belum pernah melihat data organik nyata, karena memang belum ada
post organik.

Yang sudah selesai adalah fase rekonsiliasi. Rekonsiliasi fase 5 sampai 8
tuntas dengan 12 dari 12 lolos, 15 dari 15 terverifikasi, dan 99 dari 99
lolos. R01 terkunci pada versi 3. R06 menyelesaikan 8 pengujian. R12
menyelesaikan 17 dari 17 dan 99 dari 99.

R09 berstatus RETIRED setelah sebelumnya menunggu ACC Arif.

R14 mengenal empat status yaitu INSUFFICIENT_DATA, WATCH, WINNER_ELIGIBLE,
dan QUARANTINE_ELIGIBLE.

Konsekuensi yang harus dipahami: seluruh angka di atas berasal dari data
uji, bukan data lapangan. Learning loop tidak dapat naik dari 15 persen
sampai ada post organik nyata yang bisa dipelajari. Urutannya tidak bisa
dibalik.

## 9. Lapis 6: Governance, 57 persen

### 9.1 Lubang utama: gate menghitung benar, tetapi tidak menahan

Ini temuan terpenting pada lapis governance, dan sudah TERBUKTI dari skema
data, bukan dari laporan.

Pada berkas keputusan action_gate/decisions.jsonl terdapat entri dengan
tool bernama cronjob, verdict NEEDS_APPROVAL, action_class IMPACT_HEAVY,
dan alasan "ubah cron/scheduler". Pada entri yang sama tertulis
requires_approval bernilai true dan would_block bernilai true, TETAPI
allow_execution juga bernilai true.

Artinya sistem tahu tindakan itu seharusnya ditahan, mencatatnya dengan
benar, lalu tetap membiarkannya berjalan.

Penyebabnya adalah mode penegakan. ACTION_GATE_MODE bernilai live, tetapi
ACTION_GATE_ENFORCE bernilai refuse_only. Selain itu gate_hook.py bersifat
fail-open pada baris 113 yang mengembalikan nilai izin ketika terjadi
kesalahan.

Blocker: GATE-NEVER-ENFORCED dan GATE-FAIL-OPEN.

### 9.2 Urutan memperbaikinya, jangan dibalik

1. Perbaiki jalur persetujuan untuk cron, karena cron saat ini tidak dapat
   meminta persetujuan sama sekali. Blocker CRON-CANNOT-APPROVE.
2. Ubah gate_hook.py baris 111 dan 113 menjadi fail-closed.
3. Jalankan canary dengan kontrol positif, yaitu satu tindakan yang memang
   HARUS ditolak, untuk membuktikan penolakan benar terjadi.
4. Baru setelah ketiganya lolos, ubah ACTION_GATE_ENFORCE menjadi full.

Dilarang menyasar decision_mode sebagai jalan pintas. Yang salah bukan mode
keputusan, melainkan penegakannya.

### 9.3 Batas kepercayaan pada bukti lama

Angka 225 dari 225 untuk Action-Gate v2 TIDAK BOLEH disajikan sebagai bukti
terkini. Rinciannya adalah core approval 203 dari 203 dan plugin hooks 3
dari 3, dan lineage keduanya sudah dinyatakan tidak dapat dipulihkan.

Pemeriksaan pada 29 Jul 2026 memperkuat hal ini. Berkas bernama
INTEGRATION_MAP_20260718_ACTIONGATE_V2_CORE_APPROVAL.md ternyata berisi peta
komponen mode read-only, bukan catatan hasil uji. Pencarian angka 203 di
dalamnya menghasilkan nol.

Yang masih sah sebagai bukti segar hanyalah bridge 19 dari 19.

Status resmi A4: OPERATIONALLY ACCEPTED dengan catatan HISTORICAL
CORE/PLUGIN LINEAGE GAP. Penegakan sudah dikembalikan ke refuse_only.

### 9.4 Gerbang lain yang sudah ada

Deep Analysis Gate berstatus HARD-enforced dengan tanda terima dan ledger
berbasis HMAC-SHA256 beserta verifikatornya.

PIPA4 bersifat fail-closed dengan batasan doc_type yang dinamis, dan
memakai pola isolasi per proses jalan.

## 10. Kontrak go-live: tujuh gerbang

Dikunci pada Master Plan tertanggal 24 Jul 2026.

| Gerbang | Isi | Status |
|---|---|---|
| 1 | Winner sah dan hijau | HIJAU |
| 2 | Regresi penuh tanpa cacat | MERAH |
| 3 | Promosi reversibel dan latihan rollback | HIJAU BERSYARAT |
| 4 | Nol sentuhan pada ~/.hermes/skills/** | HIJAU |
| 5 | Canary | BELUM DIJALANKAN |
| 6 | Tidak ada yang rusak | SEBAGIAN |
| 7 | Token dan IP tidak berubah | HIJAU |

Catatan pada gerbang 3: keadaan akhir runtime bersifat self-attested. Yang
benar-benar dihitung ulang hanyalah berkas di dalam arsip. Eksekusi promote
dan rollback yang sesungguhnya di dalam ~/.hermes tidak pernah dapat
diperiksa dari luar host. Bukti pendukungnya kuat, tetapi itu bukan
verifikasi.

Gerbang 2 adalah satu-satunya yang MERAH, dan gerbang itulah yang menahan
go-live. Perlu dipahami dengan tepat: Gate 2 menahan PROMOSI kandidat baru,
bukan PEMAKAIAN apa yang sudah hidup sekarang.
