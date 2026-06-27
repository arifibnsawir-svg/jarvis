"""
Route exemplars per branch (Bahasa Indonesia + istilah teknis campur).

Layer 1 embedding router membandingkan pesan masuk dengan exemplar ini via cosine.
Tambah/kurangi contoh berdasarkan 50 log Telegram historis saat kalibrasi.

Target: 10-20 exemplar per branch yang beragam (formal, slang, singkat, panjang).
"""

EXEMPLARS = {
    "R1_triage": [
        "halo jarvis",
        "lagi apa bro",
        "makasih ya",
        "oke siap",
        "tolong bantu dong",
        "kamu bisa apa aja sih",
        "test ping",
        "pagi, gimana kabar sistem",
    ],
    "R2_coding": [
        "tolong bedah error ini",
        "kenapa fungsi ini gagal",
        "perbaiki bug di script python ini",
        "ini stacktrace-nya, fix dong",
        "refactor kode ini biar lebih bersih",
        "tambahin error handling di sini",
        "jalanin perintah terminal ini dan jelasin outputnya",
        "kenapa npm install gagal",
        "tulis fungsi buat parsing file csv",
        "patch file config ini",
    ],
    "R3_extract": [
        "ubah teks ini jadi JSON",
        "ekstrak data dari dokumen ini ke struktur baku",
        "ambil nama, tanggal, nominal dari invoice ini",
        "parse paragraf ini jadi field terstruktur",
        "konversi tabel ini ke format schema",
        "ekstrak entitas dari teks mentah",
        "rapikan data acak ini jadi key-value",
    ],
    "R4_writer": [
        "buatin draf artikel tentang ini",
        "tulis email formal ke klien",
        "bikin caption panjang buat postingan",
        "kembangkan poin-poin ini jadi paragraf",
        "tulis ringkasan eksekutif dari proyek ini",
        "buatkan proposal singkat",
        "drafting konten blog 1000 kata",
    ],
    "R5_gate": [
        "audit dokumen ini sekarang",
        "jalankan QA final",
        "cek apakah semua constraint terpenuhi",
        "verifikasi hasil akhir",
        "render final dan kasih verdict",
        "validasi deterministik",
    ],
    "R6_audit": [
        "apakah kesimpulan ini logis",
        "cek konsistensi argumen di teks ini",
        "ini beneran udah selesai atau belum",
        "evaluasi apakah klaim ini didukung bukti",
        "reasoning ini ada cacat logika gak",
        "bandingkan dua versi ini mana yang konsisten",
        "telaah apakah draf memenuhi syarat",
    ],
    "R7_digest": [
        "ringkas dokumen panjang ini",
        "rangkum percakapan sepanjang ini",
        "tarik poin penting dari file besar ini",
        "kasih TL;DR dari thread ini",
        "kompres riwayat ini jadi ringkasan",
    ],
    "R8_vision": [
        "ini screenshot, tolong jelasin",
        "baca teks di gambar ini",
        "analisa diagram di foto ini",
        "apa isi gambar ini",
        "ekstrak data dari tabel di screenshot",
    ],
    "R9_memory": [
        "inget gak kemarin kita ngerjain apa",
        "apa yang udah pernah dibahas soal proyek X",
        "cari artefak lama soal topik ini",
        "kita dulu mutusin apa soal ini",
        "ada history-nya gak",
    ],
}
