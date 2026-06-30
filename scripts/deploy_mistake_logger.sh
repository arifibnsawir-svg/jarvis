#!/usr/bin/env bash
# Deploy plugin mistake_logger (item C: mistake-memory DETERMINISTIK via hook post_tool_call).
# Tiap tool-call GAGAL/error/blocked -> auto-log ke ~/.hermes/memories/LESSONS.md (reuse lessons_logger).
# Observer-only (gak ngeblok), fail-open, no LLM. Opt-in plugins.enabled + butuh restart utk discover.
# Idempotent + backup. RESTART = langkah terpisah (butuh GO Arif, ~210s).
set -uo pipefail
PLUG="$HOME/.hermes/plugins/mistake_logger"
AG="$HOME/.hermes/action_gate"
CFG="$HOME/.hermes/config.yaml"
PYBIN="$HOME/.hermes/hermes-agent/venv/bin/python"; [ -x "$PYBIN" ] || PYBIN="python3"
ts="$(date +%Y%m%d_%H%M%S)"

echo "=== [1] pastikan lessons_logger.py ada di ~/.hermes/action_gate ==="
mkdir -p "$AG"
if [ ! -f "$AG/lessons_logger.py" ]; then
  cp ~/jarvis/action_gate/lessons_logger.py "$AG/lessons_logger.py"
  echo "lessons_logger.py DICOPY (tadinya belum ada)"
else
  echo "lessons_logger.py sudah ada (skip)"
fi

echo "=== [2] copy plugin ke ~/.hermes/plugins/mistake_logger ==="
mkdir -p "$PLUG"
cp -f ~/jarvis/plugins/mistake_logger/__init__.py "$PLUG/__init__.py"
cp -f ~/jarvis/plugins/mistake_logger/plugin.yaml "$PLUG/plugin.yaml"
ls -la "$PLUG"

echo "=== [3] py_compile (auto-batal kalau syntax rusak) ==="
"$PYBIN" -m py_compile "$PLUG/__init__.py" "$AG/lessons_logger.py" && echo "PY_OK"

echo "=== [4] SMOKE-TEST: simulasi post_tool_call gagal -> cek LESSONS.md nambah ==="
"$PYBIN" - <<PY
import sys, os
sys.path.insert(0, "$PLUG")
import importlib.util
spec = importlib.util.spec_from_file_location("mistake_logger", "$PLUG/__init__.py")
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
L = os.path.expanduser("~/.hermes/memories/LESSONS.md")
before = os.path.getsize(L) if os.path.exists(L) else 0
# kasus gagal -> harus ke-log
m.post_tool_call(function_name="terminal", function_args={"command":"x"}, status="error",
                 error_type="SmokeTest", error_message="smoke-test mistake_logger deploy")
# kasus sukses -> TIDAK boleh ke-log
m.post_tool_call(function_name="read_file", function_args={"path":"/tmp/x"}, status="ok")
after = os.path.getsize(L) if os.path.exists(L) else 0
print("LESSONS.md nambah:", after-before, "bytes ->", "OK (gagal ke-log, sukses skip)" if after>before else "CEK MANUAL")
PY

echo "=== [5] enable plugin di config.yaml (opt-in plugins.enabled, idempotent + backup) ==="
if [ ! -f "$CFG" ]; then echo "RESULT_CFG: FAIL (config.yaml tidak ada)"; else
"$PYBIN" - "$CFG" "$ts" <<'PY'
import sys, shutil, re
cfg, ts = sys.argv[1], sys.argv[2]
lines = open(cfg, encoding="utf-8").read().splitlines()
joined = "\n".join(lines)
if re.search(r'^\s*-\s*mistake_logger\s*$', joined, re.M):
    print("RESULT_CFG: SKIP (mistake_logger sudah enabled)"); raise SystemExit
# cari blok plugins.enabled -> sisip setelah entri terakhir di list
out=[]; inserted=False; in_enabled=False; indent="    "
for i,l in enumerate(lines):
    out.append(l)
    if re.match(r'^\s*enabled:\s*$', l) and i>0 and lines[i-1].strip().startswith("plugins"):
        in_enabled=True; continue
    if in_enabled:
        # selama masih item list "- xxx", catat indent; sisip sebelum keluar blok
        if re.match(r'^\s*-\s+\S', l):
            indent = l[:len(l)-len(l.lstrip())]
        else:
            # baris pertama setelah list berakhir -> sisip sebelum baris ini
            out.insert(len(out)-1, indent + "- mistake_logger")
            inserted=True; in_enabled=False
if in_enabled and not inserted:  # list di ujung file
    out.append(indent + "- mistake_logger"); inserted=True
if not inserted:
    print("RESULT_CFG: FAIL (blok plugins.enabled tidak ketemu - cek manual)"); raise SystemExit
shutil.copy(cfg, cfg+".bak."+ts)
open(cfg,"w",encoding="utf-8").write("\n".join(out)+"\n")
# YAML sanity
try:
    import yaml; yaml.safe_load(open(cfg,encoding="utf-8"))
    print("BACKUP:", cfg+".bak."+ts); print("RESULT_CFG: SUCCESS + YAML_OK")
except Exception as e:
    shutil.copy(cfg+".bak."+ts, cfg)
    print("YAML RUSAK -> ROLLBACK:", e)
PY
fi

echo "=== PROOF ==="
echo "-- plugins.enabled sekarang --"; "$PYBIN" -c "import yaml; print(yaml.safe_load(open('$CFG')).get('plugins',{}).get('enabled'))" 2>/dev/null
echo "=== CATATAN ==="
echo "- Plugin ke-DISCOVER hanya setelah RESTART gateway (~210s, BUTUH GO Arif): systemctl --user restart hermes-gateway"
echo "- Verifikasi load: journalctl --user -u hermes-gateway --since '3 min ago' | grep -i mistake_logger (cari 'registered')"
echo "- Bukti jalan: kasih Jarvis tugas yang bikin tool error -> tail ~/.hermes/memories/LESSONS.md harus nambah entri"
echo "- KILL-SWITCH: export MISTAKE_LOGGER_OFF=1 (env gateway). ROLLBACK: rm -rf $PLUG ; cp $CFG.bak.$ts $CFG ; restart"
