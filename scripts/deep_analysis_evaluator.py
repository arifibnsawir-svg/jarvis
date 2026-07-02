#!/usr/bin/env python3
"""Deep Analysis Quality Evaluator — Opus 4.8 as final arbiter.

Token-efficient design:
  - jarvis-agent (cheap) writes the analysis
  - Opus 4.8 (expensive, called ONCE) evaluates quality
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
import subprocess
import sys
import time

_GUARDIAN_URL = "http://localhost:20129/v1/chat/completions"
_VENV_PY = os.path.expanduser("~/.hermes/hermes-agent/venv/bin/python")

EVAL_PROMPT = """Evaluate this deep analysis output against QUALITY criteria.
Return ONLY valid JSON with this structure:

{
  "verdict": "PASS" or "NEEDS_REVISION",
  "neuro_arc_present": true/false,
  "multi_perspective_min_3": true/false,
  "anti_halu_labels_used": true/false,
  "specific_to_context": true/false,
  "contradictions_exposed": true/false,
  "actionable_recommendations": true/false,
  "overall_quality": 0-100,
  "strengths": ["..."],
  "weaknesses": ["..."],
  "fix_suggestions": ["..."]
}

ANALYSIS TO EVALUATE:
"""


def evaluate(analysis_text: str, timeout: int = 120) -> dict:
    """Call jarvis-reason to evaluate analysis quality."""
    import urllib.request

    prompt = EVAL_PROMPT + analysis_text[:8000]

    payload = json.dumps({
        "model": "jarvis-reason",
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": 800,
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

    # Parse JSON from response (may be wrapped in markdown fences)
    content = content.strip()
    if content.startswith("```"):
        content = content.split("\n", 1)[-1]
        if content.endswith("```"):
            content = content[:-3]
    if content.startswith("json"):
        content = content[4:]
    content = content.strip()

    try:
        verdict = json.loads(content)
    except json.JSONDecodeError:
        # Fallback: extract the JSON object
        import re
        match = re.search(r"\{[^}]+\}", content, re.DOTALL)
        if match:
            try:
                verdict = json.loads(match.group(0))
            except json.JSONDecodeError:
                verdict = {"verdict": "JSON_PARSE_ERROR", "raw": content[:200]}
        else:
            verdict = {"verdict": "JSON_NOT_FOUND", "raw": content[:200]}

    verdict["model_used"] = model_used
    verdict["evaluated_at"] = time.strftime("%Y-%m-%dT%H:%M:%S%z")
    return verdict


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Deep Analysis Quality Evaluator — Opus 4.8 as final arbiter"
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

    if not text:
        print("ERROR: No analysis text provided")
        return 2

    print("Evaluating deep analysis quality via jarvis-reason...", file=sys.stderr)
    verdict = evaluate(text, timeout=args.timeout)

    if args.json:
        print(json.dumps(verdict, ensure_ascii=False, indent=2))
    else:
        print(f"Verdict: {verdict.get('verdict', 'UNKNOWN')}")
        print(f"Model: {verdict.get('model_used', 'unknown')}")
        print(f"Quality: {verdict.get('overall_quality', '?')}/100")
        print(f"NEURO-ARC: {verdict.get('neuro_arc_present', '?')}")
        print(f"Multi-perspective: {verdict.get('multi_perspective_min_3', '?')}")
        print(f"Anti-halu labels: {verdict.get('anti_halu_labels_used', '?')}")
        print(f"Context-specific: {verdict.get('specific_to_context', '?')}")
        if verdict.get("strengths"):
            print(f"Strengths: {', '.join(verdict['strengths'][:3])}")
        if verdict.get("weaknesses"):
            print(f"Weaknesses: {', '.join(verdict['weaknesses'][:3])}")
        if verdict.get("fix_suggestions"):
            print(f"Fix suggestions: {', '.join(verdict['fix_suggestions'][:3])}")

    return 0 if verdict.get("verdict") == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
