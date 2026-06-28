#!/usr/bin/env python3
"""
Smoke-test SEMUA combo di 9router: liveness + latency + basic-correctness.
Key dibaca dari ENV (NINEROUTER_KEY / ROUTER_KEY) -- TIDAK pernah di-print / di-hardcode.
Pakai: python3 scripts/combo_quality_test.py
"""
import os, sys, time, json, urllib.request, urllib.error

BASE = os.environ.get("NINEROUTER_URL", "http://localhost:20128/v1")
KEY  = os.environ.get("NINEROUTER_KEY") or os.environ.get("ROUTER_KEY") or ""

# Test ringan: cek model HIDUP + bener nalar dikit (17+26=43) + ukur latency.
Q = "Balas HANYA dengan angka, tanpa kata lain: hasil dari 17 + 26 ?"
EXPECT = "43"
MAXTOK = 20
TIMEOUT = 40

def http(path, payload=None, method="GET"):
    url = BASE.rstrip("/") + path
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Content-Type", "application/json")
    if KEY:
        req.add_header("Authorization", "Bearer " + KEY)
    with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
        return r.status, json.loads(r.read().decode("utf-8", "replace"))

def list_combos():
    try:
        _, d = http("/models")
        return [m["id"] for m in d.get("data", []) if m.get("owned_by") == "combo"]
    except Exception as e:
        print("GAGAL ambil /models:", repr(e)); sys.exit(1)

def test(combo):
    payload = {"model": combo, "messages": [{"role": "user", "content": Q}],
               "max_tokens": MAXTOK, "temperature": 0}
    t0 = time.time()
    try:
        code, d = http("/chat/completions", payload, "POST")
        dt = time.time() - t0
        msg = (d.get("choices", [{}])[0].get("message", {}) or {})
        content = (msg.get("content") or "").strip()
        if not content:
            content = (msg.get("reasoning_content") or "").strip()
        ok = EXPECT in content
        snippet = content.replace("\n", " ")[:60]
        return code, dt, ok, snippet
    except urllib.error.HTTPError as e:
        return f"HTTP{e.code}", time.time() - t0, False, ""
    except urllib.error.URLError as e:
        return "URLERR", time.time() - t0, False, str(e.reason)[:40]
    except Exception as e:
        return "ERR", time.time() - t0, False, type(e).__name__

def main():
    if not KEY:
        print("WARNING: NINEROUTER_KEY/ROUTER_KEY kosong di env. Coba tetap jalan (kalau router gak butuh key lokal).\n")
    combos = list_combos()
    print(f"Ketemu {len(combos)} combo. Test (Q: 17+26, harus '43'):\n")
    print(f"{'COMBO':<24}{'STATUS':<9}{'LAT(s)':<8}{'CORRECT':<9}SAMPLE")
    print("-" * 78)
    rows = []
    for c in combos:
        code, dt, ok, snip = test(c)
        rows.append((c, code, dt, ok, snip))
        print(f"{c:<24}{str(code):<9}{dt:<8.1f}{('YES' if ok else 'no'):<9}{snip}")
    # ringkasan: combo SEHAT (http 200 + bener + <=10s), urut tercepat
    healthy = [r for r in rows if r[1] == 200 and r[3]]
    healthy.sort(key=lambda r: r[2])
    print("\n=== SEHAT (200 + jawab '43'), urut tercepat ===")
    for c, code, dt, ok, snip in healthy:
        print(f"  {c:<24}{dt:.1f}s")
    if not healthy:
        print("  (tidak ada yang lolos -- cek key/router)")

if __name__ == "__main__":
    main()
