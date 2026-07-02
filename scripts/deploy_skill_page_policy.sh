#!/usr/bin/env bash
# deploy_skill_page_policy.sh
# Discovery-first + patch for document-factory SKILL.md page rules.
# Goal: LLM stops padding non-academic docs just to hit a page count.
#   - academic (is_academic=true): meet page targets (STRICT, unchanged)
#   - non-academic (business/report/proposal/personal): size-to-need, no padding
# PIPA4 council + ALL other quality checks stay strict for every doc type.
# Idempotent (marker-guarded), per-file backup. Safe to paste/run on Acer.
set -uo pipefail
TS="$(date +%Y%m%d_%H%M%S)"
MARK="PAGE-POLICY-AUTO v1"

list_found () {
  {
    find "$HOME" -maxdepth 8 -type f -name 'SKILL.md' -path '*document-factory*' 2>/dev/null
    echo "$HOME/.hermes/skills/productivity/jarvis-document-factory/SKILL.md"
    echo "$HOME/.hermes/skills/productivity/academic-document-factory/SKILL.md"
  } | sort -u | while IFS= read -r f; do [ -f "$f" ] && echo "$f"; done
}

echo "=== [1] DISCOVERY: locate document-factory SKILL.md sources ==="
FILES="$(list_found)"
if [ -z "$FILES" ]; then
  echo "   WARN: no document-factory SKILL.md found under \$HOME"
else
  printf '%s\n' "$FILES" | while IFS= read -r f; do
    echo "   FOUND: $f"
    top="$(cd "$(dirname "$f")" && git rev-parse --show-toplevel 2>/dev/null || true)"
    [ -n "$top" ] && echo "     git-repo: $top (commit di sini biar persist)"
  done
fi

echo "=== [2] Existing page/top-up directives (the real source of truth) ==="
grep -rn -E 'NEEDS_PAGE_TOPUP|top-?up|topup|page[ _]count|jumlah halaman' "$HOME/.hermes/skills" 2>/dev/null | head -n 40 || echo "   (none / dir missing)"

echo "=== [3] PATCH: inject audience-aware override block ==="
if [ -z "$FILES" ]; then
  echo "   skipped (no files)"
else
  printf '%s\n' "$FILES" | while IFS= read -r f; do
    if grep -qF "$MARK" "$f"; then echo "   already patched: $f"; continue; fi
    cp -p "$f" "${f}.bak.${TS}"
    cat >> "$f" <<'MD'

<!-- PAGE-POLICY-AUTO v1 -->
## [AUTO] AUDIENCE-AWARE PAGE POLICY (v1) — MENGGANTIKAN aturan page top-up sebelumnya di file ini
- Panjang dokumen ditentukan kebutuhan konten + audience, BUKAN target halaman kaku.
- Akademik (`is_academic=true`): penuhi target halaman tugas (STRICT, seperti biasa).
- Non-akademik (bisnis/report/proposal/personal): tulis size-to-need. JANGAN padding demi ngejar jumlah halaman. Dokumen 3-4 halaman SAH selama konten cukup.
- WAJIB set `is_academic` dengan benar saat membangun SPEC — ini yang mengaktifkan adaptivity otomatis.
- `NEEDS_PAGE_TOPUP` BUKAN blocker untuk non-akademik (PIPA4 gate sudah auto-bypass; lihat `deploy_page_auto_adaptive.sh`). Jangan loop top-up untuk non-akademik.
- SEMUA check kualitas lain TETAP KERAS untuk semua jenis dokumen: struktur, evidence, humanizer, dan council PIPA4.
<!-- /PAGE-POLICY-AUTO v1 -->
MD
    echo "   patched: $f"
  done
fi

echo "=== [4] VERIFY ==="
if [ -n "$FILES" ]; then
  printf '%s\n' "$FILES" | while IFS= read -r f; do
    if grep -qF "$MARK" "$f"; then echo "   OK   $f"; else echo "   MISS $f"; fi
  done
fi
echo "=== DONE. SKILL.md page policy = audience-aware; council + quality tetap keras ==="
