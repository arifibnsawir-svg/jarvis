#!/usr/bin/env python3
"""
MISTAKE-MEMORY (L1 auto-log + L2 recall) buat Jarvis.
Auto-log AMAN (cuma nyatet fakta). Promosi jadi ATURAN always-on = lewat review Arif (BUKAN di sini).
  log    : python3 lessons_logger.py log --attempted "..." --wrong "..." [--cause ".."] [--next ".."]
  recall : python3 lessons_logger.py recall "<keyword>"
"""
import os, sys, argparse, datetime

HOME = os.path.expanduser("~")
LESSONS = os.path.join(HOME, ".hermes/memories/LESSONS.md")

def _ensure():
    os.makedirs(os.path.dirname(LESSONS), exist_ok=True)
    if not os.path.exists(LESSONS):
        with open(LESSONS, "w") as f:
            f.write("# JARVIS LESSONS — kegagalan auto-log (biar gak diulang).\n"
                    "# L1 auto-log: aman/otomatis. L3 promosi jadi aturan always-on: WAJIB review Arif (bukan auto).\n")

def log_lesson(attempted, went_wrong, root_cause="", corrective=""):
    _ensure()
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    entry = (f"\n## [{ts}]\n"
             f"- ATTEMPTED: {attempted}\n"
             f"- WENT_WRONG: {went_wrong}\n"
             f"- ROOT_CAUSE: {root_cause or '(unknown)'}\n"
             f"- NEXT_TIME: {corrective or '(TBD)'}\n")
    with open(LESSONS, "a") as f:
        f.write(entry)
    return entry

def recall(keyword, n=5):
    if not os.path.exists(LESSONS):
        return []
    blocks = open(LESSONS).read().split("\n## ")
    hits = [("## " + b).strip() for b in blocks if keyword.lower() in b.lower() and b.strip().startswith("[")]
    return hits[-n:]

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd")
    lg = sub.add_parser("log")
    lg.add_argument("--attempted", required=True)
    lg.add_argument("--wrong", required=True)
    lg.add_argument("--cause", default="")
    lg.add_argument("--next", dest="nxt", default="")
    rc = sub.add_parser("recall")
    rc.add_argument("keyword")
    a = ap.parse_args()
    if a.cmd == "log":
        print(log_lesson(a.attempted, a.wrong, a.cause, a.nxt))
    elif a.cmd == "recall":
        out = recall(a.keyword)
        print("\n".join(out) if out else "(belum ada lesson relevan)")
    else:
        ap.print_help()
