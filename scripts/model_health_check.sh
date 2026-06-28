#!/usr/bin/env bash
# Audit kesehatan SEMUA model dasar di 9router (bukan combo). Read-only.
# Skip ag/ & Nara/ by default (ban-risk / paid-402). Key dari ENV, gak di-print.
set -uo pipefail
python3 - <<'PY'
import os, json, time, urllib.request, urllib.error
BASE = os.environ.get("NINEROUTER_URL", "http://localhost:20128/v1")
KEY  = os.environ.get("NINEROUTER_KEY") or os.environ.get("ROUTER_KEY") or ""
SKIP = ("ag/", "Nara/", "nara/")   # ban-risk / paid; set INCLUDE_AG=1 buat ikut tes ag/
INCLUDE_AG = os.environ.get("INCLUDE_AG") == "1"
Q = "Balas HANYA angka: 17+26?"
TIMEOUT = 25

def http(path, payload=None):
    url = BASE.rstrip("/") + path
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(url, data=data, method="POST" if data else "GET")
    req.add_header("Content-Type", "application/json")
    if KEY: req.add_header("Authorization", "Bearer " + KEY)
    with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
        return r.status, json.loads(r.read().decode("utf-8", "replace"))

try:
    _, d = http("/models")
except Exception as e:
    print("GAGAL /models:", repr(e)); raise SystemExit(1)

models = [m["id"] for m in d.get("data", []) if m.get("owned_by") != "combo"]
if not INCLUDE_AG:
    models = [m for m in models if not m.startswith(SKIP)]
print("Tes %d model dasar (skip ag/Nara kecuali INCLUDE_AG=1)...\n" % len(models))

alive, dead, slow = [], [], []
for m in models:
    t0 = time.time()
    try:
        code, r = http("/chat/completions", {"model": m, "messages":[{"role":"user","content":Q}], "max_tokens":15, "temperature":0})
        dt = time.time() - t0
        msg = (r.get("choices",[{}])[0].get("message",{}) or {})
        c = (msg.get("content") or msg.get("reasoning_content") or "").strip()
        ok = "43" in c
        tag = "OK" if ok else "200?"
        print(f"{m:<45}{tag:<6}{dt:6.1f}s  {c[:30]}")
        (slow if (ok and dt>8) else alive if ok else dead).append((m, dt))
    except urllib.error.HTTPError as e:
        print(f"{m:<45}{'HTTP'+str(e.code):<6}{time.time()-t0:6.1f}s"); dead.append((m, None))
    except Exception as e:
        print(f"{m:<45}{'ERR':<6}{time.time()-t0:6.1f}s  {type(e).__name__}"); dead.append((m, None))

print("\n===== RINGKASAN =====")
print("HIDUP & cepat (<=8s): %d" % len(alive))
print("HIDUP tapi LAMBAT (>8s): %d -> %s" % (len(slow), ", ".join(m for m,_ in slow) or "-"))
print("MATI/ERROR: %d -> %s" % (len(dead), ", ".join(m for m,_ in dead) or "-"))
PY
