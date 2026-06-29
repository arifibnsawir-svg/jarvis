#!/usr/bin/env python3
"""
ACTION-GATE v1 -- gerbang KEPUTUSAN deterministik buat otonomi Jarvis (kayak PIPA4, tapi buat AKSI).
Vonis: AUTO_OK | AUTO_OK_W_BACKUP | NEEDS_APPROVAL | REFUSE

Pemakaian:
  CLI    : python3 action_gate.py "git push origin main"
  Library: from action_gate import classify_command, assert_allowed
Aturan tunable di action_gate_rules.json (sebelah file ini). LLM TIDAK bisa override REFUSE (assert_allowed).
"""
import os, sys, json, re

HERE = os.path.dirname(os.path.abspath(__file__))
HOME = os.path.expanduser("~")

DEFAULTS = {
    "safe_zone": ["~/.hermes/workspaces/", "~/.hermes/outbox/", "~/.hermes/cache/", "/tmp/"],
    "protected_paths": ["~/.hermes/config.yaml", "~/.hermes/scripts/guardian_router.py",
                         "~/.hermes/hermes-agent/", "~/.hermes/memories/", "~/.config/systemd/user/",
                         "~/.hermes/pipelines/pipa4/", "~/.9router/", "~/.hermes/guardian/",
                         "~/.hermes/state/ARIF_STACK_EVENT_LOG.md", "~/.hermes/action_gate/"],
    "protected_services": ["hermes-gateway", "hermes-9router", "hermes-9router-direct",
                           "hermes-guardian", "hermes-autorouter"],
    "safety_mechanisms": ["action_gate", "guardian_router", "pipa4", "LESSONS.md", ".bak"],
    "secrets_patterns": ["\\.env", "api[_-]?key", "\\btoken\\b", "sk-", "bearer", "NINEROUTER_KEY", "ROUTER_KEY"],
    "destructive": ["rm -rf", "rm -fr", "rm -r ", "rm -f ", "\\bdd ", "mkfs", "> /dev/", "chmod -R", "truncate ", ":(){"],
}

def load_rules():
    try:
        with open(os.path.join(HERE, "action_gate_rules.json")) as f:
            return {**DEFAULTS, **json.load(f)}
    except Exception:
        return DEFAULTS

R = load_rules()

def _exp(p):
    return os.path.join(HOME, p[2:]) if p.startswith("~/") else p

def _norm(p):
    return os.path.normpath(_exp(p.strip().strip('"').strip("'")))

def in_safe_zone(path):
    np = _norm(path)
    for z in R["safe_zone"]:
        zp = os.path.normpath(_exp(z))
        if np == zp or np.startswith(zp.rstrip("/") + "/"):
            return True
    return False

def is_protected(path):
    np = _norm(path)
    for pp in R["protected_paths"]:
        ppn = os.path.normpath(_exp(pp))
        if np == ppn or np.startswith(ppn.rstrip("/") + "/"):
            return True
    return False

def extract_paths(cmd):
    return re.findall(r'(?:~/|/|\./)[^\s"\';|&>]+', cmd)

def V(verdict, reason, requires=None):
    return {"verdict": verdict, "reason": reason, "requires": requires or []}

def classify_command(cmd, context="default"):
    c = cmd.strip()
    low = c.lower()
    paths = extract_paths(c)
    words = low.split()
    first = words[0] if words else ""

    # 0. Tamper mekanisme keamanan -> REFUSE
    if re.search(r'\b(rm|mv|truncate)\b', low) and any(sm.lower() in low for sm in R["safety_mechanisms"]):
        return V("REFUSE", "Mau hapus/rusak mekanisme keamanan (action_gate/guardian/pipa4/backup).")

    # 1. Exfil secret ke eksternal -> REFUSE
    if re.search(r'\b(curl|wget|nc|http)\b', low) and not re.search(r'(localhost|127\.0\.0\.1|::1)', low):
        if any(re.search(p, c, re.I) for p in R["secrets_patterns"]):
            return V("REFUSE", "Indikasi transmit secret/.env/API key ke eksternal.")

    # 2. Destruktif
    for d in R["destructive"]:
        if re.search(d, c):
            tgt = paths[0] if paths else ""
            if tgt and is_protected(tgt):
                return V("REFUSE", f"Destruktif di PROTECTED_PATH ({tgt}).")
            if tgt and in_safe_zone(tgt):
                return V("AUTO_OK_W_BACKUP", f"Destruktif di SAFE_ZONE ({tgt}) -> pindah ke trash, jgn rm keras.", ["trash_not_rm"])
            return V("REFUSE", f"Destruktif irreversible di luar safe-zone ({tgt or '?'}).")

    # 3. git push
    if re.search(r'\bgit\b.*\bpush\b', low):
        force = bool(re.search(r'(--force\b|--force-with-lease\b|(^|\s)-f\b)', low))
        to_main = bool(re.search(r'\b(main|master)\b', low))
        if force and to_main:
            return V("NEEDS_APPROVAL", "Force-push ke main/master (bisa hapus history).")
        return V("AUTO_OK", "git push (non-force).")

    # 4. systemctl service
    m = re.search(r'systemctl(?:\s+--user)?\s+(restart|stop|start|disable|enable|kill)\s+(\S+)', low)
    if m:
        op, svc = m.group(1), m.group(2).replace(".service", "")
        prot = any(ps.lower() in svc for ps in R["protected_services"])
        if op in ("stop", "disable", "kill") and prot:
            return V("NEEDS_APPROVAL", f"{op} service protected ({svc}).")
        if op in ("restart", "start") and prot:
            return V("AUTO_OK_W_BACKUP", f"{op} service protected ({svc}).",
                     ["backup_config", "health_check_after", "auto_rollback_if_unhealthy"])
        return V("AUTO_OK", f"systemctl {op} {svc} (non-protected).")
    if re.search(r'\bkill\s+-9\b', low):
        return V("NEEDS_APPROVAL", "kill -9 (verifikasi target dulu).")

    # 5. paket / update
    if re.search(r'\b(pip3?|pipx)\s+install\b|\bnpm\s+(i|install)\b|\b(apt|apt-get|dnf|yum|pacman)\s+(install|update|upgrade|remove)\b|9router@latest', low):
        return V("NEEDS_APPROVAL", "Install/update paket atau sistem (bisa ubah environment).")

    # 6. publikasi / kirim ke pihak ketiga
    if re.search(r'(post|publish|tweet|/sendmessage|sendmail|mail -s|smtp)', low) and not re.search(r'(localhost|127\.0\.0\.1)', low):
        return V("NEEDS_APPROVAL", "Aksi publikasi/kirim ke pihak ketiga (irreversible-ish).")

    # 7. read-only / inspect
    READ = ["ls", "cat", "grep", "find", "stat", "head", "tail", "wc", "sha256sum", "md5sum",
            "pwd", "whoami", "ps", "ss", "netstat", "df", "du", "date", "uname", "which",
            "git status", "git log", "git diff", "git show", "git branch", "journalctl"]
    if any(low.startswith(rc) for rc in READ) or low.startswith("systemctl") and re.search(r'\b(status|is-active|is-enabled|list)\b', low):
        return V("AUTO_OK", "Read-only / inspect.")
    if first == "curl":
        if re.search(r'(-x\s*post|--data\b|-d\b)', low) and not re.search(r'(localhost|127\.0\.0\.1)', low):
            return V("NEEDS_APPROVAL", "curl POST ke eksternal.")
        return V("AUTO_OK", "curl read/localhost.")

    # 8. tulis / modifikasi file
    if first in ("cp", "mv", "touch", "mkdir", "tee", "sed", "nano", "vim", "vi") or re.search(r'(>>?|sed -i|\btee\b|chmod |chown )', low):
        if any(is_protected(p) for p in paths):
            return V("NEEDS_APPROVAL", "Modifikasi PROTECTED_PATH.")
        if paths and all(in_safe_zone(p) for p in paths):
            return V("AUTO_OK", "Tulis/modifikasi di SAFE_ZONE.")
        if paths:
            return V("AUTO_OK_W_BACKUP", "Modifikasi file non-protected di luar safe-zone.", ["backup"])
        return V("AUTO_OK_W_BACKUP", "Tulis/modifikasi (target tak jelas) -> backup dulu.", ["backup"])

    # 9. default konservatif
    return V("NEEDS_APPROVAL", "Aksi tak dikenali -> default konservatif (escalate ke Arif).")

def assert_allowed(cmd, context="default"):
    r = classify_command(cmd, context)
    if r["verdict"] == "REFUSE":
        raise PermissionError(f"ACTION-GATE REFUSE: {r['reason']} :: {cmd}")
    return r

if __name__ == "__main__":
    cmd = " ".join(sys.argv[1:]) if len(sys.argv) > 1 else sys.stdin.read().strip()
    print(json.dumps(classify_command(cmd), ensure_ascii=False, indent=2))
