#!/usr/bin/env python3
"""Deep Analysis Quality Evaluator — jarvis-reason as final arbiter.

Token-efficient design:
  - jarvis-agent (cheap) writes the analysis
  - jarvis-reason (9Router combo, expensive, called ONCE) evaluates quality
  - JSON deterministik memutuskan: PASS or NEEDS_REVISION

ROUTING: Direct to 9Router (port 20128), bypass Guardian.

Evaluates against 6 criteria.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time

_NINEROUTER_URL = "http://localhost:20128/v1/chat/completions"
_NINEROUTER_KEY = os.environ.get("NINEROUTER_KEY", os.environ.get("ROUTER_KEY", ""))

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

Keep strengths/weaknesses/fix_suggestions BRIEF (under 80 chars each).
No line breaks inside JSON values.

ANALYSIS TO EVALUATE:
"""


def _extract_json(text: str) -> dict | None:
    """Extract a JSON object from text that may contain reasoning prefix/suffix.

    Tries multiple strategies:
      1. Raw parse (clean text is pure JSON)
      2. Strip markdown fences + parse
      3. Regex: first { ... } block (non-greedy)
      4. Regex: nested { ... } with one level of nesting
      5. Regex: find ALL { ... } blocks, try each
    """
    cleaned = text.strip()

    # Strategy 1: raw parse
    try:
        return json.loads(cleaned)
    except json.JSONDecodeError:
        pass

    # Strategy 2: strip markdown fences
    for prefix, suffix in [("```json\n", "```"), ("```\n", "```")]:
        if cleaned.startswith(prefix) and cleaned.endswith(suffix):
            inner = cleaned[len(prefix):-len(suffix)].strip()
            try:
                return json.loads(inner)
            except json.JSONDecodeError:
                pass

    # Strategy 3-5: regex extraction
    for pattern in [
        r"\{[^{}]*\}",                     # flat: { "key": "val" }
        r"\{(?:[^{}]|\{[^{}]*\})*\}",      # 1-level nested
        r"\{.*?\}(?!\s*\{)",               # greedy: first complete object
    ]:
        match = re.search(pattern, cleaned, re.DOTALL)
        if match:
            try:
                return json.loads(match.group(0))
            except json.JSONDecodeError:
                continue

    # Strategy 5: find ALL possible JSON start/end
    starts = [m.start() for m in re.finditer(r"\{", cleaned)]
    for start in starts:
        depth = 0
        for i in range(start, len(cleaned)):
            if cleaned[i] == "{":
                depth += 1
            elif cleaned[i] == "}":
                depth -= 1
                if depth == 0:
                    try:
                        return json.loads(cleaned[start:i + 1])
                    except json.JSONDecodeError:
                        break

    return None


def evaluate(analysis_text: str, timeout: int = 120) -> dict:
    """Call jarvis-reason directly via 9Router to evaluate analysis quality."""
    import urllib.request

    prompt = EVAL_PROMPT + analysis_text[:6000]

    payload = json.dumps({
        "model": "jarvis-reason",
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": 1500,
        "temperature": 0.1,
    }).encode("utf-8")

    headers = {"Content-Type": "application/json"}
    if _NINEROUTER_KEY:
        headers["Authorization"] = f"Bearer {_NINEROUTER_KEY}"

    req = urllib.request.Request(
        _NINEROUTER_URL, data=payload, headers=headers, method="POST",
    )

    model_used = "unknown"
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw_body = resp.read().decode("utf-8")
            # 9Router may return JSON with nested content
            api_response = json.loads(raw_body)
            content = api_response["choices"][0]["message"]["content"]
            model_used = api_response.get("model", model_used)
    except Exception as e:
        return {
            "verdict": "EVALUATOR_ERROR",
            "error": str(e)[:200],
            "model_used": "none",
            "overall_quality": 0,
        }

    # Extract JSON from LLM response (may have reasoning prefix)
    verdict = _extract_json(content)

    if verdict is None:
        return {
            "verdict": "JSON_NOT_FOUND",
            "model_used": model_used,
            "raw": content[:300],
            "overall_quality": 0,
        }

    verdict["model_used"] = model_used
    verdict["evaluated_at"] = time.strftime("%Y-%m-%dT%H:%M:%S%z")
    return verdict


def main() -> int:
    ap = argparse.ArgumentParser(description="Deep Analysis Quality Evaluator")
    ap.add_argument("--file", help="File containing analysis text")
    ap.add_argument("--text", help="Analysis text directly")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--timeout", type=int, default=120)
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
