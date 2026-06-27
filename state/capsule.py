"""
Context Capsule — injeksi TaskState ke LLM TANPA prompt bloat.

Aturan emas: JANGAN pernah nyuntik seluruh TaskState. Render capsule yang:
  (1) ROLE-SCOPED  - tiap branch cuma lihat field yang dia butuh
  (2) DETERMINISTIK - preamble dirakit dari ledger (fakta), bukan diringkas LLM
  (3) BY-REFERENCE  - artefak besar disebut id+ringkasan, konten ditarik HANYA bila perlu
  (4) DELTA-ON-LOOP - iterasi ke-N cuma bawa yang BERUBAH + verdict pemicu
  (5) STABLE-PREFIX - bagian imutable (identitas/voice) di depan -> kena prompt cache provider
  (6) BUDGETED      - hard cap token per capsule, truncate terukur

Output: list pesan format OpenAI (system stabil + system dinamis + user).
"""
from __future__ import annotations

from task_state import TaskState, ArsiStage

# ~4 char per token (heuristik; ganti tiktoken kalau mau presisi)
CHARS_PER_TOKEN = 4


def _toks(s: str) -> int:
    return len(s) // CHARS_PER_TOKEN


def _clip(s: str, max_tokens: int) -> str:
    cap = max_tokens * CHARS_PER_TOKEN
    if len(s) <= cap:
        return s
    return s[: cap - 20].rstrip() + " …[clipped]"


# ============================ ROLE SCOPE ============================
# Per branch: field NEURO-ARC apa yang relevan + apakah butuh artefak/verdict.
ROLE_SCOPE = {
    # Audit/extract: cuma butuh narasi + input mentah. TIDAK perlu draf lama.
    "R3_extract":  {"fields": ["narasi"],                                  "artifacts": [],            "verdict": False},
    # Writer: butuh kerangka penuh + spec output. Tarik schema terbaru. Tidak perlu ledger penuh.
    "R4_writer":   {"fields": ["narasi", "entitas", "ukuran", "output"],   "artifacts": ["schema"],    "verdict": "last"},
    # Audit/NLI: fokus ke constraint + artefak yang ditinjau + verdict terakhir.
    "R6_audit":    {"fields": ["ukuran"],                                  "artifacts": ["under_review"], "verdict": "last"},
    # Digest: narasi + output spec + dokumen target.
    "R7_digest":   {"fields": ["narasi", "output"],                        "artifacts": ["target"],    "verdict": False},
    # Triage & memory: minimal.
    "R1_triage":   {"fields": ["narasi"],                                  "artifacts": [],            "verdict": False},
    "R9_memory":   {"fields": ["narasi", "entitas"],                       "artifacts": [],            "verdict": False},
}

# Coder pakai scope mirip writer (butuh ukuran + output), default fallback di bawah.
ROLE_SCOPE["R2_coding"] = {"fields": ["narasi", "ukuran", "output"], "artifacts": ["under_review"], "verdict": "last"}


# ============================ STABLE PREFIX (cacheable) ============================
# Bagian IMUTABLE per platform: identitas + voice. Diletakkan PALING DEPAN supaya
# provider prompt-caching aktif (Claude/Gemini/dll cache prefix yang sama).
def stable_prefix(platform: str = "") -> str:
    base = (
        "Kamu komponen dari Jarvis (arsi engine). Patuhi NEURO-ARC: "
        "representasi sebelum eksekusi. Jangan klaim selesai — itu wewenang GUARDIAN. "
        "Kalau kamu pikir tugas tuntas, set proposed_status=AWAITING_GATE saja."
    )
    voice = {
        "threads": " Voice: 'Anda', tenang, tanpa emoji, tanpa kata hype (BURUAN/WAJIB/RAHASIA).",
        "linkedin": " Voice: 'Anda', profesional, struktural.",
        "marketplace": " Voice: ringkas, faktual, fokus manfaat produk.",
    }.get(platform, "")
    return base + voice


# ============================ DETERMINISTIC STATE PREAMBLE ============================
# Dirakit dari ledger & artifacts — fakta, bukan ringkasan LLM. Inilah obat presentism bias.
def state_preamble(state: TaskState, scope: dict) -> str:
    lines = [
        f"[STATE] task={state.task_id} | stage={state.arsi_stage.value} | iter={state.iteration}",
    ]
    done = state.done_summary()
    if done:
        lines.append("Sudah terjadi:")
        lines += [f"  ✓ {d}" for d in done]
    oc = state.open_constraints()
    if oc:
        lines.append("Constraint BELUM terpenuhi:")
        lines += [f"  ✗ [{c.id}] {c.desc}" for c in oc]
    if scope.get("verdict") == "last":
        v = state.last_verdict()
        if v:
            lines.append(f"Verdict terakhir (GUARDIAN): {v.result} — gagal: {', '.join(v.failures) or '-'}")
    return "\n".join(lines)


# ============================ NEURO-ARC SCOPED VIEW ============================
def neuro_scope(state: TaskState, fields: list[str]) -> str:
    n = state.neuro
    out = []
    if "narasi" in fields and n.narasi:
        out.append(f"narasi: {n.narasi}")
    if "entitas" in fields and n.entitas:
        out.append("entitas: " + ", ".join(f"{e.name}({e.role})" for e in n.entitas))
    if "ukuran" in fields and n.ukuran:
        out.append("ukuran (constraint):")
        out += [f"  - [{c.id}] {c.desc}" + (f" [{c.op} {c.value}]" if c.op else "") for c in n.ukuran]
    if "relasi" in fields and n.relasi:
        out.append("relasi: " + "; ".join(f"{r.src} {r.rel} {r.dst}" for r in n.relasi))
    if "output" in fields:
        o = n.output
        out.append(f"output: {o.artifact} ({o.format}) -> {o.platform or 'n/a'}"
                   + (f" | {o.notes}" if o.notes else ""))
    return "\n".join(out)


# ============================ ARTIFACT REFERENCES ============================
def artifact_refs(state: TaskState, wanted_kinds: list[str], fetch_content) -> tuple[str, dict]:
    """
    Sebut artefak relevan by-reference. Konten penuh ditarik HANYA untuk yang 'under_review'/'target'.
    fetch_content(location) -> str : callback ke memory store (boleh None kalau gak perlu konten).
    """
    if not wanted_kinds:
        return "", {}
    lines, inline = [], {}
    for ref in state.artifacts.values():
        match = ("under_review" in wanted_kinds or "target" in wanted_kinds or ref.kind in wanted_kinds)
        if not match:
            continue
        lines.append(f"  - {ref.id} [{ref.kind}, {ref.size}b, sha {ref.sha256}]: {ref.summary}")
        # Tarik konten penuh HANYA bila branch perlu mengolahnya (review/digest)
        if ("under_review" in wanted_kinds or "target" in wanted_kinds) and fetch_content:
            inline[ref.id] = fetch_content(ref.location)
    head = "Artefak terkait:\n" + "\n".join(lines) if lines else ""
    return head, inline


# ============================ MAIN: render capsule ============================
def render_capsule(
    state: TaskState,
    branch: str,
    task_instruction: str,
    *,
    fetch_content=None,
    token_budget: int = 1200,
    conversation: list[dict] | None = None,
) -> list[dict]:
    """
    Hasilkan messages siap-kirim ke 9router. token_budget = batas untuk system dinamis
    (preamble + neuro-scope + artefak). Stable prefix & instruksi tidak dipotong.
    """
    scope = ROLE_SCOPE.get(branch, ROLE_SCOPE["R4_writer"])
    platform = state.neuro.output.platform

    # 1) STABLE PREFIX (cacheable) — pesan system pertama, terpisah.
    msgs = [{"role": "system", "content": stable_prefix(platform)}]

    # 2) SYSTEM DINAMIS — preamble + neuro-scope + artefak (dibudget)
    preamble = state_preamble(state, scope)
    nscope = neuro_scope(state, scope["fields"])
    art_head, inline = artifact_refs(state, scope["artifacts"], fetch_content)

    # Alokasi budget: preamble & constraint diutamakan (paling penting utk anti-amnesia),
    # konten artefak inline dapat sisa.
    fixed = "\n\n".join(p for p in [preamble, nscope, art_head] if p)
    dyn_parts = [fixed]

    inline_budget = max(0, token_budget - _toks(fixed))
    for aid, content in inline.items():
        share = inline_budget // max(1, len(inline))
        dyn_parts.append(f"\n[ISI {aid}]\n{_clip(content, share)}")

    dynamic = _clip("\n".join(dyn_parts), token_budget + 600)  # hard ceiling
    msgs.append({"role": "system", "content": dynamic})

    # 3) Riwayat percakapan (kalau ada) — opsional, biasanya kosong utk pipeline
    if conversation:
        msgs += conversation

    # 4) INSTRUKSI TUGAS (tidak dipotong) — apa yang call INI harus hasilkan
    msgs.append({"role": "user", "content": task_instruction})
    return msgs


# ============================ DEMO ============================
if __name__ == "__main__":
    from task_state import NeuroArc, Entity, Constraint, OutputSpec, ArsiStage

    st = TaskState(narasi="Bikin thread Threads 9-post soal NEURO-ARC, voice tenang.")
    st.neuro.entitas = [Entity("Arif", "subjek"), Entity("operator AI pemula", "audiens")]
    st.neuro.output = OutputSpec("thread", "md", "threads", "9 post")
    st.neuro.ukuran = [
        Constraint("C1", "tepat 9 post", "slide_count", "==", 9),
        Constraint("C2", "minimal 1 frase signature", "signature", ">=", 1),
        Constraint("C3", "tanpa sacred IP (847.000 dll)", "sacred_ip", "not_contains", None),
    ]
    st.add_artifact("schema", '{"posts":[...]}', "skema 9 post hasil Audit", "R3_extract")
    st.advance_stage(ArsiStage.RANCANG, "system")

    for br in ["R3_extract", "R4_writer", "R6_audit"]:
        caps = render_capsule(st, br, f"[instruksi {br}]",
                              fetch_content=lambda loc: "(isi draf panjang...)")
        total = sum(_toks(m["content"]) for m in caps)
        print(f"\n===== {br} : ~{total} tokens, {len(caps)} pesan =====")
        for m in caps:
            print(f"--- {m['role']} ---")
            print(m["content"][:400])
