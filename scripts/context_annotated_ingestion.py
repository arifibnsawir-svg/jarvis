#!/usr/bin/env python3
"""Context-Annotated Ingestion — auto-classify user turns into memory entries.

Reads a user message and classifies it into:
  - content_type: speculation, decision, fact, insight, rule, deliverable, general
  - tags: extracted from keywords + domain context
  - inferred_state: exploratory, decisive, tired, urgent, casual
  - confidence_marker: high, medium, low (how sure the classifier is)

Then calls temporal_tiered_memory.py ingest automatically.

Usage:
  echo "bro, analisa bisnis saas gue dong" | python3 context_annotated_ingestion.py --session session_001
  python3 context_annotated_ingestion.py --text "kita putusin margin kiri 4cm" --tags rule,dosen_slamet --type decision

Design: zero-dep, deterministic keyword classifier. For production, this would
be an LLM-powered annotator, but the architecture is the same.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

_MEMORY_SCRIPT = Path.home() / ".hermes" / "scripts" / "temporal_tiered_memory.py"
_VENV_PY = os.environ.get("HERMES_VENV_PY", str(Path.home() / ".hermes" / "hermes-agent" / "venv" / "bin" / "python"))

# ── keyword → content_type mapping ────────────────────────────────────────

_TYPE_KEYWORDS = {
    "decision": [
        r"\b(putuskan|putusin|keputusan|memutuskan|final|ok setuju|oke setuju|deal|lock)\b",
        r"\b(jadi gini|kesimpulannya|intinya|konklusinya)\b",
    ],
    "speculation": [
        r"\b(mungkin|seandainya|gimana kalau|coba bayangin|what if|bisa jadi|andaikan|kalau misalnya)\b",
        r"\b(spekulasi|hipotesis|dugaan|tebakan|ngasal|liar|gila|random idea)\b",
    ],
    "fact": [
        r"\b(berdasarkan|menurut data|hasilnya|faktanya|terbukti|confirmed|data menunjukkan|statistik)\b",
    ],
    "insight": [
        r"\b(insight|realisasi|baru sadar|oh iya|ternyata|aha|learning|lesson|pola|pattern)\b",
    ],
    "rule": [
        r"\b(aturan|rule|syarat|wajib|harus|ketentuan|dosen|prof|pak\s+\w+|bu\s+\w+)\b.*\b(format|margin|font|spasi|halaman|apa style|sitasi)\b",
    ],
    "deliverable": [
        r"\b(deliver|kirim|submit|kumpulin|final|pdf|docx|pptx|file jadi|output)\b",
    ],
    "brainstorm": [
        r"\b(brainstorm|ide|gagasan|pikiran|konsep|rancangan|blueprint|desain|arsitektur)\b",
    ],
}

_DOMAIN_TAGS = {
    "akademik": [r"\b(dosen|prof|pak\s+\w+|bu\s+\w+|makalah|skripsi|tugas|kuliah|sidang|jurnal|kampus|semester)\b"],
    "bisnis": [r"\b(bisnis|startup|saas|revenue|profit|pricing|customer|churn|mrr|arr|investor|pitch|market)\b"],
    "infra": [r"\b(repo|github|git|commit|deploy|server|gateway|router|plugin|venv|config|restart)\b"],
    "brainstorm": [r"\b(brainstorm|gila|liar|spekulasi|what if|konsep|blueprint|grand design|visi|arsitektur)\b"],
}

_STATE_KEYWORDS = {
    "exploratory": [r"\b(gimana kalau|coba|mungkin|eksplor|brainstorm|ide)\b"],
    "decisive": [r"\b(putuskan|final|deal|lock|ok setuju|jadi)\b"],
    "tired": [r"\b(capek|lelah|ngantuk|istirahat|besok aja|nanti aja|later|tomorrow)\b"],
    "urgent": [r"\b(urgent|penting|sekarang|cepat|deadline|besok dikumpul|mepet)\b"],
}


def classify(message: str) -> dict:
    """Classify a user message into content_type, tags, state, confidence."""
    text = message.lower()

    # Content type: first match wins (priority-ordered)
    content_type = "general"
    type_confidence = "low"
    for ctype, patterns in _TYPE_KEYWORDS.items():
        for pattern in patterns:
            if re.search(pattern, text):
                content_type = ctype
                type_confidence = "medium"
                break
        if content_type != "general":
            break

    # Tags: extract from domain keywords
    tags: list[str] = []
    for domain, patterns in _DOMAIN_TAGS.items():
        for pattern in patterns:
            if re.search(pattern, text):
                tags.append(domain)
                break

    # Also extract specific entity tags (capitalized words, project names)
    entity_pattern = re.compile(r"\b([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)?)\b")
    entities = entity_pattern.findall(message)
    # Filter out common words
    stop_entities = {"Saya", "Kita", "Ini", "Itu", "Yang", "Untuk", "Dengan", "Pada", "Dari",
                     "Akan", "Tidak", "Bukan", "Sebagai", "Oleh", "Juga", "Agar", "Serta",
                     "Antara", "Terhadap", "Para", "Suatu", "Secara", "Karena", "Tentang",
                     "Kepada", "Bagi", "Jarvis", "Arif", "Bro", "Gua", "Lo"}
    for entity in entities:
        if entity not in stop_entities and len(entity) > 1:
            tags.append(entity.lower().replace(" ", "_"))

    # Remove duplicates, preserve order
    seen = set()
    unique_tags = []
    for t in tags:
        if t not in seen:
            seen.add(t)
            unique_tags.append(t)

    # Inferred state
    inferred_state = "casual"
    for state, patterns in _STATE_KEYWORDS.items():
        for pattern in patterns:
            if re.search(pattern, text):
                inferred_state = state
                break
        if inferred_state != "casual":
            break

    # Boost confidence if multiple signals agree
    if content_type != "general" and len(unique_tags) >= 2:
        type_confidence = "high"

    return {
        "content_type": content_type,
        "tags": unique_tags,
        "inferred_state": inferred_state,
        "confidence_marker": type_confidence,
        "source_type": "text_message",
    }


def ingest_auto(message: str, session: str = "", force_type: str = "", force_tags: str = "") -> dict:
    """Classify and ingest a message into temporal memory.

    Returns the classification result + ingest status.
    """
    classification = classify(message)

    # Override with explicit flags if provided
    content_type = force_type or classification["content_type"]
    if force_tags:
        tags = [t.strip() for t in force_tags.split(",") if t.strip()]
    else:
        tags = classification["tags"]

    # Skip ingestion for trivial/general messages
    if content_type == "general" and not tags:
        return {
            "ingested": False,
            "reason": "trivial message — no content type or tags detected",
            "classification": classification,
        }

    # Build context wrapper
    context_wrapper = {
        "source_type": "text_message",
        "inferred_state": classification["inferred_state"],
        "confidence_marker": classification["confidence_marker"],
        "auto_ingested": True,
        "ingested_at": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
    }

    # Call temporal_tiered_memory.py ingest
    if _MEMORY_SCRIPT.exists():
        try:
            result = subprocess.run(
                [_VENV_PY, str(_MEMORY_SCRIPT), "ingest",
                 "--text", message,
                 "--type", content_type,
                 "--tags", ",".join(tags),
                 "--session", session,
                 "--layer", "episodic"],
                capture_output=True, text=True, timeout=10,
            )
            ingested = result.returncode == 0
        except Exception as e:
            ingested = False
            result = None
    else:
        ingested = False

    return {
        "ingested": ingested,
        "content_type": content_type,
        "tags": tags,
        "classification": classification,
        "context_wrapper": context_wrapper,
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Context-Annotated Ingestion for Monster Jarvis")
    ap.add_argument("--text", default="", help="Message text to classify and ingest")
    ap.add_argument("--session", default="", help="Session/thread ID")
    ap.add_argument("--type", default="", dest="force_type", help="Force content type")
    ap.add_argument("--tags", default="", dest="force_tags", help="Force tags (comma-separated)")
    ap.add_argument("--classify-only", action="store_true", help="Only classify, do not ingest")
    ap.add_argument("--json", action="store_true", help="Output JSON")
    args = ap.parse_args()

    text = args.text or sys.stdin.read().strip()
    if not text:
        print("ERROR: no message text provided", file=sys.stderr)
        return 2

    if args.classify_only:
        result = classify(text)
        if args.json:
            print(json.dumps(result, ensure_ascii=False, indent=2))
        else:
            print(f"type={result['content_type']} state={result['inferred_state']} "
                  f"confidence={result['confidence_marker']} tags={result['tags']}")
        return 0

    result = ingest_auto(text, session=args.session,
                         force_type=args.force_type, force_tags=args.force_tags)
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        if result["ingested"]:
            print(f"✓ Ingested: {result['content_type']} | tags={result['tags']}")
        else:
            print(f"✗ Skipped: {result.get('reason', 'unknown')}")
    return 0 if result["ingested"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
