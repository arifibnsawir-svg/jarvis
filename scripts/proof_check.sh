#!/usr/bin/env bash
# PROOF CHECK: buktiin tiap lapis yang dibangun beneran terpasang & jalan. Read-only, non-destruktif.
set -uo pipefail
echo "===================== JARVIS PROOF CHECK ====================="
date '+%Y-%m-%d %H:%M:%S %Z'

echo; echo "[1] OTAK PERCAKAPAN (gateway default) -- ekspektasi: jarvis-agent"
grep -nE "^model:|^[[:space:]]+default:" ~/.hermes/config.yaml 2>/dev/null | head -8

echo; echo "[2] DNA ALWAYS-ON di USER.md -- ekspektasi: 2 direktif ADA"
echo "jumlah direktif: $(grep -c 'neuro-arc skill by default\|arsi-doctrine skill for artifact' ~/.hermes/memories/USER.md 2>/dev/null)"
grep -n "neuro-arc skill by default\|arsi-doctrine skill for artifact" ~/.hermes/memories/USER.md 2>/dev/null

echo; echo "[3] GUARDIAN_ROUTER kenal jarvis-reason -- ekspektasi: 3 entry (map/timeout/maxtokens)"
grep -n "jarvis-reason" ~/.hermes/scripts/guardian_router.py 2>/dev/null || echo "(tidak ada)"

echo; echo "[4] COUNCIL PIPA4 pakai jarvis-reason -- ekspektasi: 5 titik"
grep -n "jarvis-reason" \
  ~/.hermes/pipelines/pipa4/phase6a/phase6a_llm_review_dryrun.py \
  ~/.hermes/pipelines/pipa4/phase6c/phase6c_council.py \
  ~/.hermes/pipelines/pipa4/phase6d/pipa4_mini_council_review.py \
  ~/.hermes/pipelines/pipa4/phase7a/pipa4_review_local.py 2>/dev/null || echo "(tidak ada)"

echo; echo "[5] LIVE: council jarvis-reason via Guardian -- model yg BENERAN serve + uji nalar audit:"
python3 - <<'PY'
import urllib.request, json
payload={"model":"jarvis-reason",
 "messages":[{"role":"user","content":"Tugas audit singkat. Klaim: 'Indonesia memproklamasikan kemerdekaan tahun 1949'. Balas format: VERDICT: <BENAR/SALAH> | ALASAN: <1 kalimat>."}],
 "max_tokens":300,"temperature":0}
req=urllib.request.Request("http://localhost:20129/v1/chat/completions",
    data=json.dumps(payload).encode(),headers={"Content-Type":"application/json"})
try:
    r=json.loads(urllib.request.urlopen(req,timeout=120).read())
    print("served_model:", r.get("model"), "(kalau gpt-5.5/claude/qwen = anggota jarvis-reason; kalau glm-5 = masih DailyFree)")
    print("content:", (r["choices"][0]["message"].get("content") or "")[:260])
except Exception as e:
    print("ERROR:", type(e).__name__, e)
PY
echo; echo "===================== END PROOF CHECK ====================="
