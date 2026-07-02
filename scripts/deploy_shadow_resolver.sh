#!/usr/bin/env bash
# =============================================================================
# deploy_shadow_resolver.sh
# -----------------------------------------------------------------------------
# GBrain-inspired SHADOW resolver for Jarvis.
#
# Goal:
# - Help Jarvis choose the right skill/flow BEFORE execution.
# - Log mismatch between user request and planned action.
# - DO NOT block actions yet. This is NOT action-gate v2.
# - Preserve existing authority: ARSIE / NEURO-ARC / A.R.S.I / 4 PIPA / factory.
#
# What it installs:
# 1) ~/.hermes/scripts/jarvis_shadow_resolver.py
#    A tiny deterministic classifier + JSONL logger.
# 2) Directive in ~/.hermes/memories/USER.md
#    Requires Jarvis to run resolver in SHADOW mode before multi-step tasks.
#
# Rollback:
# - Restore USER.md backup printed by this script.
# - rm ~/.hermes/scripts/jarvis_shadow_resolver.py
# =============================================================================
set -euo pipefail

USER_MD="${HERMES_USER_MD:-$HOME/.hermes/memories/USER.md}"
SCRIPTS_DIR="$HOME/.hermes/scripts"
RESOLVER="$SCRIPTS_DIR/jarvis_shadow_resolver.py"
LOG_DIR="$HOME/.hermes/logs"
LOG_FILE="$LOG_DIR/jarvis_shadow_resolver.jsonl"

mkdir -p "$SCRIPTS_DIR" "$LOG_DIR"
[ -f "$USER_MD" ] || { echo "ERROR: USER.md tidak ada di $USER_MD" >&2; exit 2; }

TS="$(date +%Y%m%d_%H%M%S)"
cp "$USER_MD" "${USER_MD}.bak.${TS}"
echo "backup: ${USER_MD}.bak.${TS}"

cat > "$RESOLVER" <<'PY'
#!/usr/bin/env python3
"""Jarvis shadow skill resolver.

Non-blocking classifier inspired by gbrain's resolver idea.
Logs expected route vs planned route so false-routing is visible.
Does not enforce or block.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import time
from pathlib import Path

LOG = Path.home() / ".hermes" / "logs" / "jarvis_shadow_resolver.jsonl"

DOC_WORDS = r"(pdf|docx|pptx|powerpoint|word|dokumen|makalah|laporan|proposal|business plan|strategi bisnis|slide|presentasi)"
VERIFY_WORDS = r"(verifikasi|verify|cek|audit|bukti|log|gate|hash|sha|compare|bandingkan|inspect)"
SEARCH_WORDS = r"(cari|search|sumber|referensi|jurnal|paper|artikel|data)"
CODE_WORDS = r"(repo|commit|patch|script|kode|deploy|git|github|fix|bug)"
MEMORY_WORDS = r"(ingat|catat|handoff|resume|checkpoint|lesson|memory|keputusan)"


def infer_expected(user_request: str) -> dict:
    q = user_request.lower()

    if re.search(VERIFY_WORDS, q) and re.search(DOC_WORDS, q):
        return {
            "intent": "document_gate_verification",
            "expected_flow": "verify_existing_artifact_then_report_raw_evidence",
            "expected_skill": "jarvis-document-factory/gate-readonly",
            "requires_gate": True,
            "forbidden": ["create_new_unrequested_document", "claim_done_without_raw_evidence"],
        }

    if re.search(DOC_WORDS, q):
        return {
            "intent": "document_generation",
            "expected_flow": "ARSI: audit->rancang_SPEC_blocks->validate_spec->run.py->gate->pipa4",
            "expected_skill": "jarvis-document-factory",
            "requires_gate": True,
            "forbidden": ["freehand_docx", "manual_pdf", "deliver_before_gate_pass"],
        }

    if re.search(SEARCH_WORDS, q):
        return {
            "intent": "research",
            "expected_flow": "search->verify_sources->synthesize_with_citations",
            "expected_skill": "academic-search or web/data-research",
            "requires_gate": False,
            "forbidden": ["invent_sources", "skip_source_verification"],
        }

    if re.search(CODE_WORDS, q):
        return {
            "intent": "code_or_infra_change",
            "expected_flow": "observe->patch->test->commit->deploy_instruction",
            "expected_skill": "repo/code tools",
            "requires_gate": False,
            "forbidden": ["patch_without_observe", "claim_verified_without_test"],
        }

    if re.search(MEMORY_WORDS, q):
        return {
            "intent": "memory_capture",
            "expected_flow": "capture_decision_with_source_context",
            "expected_skill": "memory/handoff",
            "requires_gate": False,
            "forbidden": ["overwrite_handoff_without_backup"],
        }

    return {
        "intent": "general",
        "expected_flow": "answer_or_clarify",
        "expected_skill": "none/general",
        "requires_gate": False,
        "forbidden": [],
    }


def detect_mismatch(expected: dict, planned: str) -> list[str]:
    p = planned.lower()
    issues = []

    if expected["intent"] == "document_gate_verification":
        if any(x in p for x in ["bikin makalah", "buat makalah", "create new", "generate new", "mulai makalah"]):
            issues.append("planned_new_document_while_user_requested_verification")
        if "background" in p and "raw" not in p and "log" not in p:
            issues.append("background_claim_without_raw_log_plan")

    if expected["intent"] == "document_generation":
        if "content" in p and "blocks" not in p:
            issues.append("spec_may_use_content_string_instead_of_blocks")
        if any(x in p for x in ["python-docx manual", "manual pdf", "freehand"]):
            issues.append("freehand_document_path_forbidden")

    if expected.get("requires_gate") and any(x in p for x in ["siap pakai", "done", "delivered", "production-ready"]):
        if "gate pass" not in p and "exit=0" not in p and "raw" not in p:
            issues.append("done_claim_planned_without_gate_evidence")

    return issues


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--user", required=True, help="User request text")
    ap.add_argument("--planned", default="", help="Jarvis planned next action/flow")
    ap.add_argument("--thread", default="", help="Optional thread/session id")
    args = ap.parse_args()

    expected = infer_expected(args.user)
    issues = detect_mismatch(expected, args.planned)
    rec = {
        "ts": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
        "thread": args.thread,
        "user_request": args.user[:1000],
        "planned": args.planned[:1000],
        "expected": expected,
        "mismatch": bool(issues),
        "issues": issues,
        "mode": "SHADOW_NO_BLOCK",
    }
    LOG.parent.mkdir(parents=True, exist_ok=True)
    with LOG.open("a", encoding="utf-8") as f:
        f.write(json.dumps(rec, ensure_ascii=False) + "\n")

    print(json.dumps(rec, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PY
chmod +x "$RESOLVER"
echo "installed: $RESOLVER"

M="## JARVIS SHADOW RESOLVER — NON-BLOCKING"
if grep -qF "$M" "$USER_MD"; then
  echo "SKIP: directive already exists: $M"
else
  cat >> "$USER_MD" <<'DIRECTIVE'

## JARVIS SHADOW RESOLVER — NON-BLOCKING
Sebelum menjalankan tugas multi-step, dokumen, repo/deploy, riset, atau verifikasi gate, jalankan shadow resolver untuk mencatat intent user vs rencana aksi. Ini SHADOW ONLY: tidak memblokir aksi, tidak mengganti ARSIE / NEURO-ARC / A.R.S.I / 4 PIPA.

Command template:
/home/arif/.hermes/hermes-agent/venv/bin/python ~/.hermes/scripts/jarvis_shadow_resolver.py --user "<permintaan user>" --planned "<rencana aksi Jarvis sebelum eksekusi>"

Aturan:
1. Jika resolver output `mismatch: true`, JANGAN otomatis lanjut ke aksi berbeda. Berhenti sebentar, baca `issues`, lalu selaraskan rencana dengan permintaan user.
2. Untuk document generation: SPEC wajib `blocks: [...]`, bukan `content: "string"`.
3. Untuk verifikasi gate/dokumen: jangan membuat dokumen baru kecuali user eksplisit minta.
4. Untuk klaim DONE/SIAP PAKAI/DELIVERED: wajib ada raw evidence gate PASS / EXIT=0 / JSON run.py.
5. Log ada di: ~/.hermes/logs/jarvis_shadow_resolver.jsonl

Tujuan: membuktikan kapan Jarvis mulai salah routing tanpa menaikkan action-gate v2 dulu.
DIRECTIVE
  echo "OK: directive appended to USER.md"
fi

echo "=== proof ==="
ls -la "$RESOLVER"
grep -nF "$M" "$USER_MD"
echo "log: $LOG_FILE"
echo "rollback: cp ${USER_MD}.bak.${TS} $USER_MD && rm -f $RESOLVER"
