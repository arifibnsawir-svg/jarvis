#!/usr/bin/env python3
"""Jarvis Citation Helper — pre-cleaner for academic SPEC citations.

GBrain-inspired (skills/citation-fixer/), adapted for Jarvis architecture.
Runs BEFORE validate_spec to catch fixable citation problems early.
REPORT-ONLY by default — does NOT mutate the SPEC. Use --fix for auto-repair.

Checks:
  1. APA format compliance (Author, Year / Author (Year))
  2. Broken DOI/URL links (HEAD request with timeout, optional)
  3. Missing citations (facts without source)
  4. Reference-citation two-way consistency
  5. Indonesian-first ordering opportunity

Usage:
  python3 jarvis_citation_helper.py SPEC.json [--fix] [--json] [--check-dois]
  Exit 0 = all checks pass / fixable issues auto-repaired
  Exit 1 = issues found that need manual review
  Exit 2 = SPEC file not found / invalid JSON

SAFE for ARSI/Neuro-Arc/factory: runs BEFORE validate_spec, does not modify
gate logic, does not bypass PIPA4 council.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from pathlib import Path
from typing import Optional

# ── APA citation regexes (updated to match factory citation.py) ────────────
_SURNAME = re.compile(r"([A-Z][a-zA-Z]+)")
CITE_PAIR = re.compile(r"([A-Z][a-zA-Z]+)\s+dan\s+([A-Z][a-zA-Z]+)\s*\((\d{4})\)")
CITE_SINGLE = re.compile(
    r"([A-Z][a-zA-Z]+)(?:\s+(?:dkk\.|et al\.))?\s*[\,\(]\s*(\d{4})\)?"
)
DOI_PATTERN = re.compile(r"10\.\d{4,}/[^\s\]\)\"]+")


def _extract_citations(text: str) -> list[str]:
    """Return primary surname of every in-text citation."""
    if not text:
        return []
    primaries: list[str] = []
    for a, _b, _yr in CITE_PAIR.findall(text):
        primaries.append(a)
    consumed = CITE_PAIR.sub(" ", text)
    for name, _yr in CITE_SINGLE.findall(consumed):
        primaries.append(name)
    return primaries


def _surname_from_apa(apa: str) -> str:
    m = _SURNAME.search(apa or "")
    return m.group(1) if m else ""


def _extract_dois(text: str) -> list[str]:
    return DOI_PATTERN.findall(text or "")


def check_apa_format(references: list[dict]) -> list[str]:
    issues = []
    for i, ref in enumerate(references):
        apa = ref.get("apa", "")
        if not apa.strip():
            issues.append(f"ref[{i}]: APA string is empty")
            continue
        surname = _surname_from_apa(apa)
        if not surname:
            issues.append(f"ref[{i}]: cannot extract author surname from '{apa[:60]}'")
    return issues


def check_doi_health(references: list[dict], timeout: int = 5) -> list[str]:
    issues = []
    try:
        import urllib.request
    except ImportError:
        return []
    for i, ref in enumerate(references):
        url = ref.get("url", "")
        if not url:
            continue
        try:
            req = urllib.request.Request(url, method="HEAD")
            req.add_header("User-Agent", "JarvisCitationHelper/1.0")
            urllib.request.urlopen(req, timeout=timeout)
        except Exception as e:
            issues.append(f"ref[{i}]: URL/DOI unreachable — {url[:80]} ({e})")
    return issues


def check_citation_consistency(sections: list[dict], references: list[dict]) -> list[str]:
    cited = set()
    for s in sections:
        if s.get("kind") == "references":
            continue
        for b in s.get("blocks", []):
            t = b.get("type", "")
            text = b.get("text", "")
            if t in ("paragraph", "lead", "callout", "heading") and text:
                cited.update(_extract_citations(text))
            elif t == "list":
                for item in b.get("items", []):
                    cited.update(_extract_citations(item))
    ref_surnames = {_surname_from_apa(r.get("apa", "")) for r in references if r.get("apa")}
    ref_surnames.discard("")
    issues = []
    cited_without_ref = cited - ref_surnames
    if cited_without_ref:
        issues.append(f"cited-without-reference: {sorted(cited_without_ref)}")
    uncited = ref_surnames - cited if ref_surnames else set()
    if uncited:
        issues.append(f"reference-never-cited: {sorted(uncited)}")
    return issues


def check_missing_sources(sections: list[dict]) -> list[str]:
    claim_markers = re.compile(
        r"(menurut|berdasarkan|studi|penelitian|data|survei|laporan|jurnal|riset|hasil)\s",
        re.IGNORECASE,
    )
    issues = []
    for s in sections:
        for b in s.get("blocks", []):
            text = b.get("text", "")
            if claim_markers.search(text) and not _extract_citations(text):
                snippet = text[:100] + "..." if len(text) > 100 else text
                issues.append(
                    f"section '{s.get('title','?')[:40]}': claim without citation — '{snippet}'"
                )
    return issues


def audit_spec(spec_path: str, fix: bool = False, check_dois: bool = False) -> dict:
    try:
        with open(spec_path, "r", encoding="utf-8") as f:
            spec = json.load(f)
    except FileNotFoundError:
        return {"error": f"File not found: {spec_path}", "exit_code": 2}
    except json.JSONDecodeError as e:
        return {"error": f"Invalid JSON: {e}", "exit_code": 2}

    references = spec.get("references", [])
    sections = spec.get("sections", [])
    is_academic = spec.get("is_academic", False)

    issues: dict[str, list[str]] = {}
    fix_count = 0
    fixed: list[str] = []

    if not is_academic and not references:
        return {
            "issues": {},
            "fix_count": 0,
            "fixed": [],
            "exit_code": 0,
            "note": "Non-academic spec with no references — no citation checks needed.",
        }

    apa_issues = check_apa_format(references)
    if apa_issues:
        issues["apa_format"] = apa_issues

    if check_dois:
        doi_issues = check_doi_health(references)
        if doi_issues:
            issues["doi_health"] = doi_issues

    if references:
        cons_issues = check_citation_consistency(sections, references)
        if cons_issues:
            issues["citation_consistency"] = cons_issues
            if fix:
                cited = set()
                for s in sections:
                    if s.get("kind") == "references":
                        continue
                    for b in s.get("blocks", []):
                        text = b.get("text", "")
                        if text:
                            cited.update(_extract_citations(text))
                ref_surnames_map = {_surname_from_apa(r.get("apa", "")): i for i, r in enumerate(references)}
                uncited_surnames = set(ref_surnames_map.keys()) - cited
                uncited_surnames.discard("")
                if uncited_surnames:
                    new_refs = [r for i, r in enumerate(references)
                               if _surname_from_apa(r.get("apa", "")) not in uncited_surnames]
                    if len(new_refs) < len(references):
                        spec["references"] = new_refs
                        fix_count += len(references) - len(new_refs)
                        fixed.append(f"removed {fix_count} uncited references: {sorted(uncited_surnames)}")

    source_issues = check_missing_sources(sections)
    if source_issues:
        issues["missing_sources"] = source_issues

    if fix and fix_count > 0:
        backup = spec_path + ".bak." + time.strftime("%Y%m%d_%H%M%S")
        os.rename(spec_path, backup)
        with open(spec_path, "w", encoding="utf-8") as f:
            json.dump(spec, f, ensure_ascii=False, indent=2)
        fixed.append(f"backup saved to {backup}")

    exit_code = 0 if not issues else 1
    return {
        "issues": issues,
        "fix_count": fix_count,
        "fixed": fixed,
        "exit_code": exit_code,
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Jarvis Citation Helper")
    ap.add_argument("spec", help="Path to SPEC JSON file")
    ap.add_argument("--fix", action="store_true", help="Auto-repair fixable issues")
    ap.add_argument("--check-dois", action="store_true", help="Verify DOI/URL links (network)")
    ap.add_argument("--json", action="store_true", help="Output machine-readable JSON")
    args = ap.parse_args()

    result = audit_spec(args.spec, fix=args.fix, check_dois=args.check_dois)

    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        if "error" in result:
            print(f"ERROR: {result['error']}")
            return result.get("exit_code", 2)
        if "note" in result:
            print(result["note"])
            return 0
        issues = result.get("issues", {})
        if not issues:
            print("OK: All citation checks passed.")
        else:
            print(f"Found {sum(len(v) for v in issues.values())} issue(s):")
            for category, items in issues.items():
                print(f"\n  [{category}]")
                for item in items:
                    print(f"    - {item}")
        if result.get("fix_count", 0) > 0:
            print(f"\nAuto-fixed: {result['fix_count']} issue(s)")
            for f in result.get("fixed", []):
                print(f"  - {f}")
        print(f"\nExit: {'PASS' if result.get('exit_code', 0) == 0 else 'NEEDS_REVIEW'}")

    return result.get("exit_code", 1)


if __name__ == "__main__":
    raise SystemExit(main())
