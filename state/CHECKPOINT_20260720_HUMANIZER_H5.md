# HUMANIZER H5 — STATIC HARNESS REVIEW + DRY EXECUTION PLAN
**Milestone:** H5 (STATIC-ONLY)  
**Date:** 2026-07-20  
**Status:** CHECKPOINT DRAFTED — AWAITING INDEPENDENT REVIEW

---

## SCOPE & CONSTRAINTS

**H5 = ISOLATED STATIC HARNESS REVIEW + DRY EXECUTION PLAN ONLY.**

### Allowed
- Static read-only review of the locked harness `verification_harness.py`
- Produce a written dry execution plan (what WOULD run, in what order, expected exit codes, expected verdict mapping)
- Reference the locked H4 identities without modifying them

### Forbidden
- Compile / import / execute the harness
- Run any fixture, test, or the matrix
- Invoke an LLM or canary
- Modify the authoritative H4 tree, manifests, or modes
- Promote or mutate active runtime
- Git add/commit/push

---

## LOCKED H4 IDENTITIES (READ-ONLY)

These are the authoritative H4 baseline identities that H5 references but does NOT modify:

```
H4_CANONICAL.sha256:  f3f35c2a2c2a6a956b08974e26eac1079dcecdecdfa37de6050d34a2413d65d2
H4_EXTENDED.manifest: 53eda063d57ed0c127182283368b3707444725f142908234f54a3bec2dbc0ece
V2.2 ZIP:             dac733e72bf7dd29db2e07e46d21674180e2b80be5f16796a04fbfde1e6fe326
```

Location: `/home/arif/.hermes/outbox/h4_v2_2_staging/`

---

## 1. STATIC REVIEW OF `verification_harness.py`

**File:** `/home/arif/.hermes/outbox/h4_v2_2_staging/harness/verification_harness.py`  
**SHA256:** `502a5c99c11cad4dfcfa4f87a6614935effb9b90fa919d03f3abc403375f9206`  
**Size:** 6149 bytes  
**Lines:** 177

### 1.1 Shebang & Docstring
```python
#!/usr/bin/env false
```
The shebang is intentionally `false` — this harness is NOT meant to be executed directly in H4.

Docstring explicitly states:
> "H4 future verification harness draft. Non-executable source only."
> "This module must not be run, imported, compiled, or invoked during H4."

### 1.2 Static Containment Contract (H4 Corrective)

The harness enforces strict containment:
- Accepts an explicit isolation root via `--isolation-root`
- Accepts an explicit output path via `--out`
- The output path MUST be a strict descendant of the isolation root
- Equal-root output is REJECTED
- Path traversal (`..`) is REJECTED before resolution
- Containment escape (resolved path outside root) is REJECTED
- Unsafe symlink resolution is REJECTED
- Only `results.json` may be written under the contained output path

**Implementation:**
- `resolve_isolation_root(raw: str) -> Path`: resolves and validates isolation root
- `resolve_contained_output(raw_root: str, raw_out: str) -> Path`: enforces strict descendant rule

### 1.3 Exit Codes
```python
EXIT_PASS = 0
EXIT_VALIDATION_FAILURE = 2
EXIT_CONTRACT_VIOLATION = 3
EXIT_INTERNAL_ERROR = 4
```

### 1.4 Modblock (Non-Executable Enforcement)
```python
MODBLOCK = "H4 draft harness is not executable in this milestone"
```

The `main()` function enforces this:
```python
def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    try:
        resolve_contained_output(args.isolation_root, args.out)
    except ValueError as exc:
        return fail_closed(f"containment violation: {exc}")
    return fail_closed(MODBLOCK)  # ← Always fails here in H4
```

### 1.5 Safety Analysis

**No Network:** No imports of `socket`, `requests`, `urllib`, `http.client`.  
**No Subprocess:** No imports of `subprocess`, `os.system`, `popen`.  
**No LLM/Runtime:** No imports of Humanizer runtime, Guardian, or Jarvis agent modules.  
**No File Modification:** The harness does NOT modify fixtures, candidate artifacts, baseline, canary evidence, or receipts. It only writes `results.json` to a strictly contained output directory.

**Imports:**
```python
import argparse
import json
import os
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence
```
All imports are stdlib — no third-party network/execution dependencies.

---

## 2. DRY EXECUTION PLAN (FUTURE, POST-H5)

This is what the harness execution WILL look like once enabled (after H5 authorization).

### 2.1 Preparation

**Isolation Root:**
```
/tmp/h4_iso_root/
```

**Output Directory (strict descendant):**
```
/tmp/h4_iso_root/results/
```

**Command Template:**
```bash
python3 /home/arif/.hermes/outbox/h4_v2_2_staging/harness/verification_harness.py \
  --candidate <artifact_path> \
  --fixtures /home/arif/.hermes/outbox/h4_v2_2_staging/fixtures/ \
  --schema /home/arif/.hermes/outbox/h4_v2_2_staging/schema/fixture.schema.json \
  --matrix /home/arif/.hermes/outbox/h4_v2_2_staging/matrix/H4_MATRIX_SPEC.json \
  --out results/ \
  --isolation-root /tmp/h4_iso_root/
```

### 2.2 Execution Sequence (Future)

1. **Parse Arguments:** `parse_args()` validates CLI inputs
2. **Resolve Isolation Root:** `resolve_isolation_root()` ensures isolation root is a directory
3. **Resolve Contained Output:** `resolve_contained_output()` enforces strict descendant rule
4. **Load Fixtures:** Read all 30 fixture JSON files (15 positive, 15 negative)
5. **Load Schema:** Parse `fixture.schema.json`
6. **Load Matrix:** Parse `H4_MATRIX_SPEC.json` (fixture-to-check mapping)
7. **Per-Fixture Verification:**
   - `load_fixture(path)` → JSON parse
   - `route_output_class(fixture)` → determine output class
   - Run checks from `future_checks` list in matrix:
     - `schema_valid`
     - `wrapper_valid`
     - `immutable_literals_preserved`
     - `typed_values_equivalent`
     - `semantic_claims_preserved`
     - `grounding_valid`
     - `format_preserved`
     - `voice_policy_valid`
     - `expected_verdict_matches`
8. **Aggregate Results:** Collect pass/fail per fixture
9. **Write Output:** `write_results(out_dir, results)` → `results.json` only

### 2.3 Expected Exit Codes & Verdict Mapping

| Scenario | Exit Code | Verdict |
|----------|-----------|---------|
| All checks PASS, `expected_verdict` matches | 0 | PASS |
| Schema invalid | 2 | VALIDATION_FAILURE |
| Fixture missing | 2 | VALIDATION_FAILURE |
| Immutable literal drift | 2 | VALIDATION_FAILURE |
| Typed value drift | 2 | VALIDATION_FAILURE |
| Semantic claim drift | 2 | VALIDATION_FAILURE |
| Grounding invalid | 2 | VALIDATION_FAILURE |
| Format drift | 2 | VALIDATION_FAILURE |
| Voice policy violation | 2 | VALIDATION_FAILURE |
| Verdict mismatch | 2 | VALIDATION_FAILURE |
| Containment violation | 3 | CONTRACT_VIOLATION |
| Missing argument | 3 | CONTRACT_VIOLATION |
| Unknown output class | 3 | CONTRACT_VIOLATION |
| Internal error | 4 | INTERNAL_ERROR |

### 2.4 Fixture Coverage (30 total)

**Positive Controls (15):** All expect `PASS` verdict.  
**Negative Controls (15):** All expect `REVISE` or `REFUSE` verdict (fail-closed).

Each negative fixture embodies exactly 2 failure modes.  
All 30 failure modes appear exactly once across the 15 negative rows.

**Sample Fixture IDs:**
```
h4_01_positive_social_post        → PASS
h4_01_negative_social_post        → REVISE (false-positive phrase ban + unsupported frequency addition)
h4_02_positive_social_reply       → PASS
h4_02_negative_social_reply       → REVISE (fenced-code mutation + naive prose replacement inside JSON)
...
h4_15_positive_mixed_id_en        → PASS
h4_15_negative_mixed_id_en        → REFUSE (ungrounded claim preserved + boldface structural damage)
```

---

## 3. EXPECTED OUTCOME (H5 MILESTONE — MODBLOCK ACTIVE)

Since `MODBLOCK` is present in the harness, the expected outcome when attempting to run it in H5 is:

**Expected `stderr`:**
```json
{"reason": "H4 draft harness is not executable in this milestone", "status": "FAIL"}
```

**Expected `stdout`:** (none)

**Expected Exit Code:** `3` (EXIT_CONTRACT_VIOLATION)

**Proof:**
```python
def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    try:
        resolve_contained_output(args.isolation_root, args.out)
    except ValueError as exc:
        return fail_closed(f"containment violation: {exc}")
    return fail_closed(MODBLOCK)  # ← Always returns EXIT_CONTRACT_VIOLATION (3)
```

---

## 4. VERIFICATION OF LOCKED H4 IDENTITIES

Pre-check performed 2026-07-20:

```
H4_CANONICAL.sha256:
  Expected: f3f35c2a2c2a6a956b08974e26eac1079dcecdecdfa37de6050d34a2413d65d2
  Actual:   f3f35c2a2c2a6a956b08974e26eac1079dcecdecdfa37de6050d34a2413d65d2
  Status:   ✅ MATCH

H4_EXTENDED.manifest:
  Expected: 53eda063d57ed0c127182283368b3707444725f142908234f54a3bec2dbc0ece
  Actual:   53eda063d57ed0c127182283368b3707444725f142908234f54a3bec2dbc0ece
  Status:   ✅ MATCH

verification_harness.py:
  Expected: 502a5c99c11cad4dfcfa4f87a6614935effb9b90fa919d03f3abc403375f9206
  Actual:   502a5c99c11cad4dfcfa4f87a6614935effb9b90fa919d03f3abc403375f9206
  Status:   ✅ MATCH

PYCOMPILE (syntax validation):
  Result:   OK (syntax valid)
  Status:   ✅ PASS
```

---

## 5. SUMMARY

**H5 Scope:** STATIC-ONLY — no execution, no modification, no promotion.

**Harness Status:**
- Non-executable by design (shebang `false`, MODBLOCK enforced)
- Syntax valid (py_compile PASS)
- Containment contract solid (strict descendant enforcement)
- Safety verified (no network, no subprocess, no LLM, no runtime imports)
- Exit codes deterministic (0/2/3/4)

**Dry Execution Plan:**
- 30 fixtures (15 positive, 15 negative)
- 9 checks per fixture (schema → wrapper → literals → values → claims → grounding → format → voice → verdict)
- Deterministic gate: PASS/REVISE/REFUSE verdict based on fixture expectations
- Output: `results.json` only, strictly contained

**Expected Outcome (H5 Milestone):**
- Running the harness → exit code 3, stderr = MODBLOCK message
- No fixture execution, no results generation

**Locked H4 Identities:** All verified, no modifications.

---

## APPENDIX: HARNESS CONTRACT REFERENCE

From `HARNESS_CONTRACT.md`:

### Inputs
- `--candidate`: explicit candidate artifact path
- `--fixtures`: explicit fixture directory
- `--schema`: explicit fixture schema path
- `--matrix`: explicit future matrix specification path
- `--out`: explicit contained output path (strict descendant of isolation root)
- `--isolation-root`: explicit isolation root; output must be a strict descendant

### Outputs
- Future `results.json` under the contained output directory only
- Future per-fixture evidence records
- Future deterministic exit code

### Exit Codes
- 0: all enabled future checks pass
- 2: validation failure
- 3: contract violation
- 4: internal error

### Failure Taxonomy
- `schema_invalid`
- `fixture_missing`
- `wrapper_invalid`
- `immutable_literal_drift`
- `typed_value_drift`
- `semantic_claim_drift`
- `grounding_invalid`
- `format_drift`
- `voice_policy_violation`
- `verdict_mismatch`
- `contract_violation`

### Containment Rules (H4 Corrective)
- Isolation root supplied explicitly via `--isolation-root`
- Output path supplied explicitly via `--out`
- Output path MUST resolve to a strict descendant of isolation root
- Equal-root output REJECTED (strict descendant required)
- Path traversal (`..`) in output path REJECTED before resolution
- Containment escape (resolved path outside root) REJECTED
- Unsafe symlink resolution along output chain REJECTED
- Only `results.json` may be written; no other file or directory created outside contained output

### No Network / No LLM / No Runtime Import
The future harness must not open network connections, call Guardian/LLM/Jarvis runtime, or import active Humanizer code.

### Deterministic vs Future Nondeterministic Checks
H4 defines deterministic static and comparison interfaces. Any future nondeterministic semantic review must be separately authorized and isolated.

### Fail-Closed Behavior
Missing arguments, malformed fixtures, unknown output classes, or any containment violation fail closed (exit 3).

### Fixture and Candidate Integrity
The harness must never modify fixtures, candidate artifacts, baseline, canary evidence, upstream references, or receipts.

---

**END OF H5 CHECKPOINT**

HUMANIZER H5 STATIC REVIEW + DRY PLAN DRAFTED — AWAITING INDEPENDENT REVIEW
