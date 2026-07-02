#!/usr/bin/env bash
# Crystallization Gateway CLI — promote episodic speculation to crystallized decision
set -euo pipefail
VENV="/home/arif/.hermes/hermes-agent/venv/bin/python"
MEMORY="$HOME/.hermes/scripts/temporal_tiered_memory.py"
cmd="${1:-}"; arg="${2:-}"
case "$cmd" in
  --topic|-t)
    [ -n "$arg" ] || { echo "Usage: crystallize_gateway.sh --topic <topic>"; exit 1; }
    echo "=== Episodic entries for: $arg ==="
    "$VENV" "$MEMORY" retrieve --query "$arg" --top 20 2>&1 | while IFS= read -r line; do [ -n "$line" ] && echo "$line" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(f'ID={d[\"id\"]} type={d[\"content_type\"]} tags={d[\"tags\"]} w={d[\"temporal_weight\"]:.3f} text={d[\"text\"][:120]}')" 2>/dev/null; done
    ;;
  --id|-i)
    [ -n "$arg" ] || { echo "Usage: crystallize_gateway.sh --id <entry_id>"; exit 1; }
    "$VENV" "$MEMORY" crystallize --id "$arg" 2>&1
    ;;
  --list|-l)
    "$VENV" "$MEMORY" retrieve --top 50 2>&1 | while IFS= read -r line; do [ -n "$line" ] && echo "$line" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(f'[{d[\"content_type\"]}] {d[\"text\"][:150]}')" 2>/dev/null; done
    ;;
  --stats|-s) "$VENV" "$MEMORY" stats 2>&1 ;;
  *) echo "Usage: crystallize_gateway.sh --topic|--id|--list|--stats" ;;
esac
