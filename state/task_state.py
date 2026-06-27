"""
TaskState — Blackboard Pattern, terstruktur menurut NEURO-ARC.

Prinsip:
  1. Kebenaran hidup DI SINI, bukan di ingatan LLM. (anti Presentism Bias)
  2. Ledger APPEND-ONLY. Sejarah tak bisa ditimpa/dihalusinasi.
  3. AUTHORITY: hanya GUARDIAN yang boleh set status final (PUBLISH_OK/NEEDS_REVISION/DONE).
     LLM cuma boleh mengusulkan AWAITING_GATE. Ditegakkan di level kode (set_status).

NEURO-ARC = lapis representasi: narasi -> entitas -> ukuran -> relasi -> output.
A.R.S.I.  = lapis eksekusi (4 PIPA): Audit -> Rancang -> Sistemasi -> Iterasi.

Stdlib only. Persist opsional ke sqlite (lihat memory/schema.sql: event_ledger, artifact_meta).
"""
from __future__ import annotations

import hashlib
import json
import time
import uuid
from dataclasses import dataclass, field, asdict
from enum import Enum


# ============================ ENUMS & AUTHORITY ============================
class Status(str, Enum):
    INTAKE = "INTAKE"
    IN_PROGRESS = "IN_PROGRESS"
    AWAITING_GATE = "AWAITING_GATE"     # LLM mengusulkan "selesai" -> GUARDIAN yang vonis
    NEEDS_REVISION = "NEEDS_REVISION"   # GUARDIAN only
    PUBLISH_OK = "PUBLISH_OK"           # GUARDIAN only
    DONE = "DONE"                       # GUARDIAN only
    BLOCKED = "BLOCKED"


# Status yang HANYA boleh di-set oleh GUARDIAN. Inilah inti anti-"False READY".
GUARDIAN_ONLY = {Status.NEEDS_REVISION, Status.PUBLISH_OK, Status.DONE}


class ArsiStage(str, Enum):
    AUDIT = "AUDIT"          # PIPA1 — intake & schema
    RANCANG = "RANCANG"      # PIPA2 — draft
    SISTEMASI = "SISTEMASI"  # PIPA3 — NLI / validasi
    ITERASI = "ITERASI"      # PIPA4 — GUARDIAN gate + loop


# ============================ NEURO-ARC SCHEMA ============================
@dataclass
class Entity:
    name: str
    role: str = ""            # subjek | audiens | produk | platform | mentor ...


@dataclass
class Constraint:
    """'ukuran' HARUS terukur supaya GUARDIAN bisa cek deterministik."""
    id: str                   # C1, C2, ...
    desc: str
    kind: str                 # slide_count | word_count | must_include | banned |
                              # voice | sacred_ip | signature | image_exists ...
    op: str = ""              # >= | <= | == | contains | not_contains
    value: object = None
    satisfied: bool | None = None   # None=belum dicek; True/False HANYA di-set GUARDIAN


@dataclass
class Relation:
    src: str
    rel: str
    dst: str


@dataclass
class OutputSpec:
    artifact: str             # thread | pptx | docx | image | reply
    format: str = ""          # md | json | pptx | png
    platform: str = ""        # threads | ig | linkedin | marketplace | none
    notes: str = ""
    # SAKLAR KONTEKS (Secondary Mind):
    #   internal_research / code_patching -> GUARDIAN cek assert teknis SAJA (bypass brand)
    #   public_social / book_draft        -> seluruh monster filter brand AKTIF
    target: str = "public_social"


@dataclass
class NeuroArc:
    narasi: str = ""
    entitas: list[Entity] = field(default_factory=list)
    ukuran: list[Constraint] = field(default_factory=list)
    relasi: list[Relation] = field(default_factory=list)
    output: OutputSpec = field(default_factory=lambda: OutputSpec(artifact=""))


# ============================ ARTIFACT / EVENT / VERDICT ============================
@dataclass
class ArtifactRef:
    """Referensi, BUKAN konten. Konten penuh disimpan di memory store, ditarik on-demand."""
    id: str
    kind: str                 # schema | draft | verdict | image | pptx | docx
    summary: str              # 1 baris untuk capsule
    sha256: str
    size: int = 0
    location: str = ""        # key di memory / path file
    stage: str = ""           # ArsiStage saat dibuat


@dataclass
class Event:
    ts: float
    type: str                 # route | output | verdict | status_change | note
    actor: str                # branch/combo/model atau 'guardian'
    payload: dict


@dataclass
class Verdict:
    ts: float
    by: str                   # 'guardian'
    result: str               # PUBLISH_OK | NEEDS_REVISION
    failures: list[str]       # ['SACRED_IP_LEAK', 'C2:slide_count'] ...


# ============================ THE BLACKBOARD ============================
class TaskState:
    def __init__(self, narasi: str = "", task_id: str | None = None):
        self.task_id: str = task_id or f"task_{uuid.uuid4().hex[:10]}"
        self.status: Status = Status.INTAKE
        self.arsi_stage: ArsiStage = ArsiStage.AUDIT
        self.iteration: int = 0
        self.neuro: NeuroArc = NeuroArc(narasi=narasi)
        self.artifacts: dict[str, ArtifactRef] = {}
        self.ledger: list[Event] = []          # APPEND-ONLY
        self.verdicts: list[Verdict] = []
        self._append("status_change", "system", {"to": self.status})

    # ---- ledger: HANYA insert, tidak ada update/delete ----
    def _append(self, etype: str, actor: str, payload: dict) -> None:
        self.ledger.append(Event(time.time(), etype, actor, payload))

    # ---- AUTHORITY ENFORCEMENT ----
    def set_status(self, new: Status, actor: str) -> None:
        """LLM tidak boleh menyentuh status final. Hanya GUARDIAN."""
        if new in GUARDIAN_ONLY and actor != "guardian":
            raise PermissionError(
                f"{actor} mencoba set {new.value}. Hanya GUARDIAN yang berwenang. "
                f"LLM hanya boleh mengusulkan AWAITING_GATE."
            )
        self._append("status_change", actor, {"from": self.status, "to": new})
        self.status = new

    def advance_stage(self, stage: ArsiStage, actor: str) -> None:
        self._append("stage_change", actor, {"from": self.arsi_stage, "to": stage})
        self.arsi_stage = stage

    # ---- artefak ----
    @staticmethod
    def _sha(content: str) -> str:
        return hashlib.sha256(content.encode()).hexdigest()[:16]

    def add_artifact(self, kind: str, content: str, summary: str,
                     actor: str, location: str = "") -> ArtifactRef:
        aid = f"{kind}_{len(self.artifacts)+1:02d}"
        ref = ArtifactRef(aid, kind, summary, self._sha(content),
                          len(content), location, self.arsi_stage.value)
        self.artifacts[aid] = ref
        self._append("output", actor, {"artifact": aid, "kind": kind, "sha": ref.sha256})
        return ref

    # ---- verdict (GUARDIAN) ----
    def record_verdict(self, result: str, failures: list[str]) -> Verdict:
        v = Verdict(time.time(), "guardian", result, failures)
        self.verdicts.append(v)
        self._append("verdict", "guardian", {"result": result, "failures": failures})
        # GUARDIAN langsung set status sesuai vonis
        if result == "PUBLISH_OK":
            self.set_status(Status.PUBLISH_OK, "guardian")
        else:
            self.set_status(Status.NEEDS_REVISION, "guardian")
            self.iteration += 1
        return v

    # ---- saklar konteks ----
    @property
    def output_target(self) -> str:
        return self.neuro.output.target

    # ---- query helpers ----
    def open_constraints(self) -> list[Constraint]:
        return [c for c in self.neuro.ukuran if c.satisfied is not True]

    def last_verdict(self) -> Verdict | None:
        return self.verdicts[-1] if self.verdicts else None

    def done_summary(self) -> list[str]:
        """Ringkasan deterministik dari ledger — BUKAN diringkas LLM (hindari halusinasi berantai)."""
        out = []
        for a in self.artifacts.values():
            out.append(f"[{a.stage}] {a.kind} -> {a.id} ({a.summary})")
        return out

    def to_dict(self) -> dict:
        return {
            "task_id": self.task_id,
            "status": self.status.value,
            "arsi_stage": self.arsi_stage.value,
            "iteration": self.iteration,
            "neuro": {
                "narasi": self.neuro.narasi,
                "entitas": [asdict(e) for e in self.neuro.entitas],
                "ukuran": [asdict(c) for c in self.neuro.ukuran],
                "relasi": [asdict(r) for r in self.neuro.relasi],
                "output": asdict(self.neuro.output),
            },
            "artifacts": {k: asdict(v) for k, v in self.artifacts.items()},
            "verdicts": [asdict(v) for v in self.verdicts],
            "ledger_len": len(self.ledger),
        }

    def to_json(self) -> str:
        return json.dumps(self.to_dict(), ensure_ascii=False, indent=2)
