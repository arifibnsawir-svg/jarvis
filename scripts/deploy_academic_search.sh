#!/usr/bin/env bash
# Deploy academic-search skill (cari + verifikasi sumber ilmiah, anti-halu) ke Acer.
# Scoped dari zLanqing/codex-claude-academic-skills (MIT): paper-lookup + literature-review + citation-management.
# Multi-database (Scholar + OpenAlex + Crossref + Semantic Scholar + PubMed/arXiv + Garuda/SINTA) -> RELEVANCE FILTER -> VERIFY wajib -> cite-only-verified.
# No-key (kecuali Semantic Scholar opsional), dep requests+scholarly (no native binary). Idempotent + backup. No restart (aktif /new).
set -uo pipefail
SK="$HOME/.hermes/skills"
DST="$SK/academic-search"
UM="$HOME/.hermes/memories/USER.md"
PYBIN="$HOME/.hermes/hermes-agent/venv/bin/python"; [ -x "$PYBIN" ] || PYBIN="python3"
PIPBIN="$HOME/.hermes/hermes-agent/venv/bin/pip"; [ -x "$PIPBIN" ] || PIPBIN="pip3"
ts="$(date +%Y%m%d_%H%M%S)"

echo "=== [1] copy skill ke ~/.hermes/skills/academic-search ==="
mkdir -p "$SK"
rm -rf "$DST"
cp -r ~/jarvis/skills/academic-search "$DST"
echo "ter-copy:"; du -sh "$DST"; ls -1 "$DST"

echo "=== [2] install deps di venv (no-key, no native binary) ==="
"$PIPBIN" install -q requests scholarly 2>&1 | tail -2 || echo "(pip: cek manual)"

echo "=== [3] verifikasi frontmatter SKILL.md ==="
"$PYBIN" - <<PY
import re,sys
t=open("$DST/SKILL.md",encoding="utf-8").read()
m=re.match(r'^---\n(.*?)\n---',t,re.S)
print("FRONTMATTER:", "OK" if (m and "name: academic-search" in m.group(1)) else "FAIL")
PY

echo "=== [4] SMOKE-TEST: verify_citations.py (real lolos, fake ditolak) ==="
cat > /tmp/_acadtest.md <<'MD'
DOI real: 10.30998/formatif.v5i2.336
DOI real: 10.33373/kop.v2i2.302
DOI halu: 10.99999/jurnal.halu.00000
MD
"$PYBIN" "$DST/literature-review/scripts/verify_citations.py" /tmp/_acadtest.md 2>&1 | grep -E "Total DOIs|Verified:|Failed:" || echo "(smoke-test: cek manual / network)"

echo "=== [4b] SMOKE-TEST: relevance_filter.py (selftest, no-network) ==="
"$PYBIN" "$DST/literature-review/scripts/relevance_filter.py" --selftest || echo "(relevance selftest: cek manual)"

echo "=== [5] wire direktif sumber akademik + fix domain Garuda mati ==="
if [ ! -f "$UM" ]; then echo "RESULT_WIRE: FAIL (USER.md tidak ada)"; else
  cp "$UM" "$UM.bak.$ts"; echo "BACKUP: $UM.bak.$ts"
  # 5a. fix domain Garuda/SINTA yang mati (kemdikbud -> kemdiktisaintek)
  sed -i 's#garuda\.kemdikbud\.go\.id#garuda.kemdiktisaintek.go.id#g; s#sinta\.kemdikbud\.go\.id#sinta.kemdiktisaintek.go.id#g' "$UM"
  echo "domain Garuda/SINTA difix (kemdikbud->kemdiktisaintek)"
  # 5b. tambah direktif always-on (idempotent)
  MARK="ACADEMIC SOURCE SEARCH"
  if grep -q "$MARK" "$UM"; then
    echo "RESULT_WIRE: SKIP_DIRECTIVE (sudah ada)"
  else
    cat >> "$UM" <<'TXT'
ACADEMIC SOURCE SEARCH (always, untuk artefak akademik apa pun): pakai skill academic-search untuk MENCARI sumber, JANGAN mengandalkan ingatan atau scrape Google Scholar sendirian. Alur WAJIB: (1) SEARCH multi-database - Indonesia-first via OpenAlex/Crossref (filter jurnal Indonesia), Garuda (garuda.kemdiktisaintek.go.id), SINTA (sinta.kemdiktisaintek.go.id), repositori .ac.id; PLUS Google Scholar (scholarly, best-effort), Semantic Scholar, PubMed/arXiv untuk coverage (minimal 3 database). (2) dedup+rank via literature-review/scripts/search_databases.py. (3) SARING RELEVANSI via literature-review/scripts/relevance_filter.py (skoring topik; sumber tangensial dibuang SEBELUM verify - DOI valid tak menjamin relevan). (4) VERIFIKASI WAJIB tiap sitasi via literature-review/scripts/verify_citations.py (DOI resolve di CrossRef + URL kebuka) SEBELUM dikutip; sitasi yang gagal-verify DIBUANG, tidak pernah dikutip. (5) kutip HANYA sumber relevan + terverifikasi (doi_to_bibtex.py untuk BibTeX). Kredibilitas non-negotiable: JANGAN sajikan DOI/link tanpa lolos verify; kalau tidak ada yang relevan+terverifikasi -> 'belum nemu sumber terverifikasi' (cite-or-abstain). Aturan ini menimpa alur apa pun yang mengutip dari ingatan.
TXT
    echo "RESULT_WIRE: SUCCESS (direktif ditambah)"
  fi
fi

echo "=== PROOF ==="
echo "-- direktif academic-search --"; grep -n "ACADEMIC SOURCE SEARCH" "$UM" | head
echo "-- domain Garuda sekarang (harus kemdiktisaintek, no kemdikbud) --"; grep -noE "garuda\.kemdik[a-z]*\.go\.id|sinta\.kemdik[a-z]*\.go\.id" "$UM" | head
echo "=== CATATAN ==="
echo "- Aktif di SESSION BARU (/new). TIDAK perlu restart gateway."
echo "- Google Scholar (scholarly) diuji di Acer (IP rumahan lebih lancar dari datacenter); kalau CAPTCHA, sumber no-key + verify tetap nutup."
echo "- ROLLBACK: cp $UM.bak.$ts $UM ; rm -rf $DST"
