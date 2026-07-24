# CONTINUITY_HANDOFF — Jarvis Humanizer H12 + H4/H5 Track (Portable)

_Purpose: single portable resume doc so tuning can continue from ANY model (Codex, other) using ONLY the GitHub repo `arifibnsawir-svg/jarvis`. Compiled from AUDITED-GOOD state on 2026-07-23. Authoritative master detail lives in Notion (private); this is the public-safe portable mirror._

## 0. TL;DR (current state)
- **H12 Humanizer skill update — Stage 1 COMPLETE & independently verified** (V10A → V10B → V10C all ACCEPTED).
- **Go-live = NO-GO.** Stage 2 FORBIDDEN. Winning candidate NOT selected. Git push of the corrective saga PARKED. Live Humanizer baseline UNCHANGED.
- **H5 static-harness track = ACCEPTED (static-evidence-only).** MODBLOCK locked; no runtime.
- Next (only on Arif's explicit go): Stage 2 = generate real outputs under updated skill + verify with harness `d881d7f9…`; Stage 3 = promotion-readiness (backup → promote → post-promote regression → live rollback) for Arif ACC.

## 1. Operating rule (STRICT — do not break)
Jarvis builds/patches LOCALLY → Arif MANUALLY relays ZIP + external sidecar → independent auditor (Notion AI / other) recomputes EVERYTHING from scratch → only after explicit ACCEPT does state advance. Jarvis never uploads directly; never skips gates; never self-promotes. Telegram-bot send does NOT count as an auditable attachment.

## 2. Repo separation (LOCKED)
- `arifibnsawir-svg/jarvis` = infra/tuning (scripts, action_gate, humanizer track, handoff). H12 handoff lives HERE.
- `arifbudiman575-ship-it/buku` = strategy/book (branding SOP, competitor watch). Do NOT mix.
- Anti-amnesia principles (reuse): state outside model; deterministic capsule; **PIPA4 = only authority for DONE**; append-only ledger.

## 3. H12 Humanizer — what it is
Live Humanizer = TWO loaded skills + ONE code module:
1. `~/.hermes/skills/humanizer/SKILL.md` — global, 18219 B, SHA `eacce5b6…` (v2.1.1, 24 patterns)
2. `~/.hermes/skills/creative/humanizer/SKILL.md` — creative, 31452 B, SHA `a3ee4dc8…` (v2.5.1, 29 patterns)
3. `~/.hermes/content-gate/humanizer.py` — 1139 B, SHA `3ed10186…` (forces Saya→gua / Anda→lo at runtime — voice-layer conflict flagged)
Update SOURCE = pinned upstream `blader/humanizer` commit `1b48564898e999219882660237fde01bf4843a0f`, `SKILL.md` 34017 B, SHA `243aecda…` (v2.8.2, 33 patterns).

### 5 decision gates (LOCKED by Arif)
1. GLOBAL = strict-safe modular (grounding/immutable-token/format-preservation/no-meta/contextual-voice = hard baseline; creative transforms conditional by output class, not absolute bans).
2. CREATIVE = full 2.8.2 capability via INCREMENTAL adaptation of live v2.5.1 (preserve Hermes metadata + Arif formal "saya"); do not overwrite wholesale.
3. `<humanized_output>` wrapper = harness/verifier-ONLY; forbidden in final Telegram/social/chat/document delivery.
4. `content-gate/humanizer.py` = IN H12 as isolated surgical precedence candidate only (no core rewrite; formal `saya` not blindly overwritten; structured/code/data protected; voice_policy.json alone insufficient unless code proven to read+enforce it).
5. Keep TWO skills separate (global baseline + creative overlay); no merge.

## 4. Stage 1 sub-milestones (all ACCEPTED, 23 Jul 2026)
| Milestone | Result | ZIP SHA256 |
|---|---|---|
| V10A (via clean V10A.3 repackage) | ACCEPTED | `59cf0bbfb3df621df8d460f0f572b00da6971f5c76c37e1fe98ab725f3b9ce30` |
| V10B (Candidate C + runtime contract) | ACCEPTED | `cfe804f0ff6fe71880bf4933299f6e7ad21a6ced1e5b3ef7373ce880edf36d0d` |
| V10C (final Stage-1 bundle) | ACCEPTED | `72ab21f007c4a814d28fd52f9993e56dbf18c96b9af790cd9dbe967d27b60af6` |

## 5. Locked identity registry (byte-identical through V10C)
- Candidate A (global)  `candidates/global/SKILL.md`  35559 B  `6dcbed33de0b3d725454cbc98672f2147b6429f7f29029594c11e77563605b2e` (33)
- Candidate B (creative) `candidates/creative/SKILL.md` 34831 B `012f5940b10a57afb0cc103b684bb325ba3823f6a2a7d2e8a0f786aaefa447ac` (33)
- Candidate C (hybrid)  `candidates/hybrid/SKILL.md`  33547 B  `8817d5b03e0a5b8d312319ed3b7c21cd67e97c664ba1fd252faebce43f2bed4f` (33)
- Snapshot global `source_snapshots/global_live_SKILL.md`  18219 B `eacce5b6dc4344dc610a50d92dcfd80c8ed67fd940e7e7ee4d004fd5965e1e05` (v2.1.1/24)
- Snapshot creative `source_snapshots/creative_live_SKILL.md` 31452 B `a3ee4dc8a42892c4e1fdc1df322a38256f061c97c0f255a18b744c00b71e870b` (v2.5.1/29)
- Snapshot upstream `source_snapshots/upstream_pinned_SKILL.md` 34017 B `243aecdafecb5e11c2d45e2e088b7876e3f6eee34aa50c53f624d8468039afa8` (v2.8.2/33)
- Crosswalk `crosswalk/H12_V10A2_PATTERN_CROSSWALK.json` 76743 B `f15fcc7d6c87e8fa1fb8f0eea1005649357df8c130e20fcb70f347c13a17944d` (33 patterns × 32 fields)
- Boundary (V10A) `receipts/SECTION_BOUNDARY_VALIDATION.json` 61498 B `cdcd5b74194f53544bd6205b37f5f6b696752745435a836002d73e1acf9fa93f` (99 records)
- Boundary (V10B) `receipts/V10B_SECTION_BOUNDARY_VALIDATION.json` 85140 B `efe09030c0a770ec5a2133515f47dfaef9134198fe83651708792c0d9c04d1f8` (132 records)
- Live-mapping `receipts/LIVE_MAPPING_VALIDATION.json` 18705 B `f2fa75cb587f55125d9262c16f70e2d59ca4c93068b7b49fd6a364e5c1fde8f6` (global 21 EXACT/12 ABSENT; creative 27 EXACT/6 ABSENT)
- Runtime contract `runtime/RUNTIME_CONTRACT.json` `a620e2bebde049621293128877b8c86512b2abcc0fb535d9e3254aa440665740`
- Diffs (8): a_vs_b `6231e1ba…`; creative_live_to_b `671b6e9f…`; global_live_to_a `e5a6562d…`; upstream_to_a `4b7f6572…`; upstream_to_b `e531b573…`; upstream_to_c `69149c71…`; a_vs_c `d8a53816…`; b_vs_c `9f5df8d1…`
- Manifest formats: `./path|<64-sha256>` and `./path|<sha256>|<bytes>|<lines-or-NA>|<mode>`. Rule: manifest_record_count == physical_files − 2. No MANIFEST.json; no build/seal scripts; no .py/.pyc/__pycache__ in payload.

## 6. H4 / H5 harness track (QA tool, separate from V10)
- H4 canonical `H4_CANONICAL.sha256` `f3f35c2a2c2a6a956b08974e26eac1079dcecdecdfa37de6050d34a2413d65d2`; H4 extended `53eda063d57ed0c127182283368b3707444725f142908234f54a3bec2dbc0ece`; accepted V2.2 ZIP `dac733e72bf7dd29db2e07e46d21674180e2b80be5f16796a04fbfde1e6fe326`.
- De-overfit QA harness (H8-CORR→H11) SHA `d881d7f94c2d39b4c86d766d06aede79498ded294f2f548449a92f12f86d879e` — THIS is the test Stage 2 must run against real outputs.
- H5 static: `verification_harness.py` `502a5c99c11cad4dfcfa4f87a6614935effb9b90fa919d03f3abc403375f9206` (177 lines/6149 B); MODBLOCK always exit 3; dry plan `h5_dry_execution_plan.md` `66ccbbb39f91fbe18dc3a01394ec09d6914e213678c58877b841e14b04281973`. 30 fixtures (15 classes × pos/neg); exit codes 0/2/3/4; verdicts PASS/REVISE/REFUSE.

## 7. Rejected evidence (read-only history — do NOT reuse as good)
- V10A ZIP `8f518b37…9121`; V10A.1 ZIP `7a61a65c…104f`; V10A.2 ZIP `58538252…537b9` (contained unmanifested `seal_v10a2.py` → 24 physical vs 21 manifest). All corrected in V10A.3.

## 8. Workspaces & repo anchors
- Workspaces: V10A `…/humanizer-h12-v10a-taxonomy/`; V10A.1 `…-v10a1-evidence-repair/`; V10A.2 `…-v10a2-schema-repair/`; V10A.3 `…-v10a3-repackage/`; V10B `…-v10b-candidate-c/`; V10C `…-v10c-final/`. Base `/home/arif/.hermes/workspaces/`. Outbox `/home/arif/.hermes/outbox/`.
- Local repo `/home/arif/jarvis`, branch `phase-a2-bridge`, local HEAD `a5897ad015623b55f33e1ad4918a41cd4f6d6980`. GitHub default `main` HEAD `a462ac9f5ef3c0ff9fed9145535d2d654a4e26f5` (stale; corrective saga NOT pushed).
- Canonical Notion (private master): Master Plan + Handoff (Ruang Budiman Arif).

## 9. Resume instructions for a new model
1. Read this file + repo `HANDOFF_CHECKPOINT.md` fully. Do NOT restart from zero.
2. Respect the operating rule (§1) and the 5 locked gates (§3).
3. To advance: Arif must explicitly authorize Stage 2. Then Jarvis (local) generates real outputs under the updated candidate skill, runs QA harness `d881d7f9…`, packages ZIP + external sidecar (real counts), and Arif relays for independent audit.
4. Never mutate live Humanizer baseline, never git push, never select a winning candidate, and never claim go-live without Arif ACC.
5. All bundles must satisfy: both manifests cover all files; manifest_record_count == physical − 2; no seal/py/pyc/pycache; locked identities (§5) byte-identical; sidecar counts computed not hardcoded.
