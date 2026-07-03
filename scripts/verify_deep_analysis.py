#!/usr/bin/env python3
"""Verify a Deep Analysis verdict is backed by a real evaluator run.
Fabricated verdict = no valid receipt = REJECTED."""
import argparse
import hashlib
import hmac
import json
import os
import sys

_SECRET_PATH = os.path.expanduser("~/.hermes/.deep_eval_secret")
_LEDGER_PATH = os.path.expanduser("~/.hermes/logs/deep_analysis_ledger.jsonl")

def _secret() -> bytes:
    with open(_SECRET_PATH, "rb") as f:
        return f.read().strip()

def _receipt(sha, model, ts, verdict, quality) -> str:
    msg = f"{sha}|{model}|{ts}|{verdict}|{quality}".encode()
    return hmac.new(_secret(), msg, hashlib.sha256).hexdigest()

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--analysis-file", required=True)
    ap.add_argument("--receipt", required=True)
    a = ap.parse_args()

    text = open(a.analysis_file, encoding="utf-8").read()
    sha = hashlib.sha256(text.encode("utf-8")).hexdigest()

    try:
        lines = open(_LEDGER_PATH, encoding="utf-8").read().splitlines()
    except FileNotFoundError:
        print("REJECT: ledger gak ada — evaluator belum pernah jalan", file=sys.stderr)
        return 3

    for ln in reversed(lines):
        try:
            e = json.loads(ln)
        except json.JSONDecodeError:
            continue
        if e.get("eval_receipt") != a.receipt:
            continue
        if e.get("analysis_sha256") != sha:
            print("REJECT: receipt ada tapi sha teks beda (verdict buat teks lain)", file=sys.stderr)
            return 4
        exp = _receipt(e["analysis_sha256"], e["model_used"], e["ts"],
                       e["verdict"], e["overall_quality"])
        if not hmac.compare_digest(exp, a.receipt):
            print("REJECT: HMAC gagal — receipt dipalsu", file=sys.stderr)
            return 5
        print(f"OK: {e['verdict']} q{e['overall_quality']} via {e['model_used']} @ {e['ts']} — VALID")
        return 0

    print("REJECT: receipt gak ada di ledger — verdict ASBUN", file=sys.stderr)
    return 2
if __name__ == "__main__":
    raise SystemExit(main())
