"""
Jarvis Router — cascade 3-layer (L0 rule -> L1 embedding -> L2 LLM fallback).

Output: RouteDecision{branch, combo, confidence, layer}.
Jalan di Acer (CPU). Embedding lokal via fastembed (multilingual).

Dependencies (install di Acer):
    pip install fastembed numpy openai

Catatan: ini SKELETON. Bagian yang perlu di-flesh-out / test di Acer ditandai TODO.
"""
from __future__ import annotations

import os
import re
import json
from dataclasses import dataclass, asdict

from exemplars import EXEMPLARS

# ----- Konfigurasi -----
ROUTER_URL = os.environ.get("ROUTER_URL", "http://arif-aspire-5551:20128/v1")
ROUTER_KEY = os.environ.get("ROUTER_KEY", "")

# Multilingual — JANGAN pakai BGE-en (English-only, misroute konten ID).
# Verifikasi nama persis di: TextEmbedding.list_supported_models()
EMBED_MODEL = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"

CONF_THRESHOLD = 0.75   # skor cosine absolut minimum
MARGIN_MIN = 0.10       # jarak top1 - top2 minimum

BRANCH_TO_COMBO = {
    "R1_triage":  "jarvis-fast",
    "R2_coding":  "jarvis-coder",
    "R3_extract": "jarvis-reason",
    "R4_writer":  "jarvis-longform",
    "R5_gate":    None,            # deterministic, no LLM
    "R6_audit":   "jarvis-reason",
    "R7_digest":  "jarvis-longform",
    "R8_vision":  None,            # DEFERRED
    "R9_memory":  "jarvis-fast",
}


@dataclass
class RouteDecision:
    branch: str
    combo: str | None
    confidence: float
    layer: int          # 0=rule, 1=embed, 2=llm
    note: str = ""

    def to_json(self) -> str:
        return json.dumps(asdict(self), ensure_ascii=False)


# ===================== LAYER 0: rule / regex / attachment =====================
def layer0_rules(text: str, attachments: list[str] | None = None) -> RouteDecision | None:
    """Sinyal deterministik. Return None kalau gak ada match kuat."""
    attachments = attachments or []

    # Attachment MIME
    for a in attachments:
        al = a.lower()
        if al.endswith((".png", ".jpg", ".jpeg", ".webp", ".gif")):
            return RouteDecision("R8_vision", BRANCH_TO_COMBO["R8_vision"], 1.0, 0, "image attachment")
        if al.endswith((".pdf", ".docx", ".txt", ".md")):
            return RouteDecision("R7_digest", BRANCH_TO_COMBO["R7_digest"], 1.0, 0, "doc attachment")

    t = text.strip().lower()

    # Slash commands eksplisit
    cmd_map = {
        "/audit": "R5_gate", "/qa": "R5_gate", "/render": "R5_gate",
        "/code": "R2_coding", "/fix": "R2_coding",
        "/extract": "R3_extract", "/json": "R3_extract",
        "/write": "R4_writer", "/draft": "R4_writer",
        "/digest": "R7_digest", "/summary": "R7_digest",
        "/recall": "R9_memory", "/history": "R9_memory",
    }
    for cmd, branch in cmd_map.items():
        if t.startswith(cmd):
            return RouteDecision(branch, BRANCH_TO_COMBO[branch], 1.0, 0, f"command {cmd}")

    # Sinyal sintaktik kuat
    if "```" in text or re.search(r"\b(traceback|stacktrace|exception|errno|segfault)\b", t):
        return RouteDecision("R2_coding", BRANCH_TO_COMBO["R2_coding"], 0.95, 0, "code/stacktrace marker")
    # Blob JSON mentah yang minta diproses
    if re.search(r"^\s*[\{\[]", text) and len(text) > 40:
        return RouteDecision("R3_extract", BRANCH_TO_COMBO["R3_extract"], 0.9, 0, "raw json/array")

    return None


# ===================== LAYER 1: embedding semantic router =====================
class EmbeddingRouter:
    def __init__(self) -> None:
        from fastembed import TextEmbedding  # lazy import
        import numpy as np
        self._np = np
        self.model = TextEmbedding(model_name=EMBED_MODEL)
        # Precompute exemplar vectors (sekali di startup), simpan per-branch centroid + raw.
        self.branch_vecs: dict[str, "np.ndarray"] = {}
        for branch, examples in EXEMPLARS.items():
            vecs = list(self.model.embed(examples))
            mat = np.array(vecs, dtype=np.float32)
            mat = mat / (np.linalg.norm(mat, axis=1, keepdims=True) + 1e-8)
            self.branch_vecs[branch] = mat
        # TODO(Acer): persist vektor ke sqlite-vec (route_exemplars) biar gak recompute tiap boot.

    def route(self, text: str) -> RouteDecision:
        np = self._np
        q = next(iter(self.model.embed([text])))
        q = np.array(q, dtype=np.float32)
        q = q / (np.linalg.norm(q) + 1e-8)

        scores: list[tuple[str, float]] = []
        for branch, mat in self.branch_vecs.items():
            sim = float(np.max(mat @ q))   # nearest exemplar di branch
            scores.append((branch, sim))
        scores.sort(key=lambda x: x[1], reverse=True)

        (top_branch, top1) = scores[0]
        top2 = scores[1][1] if len(scores) > 1 else 0.0
        margin = top1 - top2

        if top1 >= CONF_THRESHOLD and margin >= MARGIN_MIN:
            return RouteDecision(top_branch, BRANCH_TO_COMBO[top_branch], top1, 1,
                                 f"margin={margin:.3f}")
        # Ambigu -> sinyal ke caller buat eskalasi ke Layer 2
        return RouteDecision(top_branch, None, top1, 1, f"AMBIGUOUS margin={margin:.3f}")


# ===================== LAYER 2: LLM classifier fallback =====================
_BRANCHES = list(BRANCH_TO_COMBO.keys())

def layer2_llm(text: str) -> RouteDecision:
    """Fallback saat embedding ambigu. Pakai combo tercepat (jarvis-fast)."""
    from openai import OpenAI
    client = OpenAI(base_url=ROUTER_URL, api_key=ROUTER_KEY)
    sys = (
        "Klasifikasikan pesan user ke SATU branch. Jawab HANYA dengan kode branch.\n"
        + "\n".join(f"- {b}" for b in _BRANCHES)
    )
    resp = client.chat.completions.create(
        model="jarvis-fast",   # nama COMBO -> 9router rotasi internal
        messages=[{"role": "system", "content": sys},
                  {"role": "user", "content": text}],
        max_tokens=12, temperature=0,
    )
    raw = (resp.choices[0].message.content or "").strip()
    branch = next((b for b in _BRANCHES if b in raw), "R1_triage")
    return RouteDecision(branch, BRANCH_TO_COMBO[branch], 0.6, 2, f"llm said: {raw[:30]}")


# ===================== ORCHESTRATOR =====================
class Router:
    def __init__(self) -> None:
        self.embed = EmbeddingRouter()

    def decide(self, text: str, attachments: list[str] | None = None) -> RouteDecision:
        # L0
        d = layer0_rules(text, attachments)
        if d is not None:
            return d
        # L1
        d = self.embed.route(text)
        if d.combo is not None:   # confident
            return d
        # L2
        return layer2_llm(text)


if __name__ == "__main__":
    import sys
    r = Router()
    msg = " ".join(sys.argv[1:]) or "tolong fix bug di script ini ```error```"
    print(r.decide(msg).to_json())
