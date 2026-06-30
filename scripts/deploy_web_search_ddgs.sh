#!/usr/bin/env bash
# FIX web-grounding halu: set search_backend = ddgs (DuckDuckGo, NO API KEY).
# Akar (terbukti via inspect): config.yaml web.search_backend='' KOSONG + semua key search KOSONG
# -> Jarvis gak punya backend search -> scraping mentah/subagent kosong -> halu sumber.
# Fix: set search_backend ke 'ddgs' (no-key) + install paket ddgs di venv.
# Edit config.yaml = CORE -> butuh APPROVAL Arif (action-gate). Backup dibuat. Idempotent.
set -uo pipefail
CFG="$HOME/.hermes/config.yaml"
PYBIN="$HOME/.hermes/hermes-agent/venv/bin/python"; [ -x "$PYBIN" ] || PYBIN="python3"
PIPBIN="$HOME/.hermes/hermes-agent/venv/bin/pip"; [ -x "$PIPBIN" ] || PIPBIN="pip3"
ts="$(date +%Y%m%d_%H%M%S)"

if [ ! -f "$CFG" ]; then echo "RESULT: FAIL (config.yaml tidak ada: $CFG)"; exit 1; fi

echo "=== [1] state SEBELUM ==="
grep -nE "^  (search_backend|backend|extract_backend):" "$CFG" | head

echo "=== [2] set search_backend -> ddgs (idempotent + backup) ==="
if grep -qE "^  search_backend: *'ddgs'" "$CFG"; then
  echo "RESULT_CFG: SKIP (search_backend sudah 'ddgs')"
else
  cp "$CFG" "$CFG.bak.$ts"; echo "BACKUP: $CFG.bak.$ts"
  # ganti HANYA baris search_backend kosong di bawah web: (presisi, jaga komentar/baris lain)
  sed -i "s/^  search_backend: *''/  search_backend: 'ddgs'/" "$CFG"
  if grep -qE "^  search_backend: *'ddgs'" "$CFG"; then echo "RESULT_CFG: SUCCESS"; else echo "RESULT_CFG: FAIL (sed tidak match - cek indentasi/format)"; fi
fi

echo "=== [3] YAML sanity (abort kalau rusak) ==="
"$PYBIN" -c "import yaml,sys; yaml.safe_load(open('$CFG')); print('YAML_OK')" || { echo "YAML RUSAK -> ROLLBACK"; [ -f "$CFG.bak.$ts" ] && cp "$CFG.bak.$ts" "$CFG"; exit 1; }

echo "=== [4] install paket ddgs di venv ==="
"$PIPBIN" install -q ddgs 2>&1 | tail -2 || echo "(pip ddgs: cek manual)"

echo "=== [5] verifikasi import + 1 test search (no key) ==="
"$PYBIN" - <<'PY'
try:
    from ddgs import DDGS
except Exception:
    try:
        from duckduckgo_search import DDGS  # nama lama
    except Exception as e:
        print("IMPORT: FAIL", e); raise SystemExit
print("IMPORT: OK")
try:
    r = list(DDGS().text("gaya belajar prestasi belajar jurnal", max_results=3))
    print("TEST_SEARCH: OK,", len(r), "hasil")
    for x in r[:3]: print("  -", (x.get("title") or "")[:60], "|", (x.get("href") or "")[:50])
except Exception as e:
    print("TEST_SEARCH: GAGAL (mungkin rate-limit/network):", str(e)[:120])
PY

echo "=== [6] state SESUDAH ==="
grep -nE "^  (search_backend|backend|extract_backend):" "$CFG" | head
echo "=== CATATAN ==="
echo "- config cached by mtime -> kemungkinan kebaca di request berikutnya TANPA restart."
echo "- KALAU web_search masih 'no backend' setelah ini -> baru restart gateway (BUTUH GO, ~210s)."
echo "- ROLLBACK: cp $CFG.bak.<ts> $CFG"
