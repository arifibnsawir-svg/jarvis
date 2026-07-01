#!/usr/bin/env python3
"""PIPA4 HOOK — auto-trigger PIPA4 council audit after document-factory gate PASS.

Masalah yang diatasi (CHECKPOINT 12.29 + audit 2026-07-01):
  PIPA4 council (LLM audit via jarvis-reason) hanya bisa dipicu MANUAL
  (/pipa4_gate.sh atau /pipa4-review-dryrun). Tidak ada wiring otomatis
  dari document-factory pipeline ke PIPA4.

Lokasi: repo jarvis > scripts/pipa4_hook.py.
Deploy: cp ke ~/.hermes/scripts/pipa4_hook.py (bareng pipa4_gate.sh).
Dipanggil dari: jarvis_document_factory/docfactory/orchestrator.py
              (via _load_pipa4_hook() — sys.path import, fail-open).

TIDAK tergantung factory — PIPA4 = infra terpisah (repo jarvis).
Factory tetap self-contained; import ini via dynamic lookup.
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
from typing import Optional

_PIPA4_GATE_SH = os.path.expanduser("~/.hermes/scripts/pipa4_gate.sh")
_PIPA4_CONSTRAINTS_DIR = os.path.expanduser("~/.hermes/pipelines/pipa4/constraints")
_DEFAULT_CONSTRAINT = "academic_book.json"


def _find_gate_script() -> Optional[str]:
    candidates = [
        os.environ.get("PIPA4_GATE_SCRIPT", ""),
        _PIPA4_GATE_SH,
        os.path.expanduser("~/jarvis/scripts/pipa4_gate.sh"),
    ]
    for path in candidates:
        if path and os.path.isfile(path) and os.access(path, os.X_OK):
            return path
    return None


def _find_constraint(constraint_name: Optional[str] = None) -> Optional[str]:
    name = constraint_name or _DEFAULT_CONSTRAINT
    candidates = [
        os.environ.get("PIPA4_CONSTRAINT", ""),
        os.path.join(_PIPA4_CONSTRAINTS_DIR, name),
        os.path.join(_PIPA4_CONSTRAINTS_DIR, _DEFAULT_CONSTRAINT),
    ]
    for path in candidates:
        if path and os.path.isfile(path):
            return path
    return None


def run(artifact_path: str, constraint_name: Optional[str] = None,
        timeout_seconds: int = 420) -> dict:
    """Panggil PIPA4 council untuk satu artifact.

    Return dict dgn keys: triggered, verdict, final_status, false_ready_count,
    exit_code, output_tail, reason_skipped.
    Fail-open: kalau PIPA4/gate/constraint gak ada -> skip (triggered=False).
    Kill-switch: env PIPA4_AUTO=off -> skip.
    """
    if os.environ.get("PIPA4_AUTO", "").lower() == "off":
        return {
            "triggered": False, "verdict": "SKIPPED",
            "reason_skipped": "PIPA4_AUTO=off (kill-switch)",
            "final_status": None, "false_ready_count": None,
            "exit_code": None, "output_tail": "",
        }

    gate_sh = _find_gate_script()
    if gate_sh is None:
        return {
            "triggered": False, "verdict": "SKIPPED",
            "reason_skipped": "pipa4_gate.sh tidak ditemukan (PIPA4 belum di-deploy di Acer)",
            "final_status": None, "false_ready_count": None,
            "exit_code": None, "output_tail": "",
        }

    constraint = _find_constraint(constraint_name)
    if constraint is None:
        return {
            "triggered": False, "verdict": "SKIPPED",
            "reason_skipped": "constraint tidak ditemukan",
            "final_status": None, "false_ready_count": None,
            "exit_code": None, "output_tail": "",
        }

    if not os.path.isfile(artifact_path):
        return {
            "triggered": False, "verdict": "ERROR",
            "reason_skipped": f"artifact tidak ada: {artifact_path}",
            "final_status": None, "false_ready_count": None,
            "exit_code": None, "output_tail": "",
        }

    try:
        proc = subprocess.run(
            ["bash", gate_sh, artifact_path, constraint],
            capture_output=True, text=True, timeout=timeout_seconds,
        )
        exit_code = proc.returncode
        combined = (proc.stdout + "\n" + proc.stderr)[-500:]
    except subprocess.TimeoutExpired:
        return {"triggered": True, "verdict": "ERROR", "exit_code": None,
                "final_status": None, "false_ready_count": None,
                "output_tail": "timeout", "reason_skipped": f"timeout ({timeout_seconds}s)"}
    except Exception as e:
        return {"triggered": True, "verdict": "ERROR", "exit_code": None,
                "final_status": None, "false_ready_count": None,
                "output_tail": str(e)[:200], "reason_skipped": str(e)}

    final_status = None
    false_ready_count = None
    for line in combined.split("\n"):
        if "final_status" in line and ":" in line:
            parts = line.split(":", 1)
            if len(parts) == 2:
                final_status = parts[1].strip()
        if "false_READY_count" in line and ":" in line:
            parts = line.split(":", 1)
            if len(parts) == 2:
                try:
                    false_ready_count = int(parts[1].strip())
                except ValueError:
                    pass

    verdict = "SKIPPED"
    if exit_code is not None:
        if exit_code == 0:
            verdict = "PASS"
        elif exit_code == 1:
            verdict = "NEEDS_WORK"
        else:
            verdict = "ERROR"

    return {
        "triggered": True, "verdict": verdict,
        "final_status": final_status, "false_ready_count": false_ready_count,
        "exit_code": exit_code, "output_tail": combined[-200:],
        "reason_skipped": None,
    }


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 pipa4_hook.py <artifact.pdf|docx> [constraint_name]")
        sys.exit(2)
    artifact = sys.argv[1]
    constraint = sys.argv[2] if len(sys.argv) > 2 else None
    result = run(artifact, constraint)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    sys.exit(0 if result.get("verdict") == "PASS" else 1)
