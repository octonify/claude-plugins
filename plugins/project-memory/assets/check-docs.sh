#!/usr/bin/env bash
# Drift check: if code under a path a knowledge document claims to cover changed,
# and the document did not, say so.
#
# Usage:   ./scripts/check-docs.sh [base-ref]
# Default base ref: origin/main, falling back to main, then to the empty tree.
# Exit:    0 always, unless STRICT=1, in which case drift exits 1.
#
# Reads the `covers_paths:` list from the YAML frontmatter of each
# docs/knowledge/*.md file. Documents without that key are skipped.
set -uo pipefail

DOCS_DIR="${DOCS_DIR:-docs/knowledge}"
STRICT="${STRICT:-0}"
EMPTY_TREE=4b825dc642cb6eb9a060e54bf8d69288fbee4904

resolve_base() {
  if [ "$#" -ge 1 ] && [ -n "${1:-}" ]; then
    printf '%s\n' "$1"; return
  fi
  for candidate in origin/main origin/master main master; do
    if git rev-parse --verify --quiet "$candidate" >/dev/null; then
      printf '%s\n' "$candidate"; return
    fi
  done
  printf '%s\n' "$EMPTY_TREE"
}

BASE="$(resolve_base "$@")"

if [ "$BASE" = "$EMPTY_TREE" ]; then
  CHANGED="$(git diff --name-only "$BASE" HEAD 2>/dev/null || git ls-files)"
else
  CHANGED="$(git diff --name-only "$BASE"...HEAD 2>/dev/null || true)"
fi

if [ -z "$CHANGED" ]; then
  echo "check-docs: no changes against ${BASE}, nothing to check."
  exit 0
fi

# Emit the covers_paths entries of one document, bounded to the frontmatter block.
covers_paths_of() {
  awk '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---"   { exit }
    !in_fm                 { exit }
    /^covers_paths:[[:space:]]*$/ { collecting = 1; next }
    /^[A-Za-z_][A-Za-z0-9_-]*:/   { collecting = 0 }
    collecting && /^[[:space:]]*-[[:space:]]+/ {
      sub(/^[[:space:]]*-[[:space:]]+/, "")
      sub(/[[:space:]]+$/, "")
      gsub(/^["'\''"]|["'\''"]$/, "")
      if (length($0)) print
    }
  ' "$1"
}

STATUS=0
FOUND_DOC=0

for doc in "$DOCS_DIR"/*.md; do
  [ -f "$doc" ] || continue
  FOUND_DOC=1

  paths="$(covers_paths_of "$doc")"
  [ -z "$paths" ] && continue

  doc_touched=false
  if printf '%s\n' "$CHANGED" | grep -qxF "$doc"; then
    doc_touched=true
  fi
  [ "$doc_touched" = true ] && continue

  while IFS= read -r p; do
    [ -z "$p" ] && continue
    # Reduce a glob to its literal prefix: src/api/** -> src/api/
    prefix="${p%%\**}"
    # A pattern that is nothing but a glob would match every changed file.
    if [ -z "$prefix" ]; then
      echo "check-docs: ignoring unbounded pattern '$p' in $doc" >&2
      continue
    fi
    if printf '%s\n' "$CHANGED" | grep -qF -- "$prefix"; then
      echo "DRIFT: $p changed but $doc was not updated" >&2
      STATUS=1
      break
    fi
  done <<EOF
$paths
EOF
done

if [ "$FOUND_DOC" -eq 0 ]; then
  echo "check-docs: no documents in ${DOCS_DIR}, nothing to check."
  exit 0
fi

if [ "$STATUS" -ne 0 ]; then
  if [ "$STRICT" = "1" ]; then
    echo "check-docs: failing because STRICT=1." >&2
    exit 1
  fi
  echo "check-docs: warnings only. Set STRICT=1 to make drift a hard failure." >&2
fi

exit 0
