# Jarvis Filing Protocol — MANDATORY for session capture & memory organization

GBrain-inspired (`skills/_brain-filing-rules.md`), adapted for Jarvis stack.

## The Rule

The **PRIMARY SUBJECT** of the entry determines where it goes — not the format,
not the source, not whether it was captured automatically or manually.

## Decision Protocol

1. Identify the primary subject (a decision? a bug? a rule? a speculation?)
2. File in the target that matches the subject
3. Cross-link from related files (back-linking is mandatory)
4. When in doubt: what would you search for to find this again?

## Filing Targets

| Content type | Target file | When |
|---|---|---|
| **Decision** | `DECISIONS.md` | A choice was made that affects future work |
| **Bug / Lesson** | `LESSONS.md` | A mistake that should not be repeated |
| **Session summary** | `ARIF_STACK_EVENT_LOG.md` | End of session checkpoint |
| **Speculation / Brainstorm** | `memory/episodic_memory.jsonl` (via temporal_tiered_memory.py) | Wild ideas, half-baked |
| **Rule / Constraint** | `memory/crystallized_memory.jsonl` (via temporal_tiered_memory.py) | Permanent rules, crystallized |
| **Deliverable artifact** | `memory/crystallized_memory.jsonl` | Final output, locked |

## Common Misfiling Patterns — DO NOT DO THESE

| Wrong | Right | Why |
|-------|-------|-----|
| Decision about a project → `ARIF_STACK_EVENT_LOG.md` only | → ALSO ingest via `temporal_tiered_memory.py --type decision --tags <project>` | Memory retrieval needs it |
| Bug found → only mentioned in chat, not logged | → `LESSONS.md` + `temporal_tiered_memory.py ingest --type insight` | Bugs are reusable knowledge |
| Speculation about pricing → `DECISIONS.md` | → `temporal_tiered_memory.py ingest --type speculation --tags pricing,<project>` | Not a decision yet — let it decay |
| Rule from professor/client → only in SPEC file | → `temporal_tiered_memory.py ingest --type rule --layer crystallized --tags rule,<professor>` | Rules persist beyond one deliverable |

## Iron Law: Back-Linking (MANDATORY)

Every memory entry that references a previous entry MUST back-link.

Format for back-links:
```
## Related
- [YYYY-MM-DD] [session_id] — brief context
- [commit_sha] [repo] — related code change
```

An unlinked memory entry is a broken brain. The graph is the intelligence.

## Citation Requirements

Every claim written to memory must carry its source:
- **User stated:** `[Source: Arif, <session_id>, YYYY-MM-DD]`
- **Command output:** `[Source: terminal, <command_summary>, YYYY-MM-DD]`
- **Synthesis:** `[Source: consolidated from <N> sessions]`

Source precedence (highest to lowest):
1. User's direct statements (highest authority)
2. Terminal output (raw evidence)
3. Consolidated memory (pattern detection)
4. External sources (web search, API — lowest)

When sources conflict, note the contradiction with both citations. Don't silently pick one.

## Temporal Tiered Memory Integration

Every filed entry should also call `temporal_tiered_memory.py` to ensure
decay/graph/retrieval works:

```bash
# After a decision
$VENV ~/.hermes/scripts/temporal_tiered_memory.py ingest \
  --text "<decision_summary>" --type decision --tags <project>,<topic>

# After a rule is established
$VENV ~/.hermes/scripts/temporal_tiered_memory.py ingest \
  --text "<rule_text>" --type rule --layer crystallized --tags rule,<owner>

# After a session ends
$VENV ~/.hermes/scripts/temporal_tiered_memory.py stats
$VENV ~/.hermes/scripts/temporal_tiered_memory.py consolidate --min-sessions 2
```

## Tags Convention (for retrieval)

Use compound tags — domain_scoped, not generic:

| Generic (BAD) | Compound (GOOD) |
|---|---|
| `business` | `saas_venture`, `kedai_nusantara` |
| `academic` | `dosen_slamet`, `skripsi_metodologi` |
| `rule` | `rule_dosen_x_format`, `rule_brand_voice` |
| `bug` | `bug_citation_regex`, `bug_gate_timeout` |

This makes `retrieve --tag-filter dosen_slamet` return exactly that
professor's rules, not every academic rule ever.

## Dream-Cycle Integration (future)

When Jarvis runs overnight consolidation:
1. Scan `episodic_memory.jsonl` for entries past half-life
2. Detect patterns across 3+ entries with shared tags
3. Auto-promote to `crystallized_memory.jsonl`
4. Write pattern summary to `ARIF_STACK_EVENT_LOG.md`
