"""
GUARDIAN — PIPA4 Brand Gate. Palang pintu deterministik terakhir. ZERO LLM.

Versi config-driven: semua rule dibaca dari brand_rules.json (toggle tanpa sentuh kode).

SAKLAR KONTEKS (Secondary Mind):
  - target internal_research / code_patching -> HANYA assert teknis (measurable).
    Brand filter (Sacred IP / Signature / Hype / Voice / Emoji) DI-BYPASS.
    -> Jarvis bisa diajak ngobrol liar soal Sacred IP di mode internal.
  - target public_social / book_draft -> seluruh monster filter AKTIF.

Output: Verdict -> state.record_verdict() -> auto-banting status.
Stdlib only.
"""
from __future__ import annotations

import json
import os
import re
import sys
from dataclasses import dataclass

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "state"))
from task_state import TaskState, Verdict  # noqa: E402

RULES_PATH = os.path.join(os.path.dirname(__file__), "brand_rules.json")
PUBLIC_ARTIFACTS = {"thread", "post", "article", "caption", "reply", "carousel"}


@dataclass
class Failure:
    code: str
    severity: str       # CRITICAL | HIGH | MED
    detail: str
    def __str__(self) -> str:
        return f"[{self.severity}] {self.code}: {self.detail}"


class Guardian:
    def __init__(self, rules_path: str = RULES_PATH):
        with open(rules_path, encoding="utf-8") as f:
            self.r = json.load(f)
        # precompile sacred ip
        self._sacred = []
        if self.r["sacred_ip"]["enabled"]:
            for rule in self.r["sacred_ip"]["rules"]:
                if rule.get("enabled", True):
                    self._sacred.append((rule["code"],
                                         re.compile(rule["pattern"], re.I),
                                         rule["severity"]))
        ah = self.r["anti_hype"]
        self._hype_always = re.compile(r"\b(" + "|".join(ah["always"]) + r")\b", re.I) \
            if ah["enabled"] and ah["always"] else None
        self._pron = re.compile(r"\b(" + "|".join(self.r["voice"]["informal_pronouns"]) + r")\b", re.I)
        self._emoji = re.compile(
            "[" "\U0001F300-\U0001FAFF" "\U00002600-\U000026FF" "\U00002700-\U000027BF"
            "\U0001F1E6-\U0001F1FF" "\U00002B00-\U00002BFF" "\U0001F900-\U0001F9FF" "]",
            flags=re.UNICODE)

    # ---------- brand checks ----------
    def _sacred_ip(self, text: str) -> list[Failure]:
        out = []
        for code, rx, sev in self._sacred:
            for m in rx.finditer(text):
                out.append(Failure(code, sev, f"'{m.group(0)}' @pos {m.start()}"))
        return out

    def _signature(self, text: str) -> list[Failure]:
        sig = self.r["signature"]
        if not sig["enabled"]:
            return []
        hits = sum(1 for p in sig["phrases"] if p.lower() in text.lower())
        if hits >= sig["min_required"]:
            return []
        return [Failure("NO_SIGNATURE", "HIGH",
                        f"signature {hits}/{sig['min_required']} (wajib >= {sig['min_required']})")]

    def _anti_hype(self, text: str) -> list[Failure]:
        ah = self.r["anti_hype"]
        if not ah["enabled"]:
            return []
        out = []
        # 1) always-block words (any case)
        if self._hype_always:
            for m in self._hype_always.finditer(text):
                out.append(Failure("HYPE_WORD", "HIGH", f"'{m.group(0)}'"))
        # 2) context words (whitelist + caps + hype-action)
        actions = set(ah.get("hype_action_words", []))
        for word, cfg in ah.get("context", {}).items():
            whitelist = [w.lower() for w in cfg.get("whitelist", [])]
            rx = re.compile(r"\b" + re.escape(word) + r"\b(\s+\w+)?", re.I)
            for m in rx.finditer(text):
                matched = text[m.start():m.start() + len(word)]
                next_word = (m.group(1) or "").strip().lower()
                phrase = (word.lower() + " " + next_word).strip()
                if matched.isupper():                                   # CAPS = hype
                    out.append(Failure("HYPE_CAPS", "HIGH", f"'{matched} {next_word}'".strip()))
                elif any(phrase == wl or wl.startswith(phrase) for wl in whitelist):
                    continue                                            # whitelist -> lolos
                elif next_word in actions:                              # "wajib beli" -> hype
                    out.append(Failure("HYPE_CONTEXT", "MED", f"'{word} {next_word}'"))
                # else: pemakaian normal -> lolos
        return out

    def _voice(self, text: str, state: TaskState) -> list[Failure]:
        if not self.r["voice"]["enabled"]:
            return []
        vc = next((c for c in state.neuro.ukuran if c.kind == "voice"), None)
        if vc is None:                                                  # tak ada tuntutan -> jangan blok
            return []
        if str(vc.value).lower() == "formal":
            found = {w.lower() for w in self._pron.findall(text)}
            if found:
                return [Failure("VOICE_MISMATCH", "MED", f"voice FORMAL tapi ada {found}")]
        return []                                                       # casual -> lolos lo/gue

    def _emoji_check(self, text: str) -> list[Failure]:
        em = self.r["emoji"]
        if not em["enabled"]:
            return []
        out = []
        alay = {e for e in em["alay"] if e in text}
        if alay:
            out.append(Failure("EMOJI_ALAY", "HIGH", f"emoji alay: {alay}"))
        for i, para in enumerate(re.split(r"\n\s*\n", text)):
            n = len(self._emoji.findall(para))
            if n > em["max_per_paragraph"]:
                out.append(Failure("EMOJI_SPAM", "MED",
                                   f"paragraf {i+1}: {n} emoji (maks {em['max_per_paragraph']})"))
        return out

    # ---------- measurable (SELALU jalan, kedua mode) ----------
    @staticmethod
    def _cmp(got, op, val) -> bool:
        try:
            return {"==": got == val, ">=": got >= val, "<=": got <= val,
                    ">": got > val, "<": got < val}.get(op, False)
        except TypeError:
            return False

    def _measurable(self, text: str, state: TaskState, facts: dict) -> list[Failure]:
        out = []
        for c in state.neuro.ukuran:
            ok, detail = None, ""
            if c.kind == "slide_count":
                got = facts.get("slide_count")
                ok = self._cmp(got, c.op, c.value) if got is not None else None
                detail = f"slide_count={got} {c.op} {c.value}"
            elif c.kind == "word_count":
                got = len(text.split()); ok = self._cmp(got, c.op, c.value)
                detail = f"word_count={got} {c.op} {c.value}"
            elif c.kind == "must_include":
                ok = str(c.value).lower() in text.lower(); detail = f"memuat '{c.value}'"
            elif c.kind == "image_exists":
                p = facts.get("image_path")
                ok = bool(p) and os.path.exists(p) and os.path.getsize(p) > 0
                detail = f"image={p}"
            else:
                continue
            c.satisfied = ok
            if ok is False:
                out.append(Failure(c.id, "HIGH", f"{c.desc} | {detail}"))
            elif ok is None:
                out.append(Failure(c.id, "MED", f"{c.desc} | tak terverifikasi ({detail})"))
        return out

    # ---------- THE GATE ----------
    def run(self, content: str, state: TaskState, artifact_facts: dict | None = None) -> Verdict:
        facts = artifact_facts or {}
        brand_on = state.output_target in self.r["brand_enforced_targets"]

        fails: list[Failure] = []
        fails += self._measurable(content, state, facts)   # SELALU
        if brand_on:                                        # SAKLAR KONTEKS
            fails += self._sacred_ip(content)
            is_public = (state.neuro.output.artifact in PUBLIC_ARTIFACTS
                         or state.output_target == "public_social")
            if is_public:
                fails += self._signature(content)
            fails += self._anti_hype(content)
            fails += self._voice(content, state)
            fails += self._emoji_check(content)

        if not fails:
            return state.record_verdict("PUBLISH_OK", [])
        codes = [str(f) for f in fails]
        if any(f.severity == "CRITICAL" for f in fails):
            codes.insert(0, "[!] SACRED_IP LEAK — DITAHAN, tidak boleh publish")
        return state.record_verdict("NEEDS_TEXT_CLEANUP", codes)


# module-level convenience
_default = None
def run_guardian(content: str, state: TaskState, artifact_facts: dict | None = None) -> Verdict:
    global _default
    if _default is None:
        _default = Guardian()
    return _default.run(content, state, artifact_facts)


# ============================ DEMO: saklar konteks + whitelist ============================
if __name__ == "__main__":
    from task_state import OutputSpec, Constraint, Status
    def banner(t): print("\n" + "=" * 64 + f"\n{t}\n" + "=" * 64)

    leak = ("Gue dulu habis 847.000 buat 347 prompt. Framework gue Neuro-Arc. "
            "Ini wajib pajak tahunan, tapi WAJIB KLIK link ini sekarang!")

    banner("MODE INTERNAL (internal_research) — brand BYPASS, leak DIBOLEHKAN")
    si = TaskState(narasi="brainstorm internal soal angka buku")
    si.neuro.output = OutputSpec("reply", "md", target="internal_research")
    vi = run_guardian(leak, si)
    print(f"target={si.output_target} status={si.status.value} verdict={vi.result}")
    print("  failures:", vi.failures or "TIDAK ADA (bypass)")

    banner("MODE PUBLIK (public_social) — konten SAMA, monster filter NYALA")
    sp = TaskState(narasi="post publik")
    sp.neuro.output = OutputSpec("thread", "md", "threads", target="public_social")
    sp.neuro.ukuran = [Constraint("V", "santai", "voice", value="casual")]
    vp = run_guardian(leak, sp)
    print(f"target={sp.output_target} status={sp.status.value} verdict={vp.result}")
    for f in vp.failures: print("  -", f)

    banner("WHITELIST 'WAJIB' — 'wajib pajak' lolos, 'WAJIB KLIK' kena")
    sw = TaskState(narasi="cek whitelist")
    sw.neuro.output = OutputSpec("post", "md", "linkedin", target="public_social")
    sw.neuro.ukuran = [Constraint("V", "formal", "voice", value="formal")]
    txt = ("Sistem bukan tools. Pelaporan wajib pajak itu rutin. "
           "Tapi jangan tulis WAJIB BELI di caption Anda.")
    vw = run_guardian(txt, sw)
    print(f"status={sw.status.value} verdict={vw.result}")
    for f in vw.failures: print("  -", f)
