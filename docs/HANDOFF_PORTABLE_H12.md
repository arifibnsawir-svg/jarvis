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
