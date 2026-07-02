#!/usr/bin/env python3
"""Deep Analysis Quality Evaluator — Opus 4.8 as final arbiter.

Token-efficient design:
  - jarvis-agent (cheap) writes the analysis
  - jarvis-reason (expensive, called ONCE) evaluates quality
  - JSON deterministik memutuskan: PASS or NEEDS_REVISION

Evaluates against 6 criteria:
  1. NEURO-ARC framework present
  2. Multi-perspective (min 3)
  3. Anti-halu labels used
  4. Specific to user's context (not generic)
  5. Contradictions exposed (not hidden)
  6. Actionable recommendations

Usage:
  echo "<deep analysis output>" | python3 deep_analysis_evaluator.py
  python3 deep_analysis_evaluator.py --file /tmp/analysis_output.txt
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time

_GUARDIAN_URL = "http://localhost:20129/v1/chat/completions"

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
  "strengths": ["short strength 1", "short strength 2"],
  "weaknesses": ["short weakness 1", "short weakness 2"],
  "fix_suggestions": ["short fix 1"]
}

Keep strengths/weaknesses/fix_suggestions BRIEF (under 80 chars each).
Do NOT include line breaks inside the JSON string values.

ANALYSIS TO EVALUATE:
"""


def evaluate(analysis_text: str, timeout: int = 120) -> dict:
    """Call jarvis-reason to evaluate analysis quality."""
    import urllib.request

    prompt = EVAL_PROMPT + analysis_text[:6000]

    payload = json.dumps({
        "model": "jarvis-reason",
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": 1500,
        "temperature": 0.1,
    }).encode("utf-8")

    req = urllib.request.Request(
        _GUARDIAN_URL,
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            result = json.loads(resp.read().decode("utf-8"))
            content = result["choices"][0]["message"]["content"]
            model_used = result.get("model", "unknown")
    except Exception as e:
        return {
            "verdict": "EVALUATOR_ERROR",
            "error": str(e),
            "model_used": "none",
            "overall_quality": 0,
        }

    # Parse JSON from response — try multiple strategies
    cleaned = content.strip()
    
    # Strategy 1: Raw parse
    try:
        verdict = json.loads(cleaned)
        if isinstance(verdict, dict) and "verdict" in verdict:
            verdict["model_used"] = model_used
            verdict["evaluated_at"] = time.strftime("%Y-%m-%dT%H:%M:%S%z")
            return verdict
    except json.JSONDecodeError:
        pass

    # Strategy 2: Strip markdown fences
    if cleaned.startswith("```"):
        parts = cleaned.split("\n", 1)
        if len(parts) > 1:
            cleaned = parts[1]
            if cleaned.endswith("```"):
                cleaned = cleaned[:-3]
            if cleaned.startswith("json"):
                cleaned = cleaned[4:]
            cleaned = cleaned.strip()
    try:
        verdict = json.loads(cleaned)
        if isinstance(verdict, dict) and "verdict" in verdict:
            verdict["model_used"] = model_used
            verdict["evaluated_at"] = time.strftime("%Y-%m-%dT%H:%M:%S%z")
            return verdict
    except json.JSONDecodeError:
        pass

    # Strategy 3: Extract JSON object with regex
    match = re.search(r"\{[^{}]*\}", cleaned, re.DOTALL)
    if match:
        try:
            verdict = json.loads(match.group(0))
            if isinstance(verdict, dict):
                verdict["model_used"] = model_used
                verdict["evaluated_at"] = time.strftime("%Y-%m-%dT%H:%M:%S%z")
                return verdict
        except json.JSONDecodeError:
            pass

    # Strategy 4: Deep regex for nested JSON
    match = re.search(r"\{(?:[^{}]|\{[^{}]*\})*\}", cleaned, re.DOTALL)
    if match:
        try:
            verdict = json.loads(match.group(0))
            if isinstance(verdict, dict):
                verdict["model_used"] = model_used
                verdict["evaluated_at"] = time.strftime("%Y-%m-%dT%H:%M:%S%z")
                return verdict
        except json.JSONDecodeError:
            pass

    # Final fallback
    return {
        "verdict": "JSON_PARSE_ERROR",
        "model_used": model_used,
        "raw": cleaned[:300],
        "evaluated_at": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
        "overall_quality": 0,
    }


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Deep Analysis Quality Evaluator — jarvis-reason as final arbiter"
    )
    ap.add_argument("--file", help="File containing analysis text")
    ap.add_argument("--text", help="Analysis text directly")
    ap.add_argument("--json", action="store_true", help="Output machine-readable JSON")
    ap.add_argument("--timeout", type=int, default=120, help="Guardian request timeout")
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
        print("ERROR: Analysis text too short (< 100 chars). Save full output first.")
        return 2

    print(f"Evaluating {len(text)} chars via jarvis-reason...", file=sys.stderr)
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
