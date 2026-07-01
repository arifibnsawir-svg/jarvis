#!/usr/bin/env python3
"""
Relevance filter untuk hasil pencarian academic-search.

Masalah yang diatasi (RESUME Bagian 6 #1): verify_citations.py cuma memastikan
DOI *resolve* (sumber ADA), TIDAK cek apakah sumbernya RELEVAN dengan topik.
Akibatnya sumber tangensial (DOI valid tapi beda topik) lolos ke daftar pustaka.

Script ini skoring relevansi tiap hasil terhadap topik/keywords (judul dibobot
lebih tinggi dari abstrak), lalu memisahkan RELEVAN vs TANGENSIAL (perlu cek
manual / cari ganti). Stdlib-only (no deps), Indonesia-friendly: substring match
menangani imbuhan ('belajar' cocok dengan 'pembelajaran').

INI FILTER RELEVANSI, BUKAN pengganti verify. Alur tetap:
search -> konsolidasi -> RELEVANCE FILTER (ini) -> verify DOI -> cite-only-verified.
Skor yang ditulis (relevance_score) juga dipakai search_databases.py --rank relevance.

Exit: 0 = ada >= min-relevant sumber relevan; 1 = kurang dari itu (jangan paksa,
cari lagi / longgarkan kata kunci); 2 = input tak terbaca / bukan JSON / tanpa topik.

Usage:
  relevance_filter.py results.json --topic "Pengaruh media sosial terhadap prestasi belajar mahasiswa"
      [--keywords "media sosial,prestasi belajar,mahasiswa"]
      [--min-score 0.30] [--min-relevant 3]
      [--out filtered.json] [--drop] [--json]
  relevance_filter.py --selftest
"""
from __future__ import annotations

import json
import re
import sys

# Stopword Indonesia + Inggris (ringkas; termasuk kata generik riset yang
# nyaris selalu muncul di judul akademik sehingga tak informatif buat relevansi).
_STOP = {
    # ID umum
    "yang", "dan", "di", "ke", "dari", "untuk", "pada", "dengan", "atau", "dalam",
    "adalah", "itu", "ini", "sebagai", "oleh", "akan", "juga", "agar", "serta",
    "antara", "terhadap", "para", "suatu", "secara", "tidak", "bukan", "karena",
    "tentang", "kepada", "bagi", "dll", "dsb",
    # ID generik-riset
    "studi", "penelitian", "analisis", "pengaruh", "hubungan", "faktor", "peran",
    "kajian", "tinjauan", "jurnal", "artikel",
    # EN
    "the", "a", "an", "of", "and", "or", "to", "for", "in", "on", "with", "by",
    "is", "are", "study", "analysis", "effect", "impact", "influence", "role",
    "relationship", "factor", "toward", "towards", "among", "between", "based",
    "using", "use", "case", "review",
}


def _tokens(text):
    """Tokenize -> lowercase, buang non-alfanumerik, drop token pendek + stopword."""
    if not text:
        return []
    text = re.sub(r"[^a-z0-9]+", " ", str(text).lower())
    return [w for w in text.split() if len(w) >= 3 and w not in _STOP]


def keywords_from(topic, extra):
    """Bangun daftar kata kunci unik dari --topic (+ opsional --keywords)."""
    kws, seen = [], set()

    def add(tok):
        if tok and tok not in seen:
            seen.add(tok)
            kws.append(tok)

    for t in _tokens(topic):
        add(t)
    if extra:
        for chunk in extra.split(","):
            for t in _tokens(chunk):
                add(t)
    return kws


def _match(kw, toks):
    """Cocok kalau sama, atau saling-substring (tangani imbuhan Indonesia)."""
    for t in toks:
        if kw == t or kw in t or t in kw:
            return True
    return False


def score_result(result, keywords):
    """Skor 0..1: 0.6*coverage + 0.4*title_coverage. Judul dibobot lebih tinggi."""
    if not keywords:
        return 0.0, 0
    title_toks = _tokens(result.get("title", ""))
    body_toks = _tokens(
        " ".join(str(result.get(k, "")) for k in ("abstract", "journal", "source"))
    )
    matched = 0
    title_matched = 0
    for kw in keywords:
        in_title = _match(kw, title_toks)
        in_body = _match(kw, body_toks)
        if in_title:
            title_matched += 1
        if in_title or in_body:
            matched += 1
    n = len(keywords)
    coverage = matched / n
    title_cov = title_matched / n
    return round(0.6 * coverage + 0.4 * title_cov, 4), matched


def filter_results(results, keywords, min_score):
    scored = []
    for r in results:
        s, matched = score_result(r, keywords)
        r = dict(r)
        r["relevance_score"] = s
        r["relevance_matched"] = matched
        r["relevant"] = s >= min_score
        scored.append(r)
    scored.sort(key=lambda x: x["relevance_score"], reverse=True)
    relevant = [r for r in scored if r["relevant"]]
    tangensial = [r for r in scored if not r["relevant"]]
    return scored, relevant, tangensial


def _run_selftest():
    kws = keywords_from("Pengaruh media sosial terhadap prestasi belajar mahasiswa", None)
    data = [
        {"title": "Dampak Media Sosial terhadap Prestasi Belajar Mahasiswa",
         "abstract": "penggunaan media sosial dan hasil belajar mahasiswa"},
        {"title": "Sejarah Kopi Nusantara di Abad ke-19",
         "abstract": "perdagangan kopi era kolonial"},
        {"title": "Pembelajaran daring dan motivasi mahasiswa",
         "abstract": "media sosial sebagai kanal pembelajaran"},
    ]
    scored, relevant, tangensial = filter_results(data, kws, 0.30)
    ok = True
    ok = ok and scored[0]["title"].startswith("Dampak Media Sosial")
    kopi = [r for r in scored if "Kopi" in r["title"]][0]
    ok = ok and (kopi["relevant"] is False)
    ok = ok and len(relevant) >= 2
    print("SELFTEST:", "PASS" if ok else "FAIL")
    print("  keywords:", kws)
    for r in scored:
        print(f"  score={r['relevance_score']:.2f} relevant={r['relevant']} :: {r['title']}")
    return 0 if ok else 1


def main(argv):
    if "--selftest" in argv:
        return _run_selftest()
    if not argv:
        print(__doc__)
        return 2

    results_file = argv[0]
    topic = extra = out = None
    min_score = 0.30
    min_relevant = 3
    drop = as_json = False

    i = 1
    while i < len(argv):
        a = argv[i]
        if a == "--topic" and i + 1 < len(argv):
            topic = argv[i + 1]; i += 2
        elif a == "--keywords" and i + 1 < len(argv):
            extra = argv[i + 1]; i += 2
        elif a == "--min-score" and i + 1 < len(argv):
            min_score = float(argv[i + 1]); i += 2
        elif a == "--min-relevant" and i + 1 < len(argv):
            min_relevant = int(argv[i + 1]); i += 2
        elif a == "--out" and i + 1 < len(argv):
            out = argv[i + 1]; i += 2
        elif a == "--drop":
            drop = True; i += 1
        elif a == "--json":
            as_json = True; i += 1
        else:
            i += 1

    if not topic and not extra:
        print('ERROR: wajib kasih --topic "..." (atau --keywords). Relevansi butuh topik acuan.')
        return 2

    try:
        with open(results_file, encoding="utf-8") as f:
            results = json.load(f)
    except FileNotFoundError:
        print(f"ERROR: file tidak ada: {results_file}")
        return 2
    except Exception as e:
        print(f"ERROR: gagal baca/parse JSON ({e}).")
        return 2
    if not isinstance(results, list):
        print("ERROR: results.json harus berupa array/list hasil pencarian.")
        return 2

    keywords = keywords_from(topic, extra)
    if len(keywords) < 2:
        print('WARNING: kata kunci topik < 2 setelah buang stopword; skor jadi kasar. '
              'Kasih --keywords "a,b,c" yang lebih spesifik.')

    scored, relevant, tangensial = filter_results(results, keywords, min_score)

    payload = {
        "topic": topic,
        "keywords": keywords,
        "min_score": min_score,
        "total": len(scored),
        "relevant_count": len(relevant),
        "tangensial_count": len(tangensial),
        "results": relevant if drop else scored,
    }

    if out:
        with open(out, "w", encoding="utf-8") as f:
            json.dump(payload["results"], f, ensure_ascii=False, indent=2)

    if as_json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        print("=" * 60)
        print("RELEVANCE FILTER")
        print("=" * 60)
        print(f"Topik      : {topic}")
        print(f"Kata kunci : {', '.join(keywords)}")
        print(f"Ambang     : min-score={min_score}")
        print(f"Total {len(scored)} -> RELEVAN {len(relevant)} | TANGENSIAL {len(tangensial)}")
        print("\n-- RELEVAN (boleh lanjut ke verify DOI) --")
        for r in relevant:
            print(f"  [{r['relevance_score']:.2f}] {r.get('title', '(tanpa judul)')}")
        if tangensial:
            print("\n-- TANGENSIAL (JANGAN dikutip tanpa cek manual; cari ganti) --")
            for r in tangensial:
                print(f"  [{r['relevance_score']:.2f}] {r.get('title', '(tanpa judul)')}")
        if out:
            print(f"\nDisimpan: {out} ({'hanya relevan' if drop else 'semua + skor'})")
        print("\nCATATAN: relevansi != kredibilitas. Sumber relevan TETAP wajib lolos "
              "verify_citations.py (DOI resolve) sebelum dikutip.")

    return 0 if len(relevant) >= min_relevant else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
