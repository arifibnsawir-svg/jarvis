#!/usr/bin/env bash
# =============================================================================
# integrity_check.sh
# -----------------------------------------------------------------------------
# Jarvis Integrity Check — verify that a claimed operation actually happened.
#
# Known pattern (2026-07-02): Jarvis claimed "background process selesai, re-run
# complete" but both PDF files had SHA256 c1a43ef6... — identical, no re-render.
#
# This script compares BEFORE/AFTER state to provide raw evidence.
# Usage:
#   integrity_check.sh --before <file1> <file2> ... --after <file1> <file2> ...
#   integrity_check.sh --verify-render <output_dir> --since <timestamp>
#   integrity_check.sh --solo <new_file>  (verify file was just created)
# =============================================================================
set -euo pipefail

MODE="${1:-}"
shift || true

case "$MODE" in
  --before)
    BEFORE_FILES=()
    AFTER_FILES=()
    target="before"
    for arg in "$@"; do
      [ "$arg" = "--after" ] && { target="after"; continue; }
      [ "$target" = "before" ] && BEFORE_FILES+=("$arg") || AFTER_FILES+=("$arg")
    done
    
    [ ${#BEFORE_FILES[@]} -gt 0 ] || { echo "ERROR: no --before files"; exit 2; }
    
    ALL_IDENTICAL=true
    for i in "${!BEFORE_FILES[@]}"; do
      b="${BEFORE_FILES[$i]}"
      a="${AFTER_FILES[$i]:-}"
      [ -f "$b" ] || { echo "MISSING before: $b"; exit 3; }
      [ -f "$a" ] || { echo "MISSING after: $a"; exit 3; }
      sha_b=$(sha256sum "$b" | awk '{print $1}')
      sha_a=$(sha256sum "$a" | awk '{print $1}')
      size_b=$(wc -c < "$b" | tr -d ' ')
      size_a=$(wc -c < "$a" | tr -d ' ')
      ts_b=$(stat -c %Y "$b" 2>/dev/null || stat -f %m "$b" 2>/dev/null || echo 0)
      ts_a=$(stat -c %Y "$a" 2>/dev/null || stat -f %m "$a" 2>/dev/null || echo 0)
      echo "[$i] $b"
      echo "    SHA256: $sha_b | size: $size_b | mtime: $ts_b"
      echo "    SHA256: $sha_a | size: $size_a | mtime: $ts_a"
      if [ "$sha_b" = "$sha_a" ] && [ "$size_b" = "$size_a" ]; then
        echo "    VERDICT: IDENTICAL — no actual change detected"
      else
        echo "    VERDICT: CHANGED — operation had real effect"
        ALL_IDENTICAL=false
      fi
    done
    $ALL_IDENTICAL && { echo "INTEGRITY_FAIL: all files identical — claimed operation was FALSE"; exit 1; }
    echo "INTEGRITY_PASS: at least one file changed — operation was REAL"; exit 0
    ;;
    
  --solo)
    FILE="${1:-}"
    [ -n "$FILE" ] || { echo "Usage: integrity_check.sh --solo <file>"; exit 2; }
    [ -f "$FILE" ] || { echo "MISSING: $FILE"; exit 1; }
    sha=$(sha256sum "$FILE" | awk '{print $1}')
    size=$(wc -c < "$FILE" | tr -d ' ')
    ts=$(stat -c %Y "$FILE" 2>/dev/null || stat -f %m "$FILE" 2>/dev/null || echo 0)
    echo "FILE: $FILE"
    echo "SHA256: $sha | size: $size | mtime: $ts"
    exit 0
    ;;
    
  --verify-render)
    DIR="${1:-}"; SINCE="${2:-}"
    [ -d "$DIR" ] || { echo "MISSING dir: $DIR"; exit 2; }
    [ -n "$SINCE" ] || SINCE="5 minutes ago"
    echo "Files in $DIR modified since $SINCE:"
    find "$DIR" -type f -newermt "$SINCE" -exec ls -lah {} \; 2>/dev/null || echo "(no recently modified files)"
    exit 0
    ;;
    
  *)
    echo "Usage:"
    echo "  integrity_check.sh --before <files...> --after <files...>"
    echo "  integrity_check.sh --solo <file>"
    echo "  integrity_check.sh --verify-render <dir> [--since '5 min ago']"
    exit 2
    ;;
esac
