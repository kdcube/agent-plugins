#!/usr/bin/env bash
# Report when a tier1/ pack file no longer matches its source in the local
# kdcube-ai-app checkout. Each pack file is a copy that keeps the source `id:`
# (upstream path) and `updated_at` (version), so both are read from the file.
#
# Always exits 0; prints nothing unless a file diverges. The action depends on
# direction:
#   BEHIND (checkout newer) -> re-copy from the checkout is safe.
#   AHEAD  (pack newer)     -> the checkout is not on that version yet; read from
#                              the checkout, do not overwrite the pack.
set -uo pipefail

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPOS_YAML="${PLUGIN_ROOT}/config/repos.yaml"
TIER1="${PLUGIN_ROOT}/tier1"

# repos.yaml holds the checkout path; without it there is nothing to compare to.
[[ -f "$REPOS_YAML" ]] || exit 0

KDCUBE_LOCAL=$(awk '
  /^[[:space:]]*kdcube-ai-app:[[:space:]]*$/ { in_kd=1; next }
  in_kd && /^[[:space:]]+local_path:[[:space:]]/ {
    sub(/^[[:space:]]+local_path:[[:space:]]*/, "")
    gsub(/^["'"'"']|["'"'"']$/, "")
    print; exit
  }
  /^[a-zA-Z_-]+:[[:space:]]*$/ && in_kd { in_kd=0 }
' "$REPOS_YAML")
[[ -n "${KDCUBE_LOCAL:-}" && -d "$KDCUBE_LOCAL" ]] || exit 0

_fm() {  # frontmatter value: _fm <file> <key>
  grep -m1 "^$2:" "$1" 2>/dev/null | sed "s/^$2:[[:space:]]*//" | tr -d "\"'"
}

behind=""; ahead=""; unclear=""

shopt -s nullglob
for pack in "$TIER1"/*.md; do
  base="$(basename "$pack")"
  id="$(_fm "$pack" id)"
  [[ "$id" == repo:kdcube-ai-app/* ]] || continue
  src="${KDCUBE_LOCAL}/${id#repo:kdcube-ai-app/}"

  # Source doc gone from the checkout: the pack has a doc the checkout lacks.
  if [[ ! -f "$src" ]]; then
    ahead+=$(printf '\n    %-24s source not in checkout' "$base")
    continue
  fi

  cmp -s "$pack" "$src" && continue

  p="$(_fm "$pack" updated_at)"; l="$(_fm "$src" updated_at)"
  if [[ -n "$p" && -n "$l" && "$p" != "$l" ]]; then
    if [[ "$l" > "$p" ]]; then
      behind+=$(printf '\n    %-24s pack %s  <  checkout %s' "$base" "$p" "$l")
    else
      ahead+=$(printf '\n    %-24s pack %s  >  checkout %s' "$base" "$p" "$l")
    fi
  else
    # Content differs but dates cannot order it (equal or missing on one side).
    unclear+=$(printf '\n    %-24s differs; dates equal/absent' "$base")
  fi
done

[[ -z "$behind" && -z "$ahead" && -z "$unclear" ]] && exit 0

echo "[kdcube] tier1 pack diverges from the local kdcube-ai-app checkout"
echo "  (checkout HEAD $(git -C "$KDCUBE_LOCAL" rev-parse --short HEAD 2>/dev/null || echo '?') — the checkout is authoritative)."
[[ -n "$behind"  ]] && echo "  BEHIND the checkout:${behind}"
[[ -n "$ahead"   ]] && echo "  AHEAD of the checkout (pack knows a platform you are NOT running):${ahead}"
[[ -n "$unclear" ]] && echo "  DIFFERS, direction unclear:${unclear}"
echo "  ---"

if [[ -z "$ahead" ]]; then
  # behind and/or unclear: a full re-copy aligns every file to the checkout.
  echo "  Don't wait to be asked: sync the pack yourself now — run bin/refresh-tier1.sh"
  echo "  (docs-only copy from the checkout) — then tell the operator which files moved."
else
  echo "  Read ground truth from the CHECKOUT (not the pack) for the work at hand."
  echo "  Do NOT auto-refresh: it would overwrite the newer pack. Tell the operator —"
  echo "  either pull the platform forward (git pull / kdcube refresh --upstream),"
  echo "  or run /kdcube:knowledge-refresh to align the pack down to the checkout."
fi
exit 0
