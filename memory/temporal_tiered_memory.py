#!/usr/bin/env python3
"""Temporal Tiered Memory — the cognitive memory backbone of Monster Jarvis.

Implements the three-layer memory architecture from the Grand Design:

  LAYER 1: WORKING MEMORY   — active TaskState, lifetime = 1 session
  LAYER 2: EPISODIC MEMORY  — decisions, insights, speculations (decay)
  LAYER 3: CRYSTALLIZED MEMORY — locked truth, permanent, zero decay

Key mechanisms:
  - Temporal weight decay: speculation half-life 3 days, decision 30 days
  - Signal booster: re-mention resets decay to 1.0
  - Memory consolidation: pattern detection across 3+ episodic entries
  - Content-type-aware retrieval scoring
  - JSONL backend (same pattern as shadow resolver), zero deps

Usage (CLI):
  python3 temporal_tiered_memory.py ingest --text "..." --type speculation --tags pricing
  python3 temporal_tiered_memory.py retrieve --query "pricing model" --top 5
  python3 temporal_tiered_memory.py consolidate --min-sessions 3
  python3 temporal_tiered_memory.py crystallize --id <entry_id>
  python3 temporal_tiered_memory.py booster --topic "pricing"
  python3 temporal_tiered_memory.py stats

Library usage:
  from temporal_tiered_memory import TieredMemoryStore
  store = TieredMemoryStore()
  store.ingest("spekulasi liar", content_type="speculation", tags=["pricing"])
  results = store.retrieve("pricing model", top_k=5)
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
import time
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Optional

# ── defaults ────────────────────────────────────────────────────────────────
_MEMORY_DIR = Path.home() / ".hermes" / "memory"
_WORKING_FILE = _MEMORY_DIR / "working_memory.jsonl"
_EPISODIC_FILE = _MEMORY_DIR / "episodic_memory.jsonl"
_CRYSTALLIZED_FILE = _MEMORY_DIR / "crystallized_memory.jsonl"

# ── content-type decay profiles ────────────────────────────────────────────
# half_life_days: after this many days, weight = 0.5 (linear decay)
# retrieval_boost: multiplier applied at retrieval time
DECAY_PROFILES = {
    "speculation":     {"half_life_days": 7,  "retrieval_boost": 0.5},
    "decision":        {"half_life_days": 30, "retrieval_boost": 2.0},
    "brainstorm":      {"half_life_days": 7,  "retrieval_boost": 0.5},
    "insight":         {"half_life_days": 60, "retrieval_boost": 1.5},
    "fact":            {"half_life_days": 90, "retrieval_boost": 1.5},
    "deliverable":     {"half_life_days": None, "retrieval_boost": 3.0},  # None = never decays (crystallized)
    "research_note":    {"half_life_days": 90, "retrieval_boost": 1.2},
    "voice_note":       {"half_life_days": 7,  "retrieval_boost": 0.6},
    "screenshot_find": {"half_life_days": 14, "retrieval_boost": 0.7},
    "pattern":          {"half_life_days": None, "retrieval_boost": 3.0},  # consolidated patterns are permanent
    "rule":             {"half_life_days": None, "retrieval_boost": 3.0},  # locked rules
}

# ── data model ─────────────────────────────────────────────────────────────

@dataclass
class MemoryEntry:
    id: str
    text: str
    content_type: str = "speculation"
    tags: list[str] = field(default_factory=list)
    temporal_weight: float = 1.0
    created_at: float = 0.0          # epoch
    last_boosted_at: float = 0.0     # epoch
    boost_count: int = 0
    source_session: str = ""         # thread/session id
    context_wrapper: dict = field(default_factory=dict)  # {source_type, inferred_state, confidence_marker, emotional_tone}
    layer: str = "episodic"          # "working" | "episodic" | "crystallized"
    half_life_days: Optional[float] = None
    retrieval_boost: float = 1.0

    @classmethod
    def from_dict(cls, d: dict) -> "MemoryEntry":
        return cls(
            id=d.get("id", ""),
            text=d.get("text", ""),
            content_type=d.get("content_type", "speculation"),
            tags=d.get("tags", []),
            temporal_weight=d.get("temporal_weight", 1.0),
            created_at=d.get("created_at", 0.0),
            last_boosted_at=d.get("last_boosted_at", 0.0),
            boost_count=d.get("boost_count", 0),
            source_session=d.get("source_session", ""),
            context_wrapper=d.get("context_wrapper", {}),
            layer=d.get("layer", "episodic"),
            half_life_days=d.get("half_life_days"),
            retrieval_boost=d.get("retrieval_boost", 1.0),
        )


# ── core engine ────────────────────────────────────────────────────────────

class TieredMemoryStore:
    """Three-layer temporal memory with decay, boost, and consolidation."""

    def __init__(self, base_dir: Path | None = None):
        self.base = base_dir or _MEMORY_DIR
        self.base.mkdir(parents=True, exist_ok=True)
        self.working_path = self.base / "working_memory.jsonl"
        self.episodic_path = self.base / "episodic_memory.jsonl"
        self.crystallized_path = self.base / "crystallized_memory.jsonl"

    # ── read / write helpers ──────────────────────────────────────────

    def _read_all(self, path: Path) -> list[MemoryEntry]:
        if not path.exists():
            return []
        entries = []
        with path.open("r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line:
                    try:
                        entries.append(MemoryEntry.from_dict(json.loads(line)))
                    except (json.JSONDecodeError, KeyError):
                        pass
        return entries

    def _append(self, path: Path, entry: MemoryEntry) -> None:
        with path.open("a", encoding="utf-8") as f:
            f.write(json.dumps(asdict(entry), ensure_ascii=False) + "\n")

    def _rewrite(self, path: Path, entries: list[MemoryEntry]) -> None:
        tmp = path.with_suffix(path.suffix + ".tmp")
        with tmp.open("w", encoding="utf-8") as f:
            for e in entries:
                f.write(json.dumps(asdict(e), ensure_ascii=False) + "\n")
        tmp.replace(path)

    def _entry_id(self, text: str) -> str:
        return hashlib.blake2b(text.encode("utf-8"), digest_size=8).hexdigest()

    def _compute_weight(self, entry: MemoryEntry, now: float | None = None) -> float:
        """Return current temporal weight, applying linear decay since last boost."""
        if entry.half_life_days is None:
            return 1.0  # crystallized: never decays
        now = now or time.time()
        age_days = (now - max(entry.created_at, entry.last_boosted_at)) / 86400.0
        if entry.half_life_days <= 0:
            return entry.temporal_weight
        decay = age_days / entry.half_life_days
        return max(0.001, entry.temporal_weight * (1.0 - decay))

    # ── public API ────────────────────────────────────────────────────

    def ingest(
        self,
        text: str,
        content_type: str = "speculation",
        tags: list[str] | None = None,
        source_session: str = "",
        context_wrapper: dict | None = None,
        layer: str = "episodic",
    ) -> MemoryEntry:
        """Write a new memory entry. Returns the created entry."""
        profile = DECAY_PROFILES.get(content_type, DECAY_PROFILES["speculation"])
        now = time.time()
        entry = MemoryEntry(
            id=self._entry_id(text),
            text=text,
            content_type=content_type,
            tags=tags or [],
            temporal_weight=1.0,
            created_at=now,
            last_boosted_at=now,
            boost_count=0,
            source_session=source_session,
            context_wrapper=context_wrapper or {},
            layer=layer,
            half_life_days=profile["half_life_days"],
            retrieval_boost=profile["retrieval_boost"],
        )
        if layer == "working":
            self._append(self.working_path, entry)
        elif layer == "crystallized":
            self._append(self.crystallized_path, entry)
        else:
            self._append(self.episodic_path, entry)
        return entry

    def retrieve(
        self,
        query: str = "",
        top_k: int = 10,
        include_working: bool = False,
        include_episodic: bool = True,
        include_crystallized: bool = True,
        content_type_filter: str | None = None,
        tag_filter: str | None = None,
    ) -> list[MemoryEntry]:
        """Retrieve entries ranked by (relevance × temporal_weight × retrieval_boost).

        Relevance is approximate (substring + tag match) because this is a
        zero-dep JSONL store. For production semantic search, this would
        plug into sqlite-vec or the Hermes embedding pipeline.
        """
        now = time.time()
        candidates: list[MemoryEntry] = []

        if include_working:
            candidates.extend(self._read_all(self.working_path))
        if include_episodic:
            candidates.extend(self._read_all(self.episodic_path))
        if include_crystallized:
            candidates.extend(self._read_all(self.crystallized_path))

        # compute current weight
        for e in candidates:
            e.temporal_weight = self._compute_weight(e, now)

        # filter
        if content_type_filter:
            candidates = [e for e in candidates if e.content_type == content_type_filter]
        if tag_filter:
            candidates = [e for e in candidates if tag_filter in e.tags]

        # score
        q = query.lower()
        def score(e: MemoryEntry) -> float:
            s = e.temporal_weight * e.retrieval_boost
            if q:
                text_low = e.text.lower()
                # substring bonus
                if q in text_low:
                    s *= 3.0
                # tag match bonus
                if any(q in t.lower() or t.lower() in q for t in e.tags):
                    s *= 2.0
                # keyword overlap bonus (cheap bag-of-words)
                q_words = set(q.split())
                t_words = set(text_low.split())
                overlap = len(q_words & t_words)
                if overlap > 0:
                    s *= 1.0 + (overlap / max(len(q_words), 1)) * 2.0
            return s

        candidates.sort(key=score, reverse=True)
        return candidates[:top_k]

    def boost(self, topic: str, multiplier: float = 1.0) -> int:
        """Signal booster: reset decay for all entries matching a topic.

        Returns the number of entries boosted.
        """
        now = time.time()
        q = topic.lower()
        boosted = 0
        for path in [self.episodic_path, self.working_path]:
            entries = self._read_all(path)
            changed = False
            for e in entries:
                if q in e.text.lower() or any(q in t.lower() or t.lower() in q for t in e.tags):
                    e.temporal_weight = 1.0
                    e.last_boosted_at = now
                    e.boost_count += 1
                    boosted += 1
                    changed = True
            if changed:
                self._rewrite(path, entries)
        return boosted

    def consolidate(self, min_sessions: int = 3) -> list[MemoryEntry]:
        """Memory consolidation: detect patterns across 3+ episodic entries
        and promote them to crystallized memory.

        Returns the list of newly crystallized entries.
        """
        episodic = self._read_all(self.episodic_path)
        crystallized_texts = {e.text for e in self._read_all(self.crystallized_path)}

        # Group by content_type + tags signature
        groups: dict[str, list[MemoryEntry]] = {}
        for e in episodic:
            key = f"{e.content_type}||{",".join(sorted(e.tags))}"
            groups.setdefault(key, []).append(e)

        new_crystallized: list[MemoryEntry] = []
        for key, group in groups.items():
            if len(group) < min_sessions:
                continue
            # Check if any entry is already crystallized
            if any(e.text in crystallized_texts for e in group):
                continue
            # Promote the most recent entry
            group.sort(key=lambda e: e.created_at, reverse=True)
            representative = group[0]
            pattern_entry = MemoryEntry(
                id=self._entry_id(f"consolidated:{representative.id}"),
                text=f"[PATTERN from {len(group)} sessions] {representative.text}",
                content_type="pattern",
                tags=list(set(t for e in group for t in e.tags)),
                temporal_weight=1.0,
                created_at=time.time(),
                last_boosted_at=time.time(),
                boost_count=0,
                source_session=",".join(sorted({e.source_session for e in group if e.source_session})),
                context_wrapper={"source_count": len(group), "source_type": "consolidation"},
                layer="crystallized",
                half_life_days=None,  # permanent
                retrieval_boost=DECAY_PROFILES["pattern"]["retrieval_boost"],
            )
            self._append(self.crystallized_path, pattern_entry)
            new_crystallized.append(pattern_entry)

        return new_crystallized

    def crystallize(self, entry_id: str) -> Optional[MemoryEntry]:
        """Manually promote one episodic entry to crystallized (Crystallization Gateway)."""
        episodic = self._read_all(self.episodic_path)
        crystallized = self._read_all(self.crystallized_path)
        for i, e in enumerate(episodic):
            if e.id == entry_id:
                e.layer = "crystallized"
                e.half_life_days = None  # permanent
                e.retrieval_boost = DECAY_PROFILES["rule"]["retrieval_boost"]
                e.content_type = "rule"
                self._append(self.crystallized_path, e)
                # Remove from episodic
                del episodic[i]
                self._rewrite(self.episodic_path, episodic)
                return e
        return None

    def stats(self) -> dict:
        """Return memory health stats."""
        working = self._read_all(self.working_path)
        episodic = self._read_all(self.episodic_path)
        crystallized = self._read_all(self.crystallized_path)
        now = time.time()
        decayed = sum(1 for e in episodic if self._compute_weight(e, now) < 0.1)
        return {
            "working_count": len(working),
            "episodic_count": len(episodic),
            "crystallized_count": len(crystallized),
            "total": len(working) + len(episodic) + len(crystallized),
            "decayed_below_10pct": decayed,
            "half_life_remaining_pct": round(100 * (len(episodic) - decayed) / max(len(episodic), 1)),
        }


# ── CLI ────────────────────────────────────────────────────────────────────

def _main() -> int:
    ap = argparse.ArgumentParser(description="Temporal Tiered Memory — Monster Jarvis memory backbone")
    sub = ap.add_subparsers(dest="cmd")

    # ingest
    p = sub.add_parser("ingest")
    p.add_argument("--text", required=True)
    p.add_argument("--type", default="speculation", dest="content_type")
    p.add_argument("--tags", default="")
    p.add_argument("--session", default="")
    p.add_argument("--layer", default="episodic", choices=["working","episodic","crystallized"])

    # retrieve
    p = sub.add_parser("retrieve")
    p.add_argument("--query", default="")
    p.add_argument("--top", type=int, default=10)
    p.add_argument("--type-filter", default="")
    p.add_argument("--tag-filter", default="")
    p.add_argument("--no-episodic", action="store_true")
    p.add_argument("--no-crystallized", action="store_true")

    # boost
    p = sub.add_parser("boost")
    p.add_argument("--topic", required=True)

    # consolidate
    p = sub.add_parser("consolidate")
    p.add_argument("--min-sessions", type=int, default=3)

    # crystallize
    p = sub.add_parser("crystallize")
    p.add_argument("--id", required=True, dest="entry_id")

    # stats
    sub.add_parser("stats")

    args = ap.parse_args()
    store = TieredMemoryStore()

    if args.cmd == "ingest":
        entry = store.ingest(
            text=args.text,
            content_type=args.content_type,
            tags=[t.strip() for t in args.tags.split(",") if t.strip()],
            source_session=args.session,
            layer=args.layer,
        )
        print(json.dumps(asdict(entry), ensure_ascii=False, indent=2))

    elif args.cmd == "retrieve":
        results = store.retrieve(
            query=args.query,
            top_k=args.top,
            include_episodic=not args.no_episodic,
            include_crystallized=not args.no_crystallized,
            content_type_filter=args.type_filter or None,
            tag_filter=args.tag_filter or None,
        )
        for r in results:
            d = asdict(r)
            d["text"] = d["text"][:200]  # truncate for display
            print(json.dumps(d, ensure_ascii=False))

    elif args.cmd == "boost":
        n = store.boost(args.topic)
        print(f"Signal boosted {n} entries for topic: {args.topic}")

    elif args.cmd == "consolidate":
        new = store.consolidate(min_sessions=args.min_sessions)
        print(f"Consolidated {len(new)} new patterns into crystallized memory")
        for e in new:
            print(f"  [{e.content_type}] {e.text[:120]}")

    elif args.cmd == "crystallize":
        entry = store.crystallize(args.entry_id)
        if entry:
            print(f"Crystallized: {entry.text[:120]}")
        else:
            print(f"Entry not found: {args.entry_id}")
            return 1

    elif args.cmd == "stats":
        s = store.stats()
        print(json.dumps(s, ensure_ascii=False, indent=2))

    else:
        ap.print_help()

    return 0


if __name__ == "__main__":
    raise SystemExit(_main())
