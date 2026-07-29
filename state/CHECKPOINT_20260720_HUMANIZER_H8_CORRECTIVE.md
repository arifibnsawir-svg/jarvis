# CHECKPOINT H8-CORRECTIVE — GENERALIZATION FIX + HELD-OUT EXPANSION
Date: 2026-07-20
Time: 22:15 WIB (approx)

## Locked Identities (unchanged, read-only)
- H4_CANONICAL.sha256: f3f35c2a2c2a6a956b08974e26eac1079dcecdecdfa37de6050d34a2413d65d2
- H4_EXTENDED.manifest: 53eda063d57ed0c127182283368b3707444725f142908234f54a3bec2dbc0ece
- V2.2 ZIP: dac733e72bf7dd29db2e07e46d21674180e2b80be5f16796a04fbfde1e6fe326
- Authoritative 502a5c99... fixtures/schema/matrix: **UNCHANGED** (sandbox only)

## Verification Results
- Baseline 30 fixtures: **30/30 match. EXIT=0.** (h4_04 → REVISE, regresi fixed)
- Held-out 8 fixtures: **8/8 match. EXIT=0.** (6 unseen + 2 original)
- Failure modes covered: equation mutation (symbolic+code), entity swap (new names), number/percentage drift, quotation mutation, unsupported marker, plus 2 positive controls

## Harness & Bundle SHA
- Sandbox harness SHA-256: `67d400041eb7f79a6eece81c58c1e03b344a9e21f8ab6c0184e53713c6f62baf`
- Bundle ZIP SHA-256: `12a9d1a21b79ef55c4ac390b4bcf1ff0641ece8d38827101d349bfd43d6f2c37`

## Generalization Changes (vs H7 hardcoded)
- Rule #4 equation operator mutation: operand-chain parse (numeric + symbolic)
- Rule #7 entity/subject swap: role-based (verb, object) detection
- All other H8 rules maintained: unsupported marker, time scope, markdown list, negation, possibility→certainty, speaker shift, quotation removed, port/version/date/money/percentage mutation

## Caveats
(a) **Sisa hardcode belum fully de-overfit** — beberapa string seperti `revenue-cost/Balqis/[FAN]` sudah diganti, tapi deteksi entity swap masih bergantung pada sequence pattern `ProperNoun verb obj` dan belum cover semua bentuk (mis. entity swap tanpa verb eksplisit).
(b) **Severity mapping masih kasar** — entity swap saat ini mapping ke REVISE (karena cuma semantic violation), padahal untuk safety bisa dianggap lebih serius (REFUSE). Perlu tuning severity tier nanti.
(c) **Isolated sandbox only** — belum dipromote ke live/canary. Authoritative tree zero-touch.
(d) **Belum ada per-file MANIFEST.sha256** — bundle integrity masih rely pada ZIP-level SHA, bukan manifest granular.

## Next Gate
HUMANIZER H8-CORRECTIVE COMPLETE — AWAITING INDEPENDENT REVIEW
