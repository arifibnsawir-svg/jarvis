#!/usr/bin/env python3
"""Deep Analysis Quality Evaluator — jarvis-reason as final arbiter.

HARD-ENFORCE v2:
  - Robust content extraction (message.content / delta / reasoning_content /
    reasoning) + retry biar flake 9Router gak false-block.
  - Tiap verdict asli (PASS/NEEDS_REVISION) dapat eval_receipt (HMAC-SHA256)
    dan dicatat ke ledger -> fondasi anti-asbun (verify_deep_analysis.py).

ROUTING: Direct to 9Router (port 20128), bypass Guardian.
INPUT: Truncated to 3000 chars to prevent timeout.
"""
from __future__ import annotations

import argparse
import hashlib
import hmac
import json
import os
import re
import sys
import time

_NINEROUTER_URL = "<http://localhost:20128/v1/chat/completions>"
_NINEROUTER_KEY = os.environ.get("NINEROUTER_KEY", os.environ.get("ROUTER_KEY", ""))

_SECRET_PATH = os.path.expanduser("~/.hermes/.deep_eval_secret")
_LEDGER_PATH = os.path.expanduser("~/.hermes/logs/deep_analysis_ledger.jsonl")

EVAL_PROMPT = """Evaluate this deep analysis output against QUALITY criteria.
Return ONLY valid JSON (no markdown, no explanation).

{
  "verdict": "PASS" or "NEEDS_REVISION",
  "neuro_arc_present": true/false,
  "multi_perspective_min_3": true/false,
  "anti_halu_labels_used": true/false,
  "specific_to_context": true/false,
  "contradictions_exposed": true/false,
  "actionable_recommendations": true/false,
  "overall_quality": 0-100,
  "strengths": ["short strength 1"],
  "weaknesses": ["short weakness 1"],
  "fix_suggestions": ["short fix 1"]
}

ANALYSIS TO EVALUATE:
"""

def _extract_json(text: str) -> dict | None:
    """Extract first valid JSON object from any text."""
    cleaned = text.strip()
    if not cleaned:
        return None

    _fence = "`" * 3
    for prefix, suffix in [(_fence + "json\n", _fence), (_fence + "\n", _fence)]:
        if cleaned.startswith(prefix) and cleaned.endswith(suffix):
            inner = cleaned[len(prefix):-len(suffix)].strip()
            try:
                return json.loads(inner)
            except json.JSONDecodeError:
                pass

    try:
        return json.loads(cleaned)
    except json.JSONDecodeError:
        pass

    starts = [m.start() for m in re.finditer(r"\{", cleaned)]
    for start in starts:
        depth = 0
        for i in range(start, len(cleaned)):
            if cleaned[i] == "{":
                depth += 1
            elif cleaned[i] == "}":
                depth -= 1
                if depth == 0:
                    candidate = cleaned[start:i + 1]
                    try:
                        return json.loads(candidate)
                    except json.JSONDecodeError:
                        break

    for pattern in [r"\{(?:[^{}]|\{[^{}]*\})*\}", r"\{[^{}]*\}"]:
        match = re.search(pattern, cleaned, re.DOTALL)
        if match:
            try:
                return json.loads(match.group(0))
            except json.JSONDecodeError:
                continue

    return None

def _load_secret() -> bytes:
    """Load (or create, chmod 600) the HMAC secret for receipts."""
    try:
        with open(_SECRET_PATH, "rb") as f:
            s = f.read().strip()
            if s:
                return s
    except FileNotFoundError:
        pass
    s = os.urandom(32).hex().encode()
    os.makedirs(os.path.dirname(_SECRET_PATH), exist_ok=True)
    fd = os.open(_SECRET_PATH, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "wb") as f:
        f.write(s)
    return s
def _make_receipt(analysis_sha, model_used, evaluated_at, verdict, quality) -> str:
    msg = f"{analysis_sha}|{model_used}|{evaluated_at}|{verdict}|{quality}".encode()
    return hmac.new(_load_secret(), msg, hashlib.sha256).hexdigest()

def _append_ledger(entry: dict) -> None:
    os.makedirs(os.path.dirname(_LEDGER_PATH), exist_ok=True)
    with open(_LEDGER_PATH, "a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")

def _extract_content(choices) -> str:
    """Ambil teks konten dari berbagai shape balikan 9Router."""
    if not choices:
        return ""
    ch = choices[0] or {}
    msg = ch.get("message") or {}
    delta = ch.get("delta") or {}
    for c in (msg.get("content"), delta.get("content"),
              msg.get("reasoning_content"), msg.get("reasoning")):
        if c and str(c).strip():
            return str(c)
    return ""

def evaluate(analysis_text: str, timeout: int = 180, retries: int = 2) -> dict:
    """Call jarvis-reason via 9Router to evaluate quality.

    Retry menutup flake; verdict asli dapat eval_receipt + masuk ledger.
    """
    import urllib.request

    analysis_sha = hashlib.sha256(analysis_text.encode("utf-8")).hexdigest()

    sample = analysis_text
    if len(sample) > 3000:
        sample = sample[:1500] + "\n...\n" + sample[-1500:]

    payload = json.dumps({
        "model": "jarvis-reason",
        "messages": [{"role": "user", "content": EVAL_PROMPT + sample}],
        "max_tokens": 1500,
        "temperature": 0.1,
    }).encode("utf-8")

    headers = {"Content-Type": "application/json"}
    if _NINEROUTER_KEY:
        headers["Authorization"] = f"Bearer {_NINEROUTER_KEY}"

    last = {"verdict": "REQUEST_FAILED", "model_used": "none", "overall_quality": 0}

    for attempt in range(1, retries + 2):
        try:
            req = urllib.request.Request(
                _NINEROUTER_URL, data=payload, headers=headers, method="POST",
            )
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                raw_body = resp.read().decode("utf-8")
        except Exception as e:
            last = {"verdict": "REQUEST_FAILED", "error": str(e)[:200],
                    "model_used": "none", "overall_quality": 0, "attempt": attempt}
            continue

        api = _extract_json(raw_body)
        if api is None:
            last = {"verdict": "API_RESPONSE_NOT_JSON", "raw": raw_body[:300],
                    "model_used": "none", "overall_quality": 0, "attempt": attempt}
            continue

        choices = api.get("choices", [])
        model_used = api.get("model", "unknown")
        finish = choices[0].get("finish_reason") if choices else None
        content = _extract_content(choices)
        if not content.strip():
            last = {"verdict": "EMPTY_CONTENT", "model_used": model_used,
                    "finish_reason": finish, "raw": raw_body[:300],
                    "overall_quality": 0, "attempt": attempt}
            continue

        verdict = _extract_json(content)
        if verdict is None:
            last = {"verdict": "VERDICT_NOT_FOUND", "model_used": model_used,
                    "finish_reason": finish, "raw": content[:300],
                    "overall_quality": 0, "attempt": attempt}
            continue

        evaluated_at = time.strftime("%Y-%m-%dT%H:%M:%S%z")
        verdict["model_used"] = model_used
        verdict["evaluated_at"] = evaluated_at
        verdict["analysis_sha256"] = analysis_sha
        verdict["finish_reason"] = finish
        verdict["attempt"] = attempt
        verdict["eval_receipt"] = _make_receipt(
            analysis_sha, model_used, evaluated_at,
            verdict.get("verdict", ""), verdict.get("overall_quality", ""))
        _append_ledger({
            "ts": evaluated_at, "analysis_sha256": analysis_sha,
            "model_used": model_used, "verdict": verdict.get("verdict"),
            "overall_quality": verdict.get("overall_quality"),
            "eval_receipt": verdict["eval_receipt"],
        })
        return verdict

    return last
def main() -> int:
    ap = argparse.ArgumentParser(description="Deep Analysis Quality Evaluator")
    ap.add_argument("--file", help="File containing analysis text")
    ap.add_argument("--text", help="Analysis text directly")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--timeout", type=int, default=180)
    args = ap.parse_args()

    if args.file:
        try:
            with open(args.file, "r", encoding="utf-8") as f:
                text = f.read()
        except FileNotFoundError:
            print(f"ERROR: File not found: {args.file}")
            return 2
    elif args.text:
        text = args.text
    else:
        text = sys.stdin.read().strip()

    if not text or len(text) < 100:
        print("ERROR: Analysis text too short", file=sys.stderr)
        return 2

    print(f"Evaluating {len(text)} chars via 9Router (jarvis-reason)...", file=sys.stderr)
    verdict = evaluate(text, timeout=args.timeout)

    if args.json:
        print(json.dumps(verdict, ensure_ascii=False, indent=2))
    else:
        print(f"Verdict: {verdict.get('verdict', 'UNKNOWN')}")
        print(f"Model: {verdict.get('model_used', 'unknown')}")
        print(f"Quality: {verdict.get('overall_quality', '?')}/100")
        print(f"Receipt: {verdict.get('eval_receipt', '-')}")
        for key in ["neuro_arc_present", "multi_perspective_min_3",
                     "anti_halu_labels_used", "specific_to_context",
                     "contradictions_exposed", "actionable_recommendations"]:
            print(f"  {key}: {verdict.get(key, '?')}")
        for key in ["strengths", "weaknesses", "fix_suggestions"]:
            vals = verdict.get(key, [])
            if vals:
                print(f"{key.capitalize()}: {', '.join(vals[:3])}")

    return 0 if verdict.get("verdict") == "PASS" else 1

if __name__ == "__main__":
    raise SystemExit(main())
