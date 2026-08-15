#!/usr/bin/env bash
# Staleness check: how far behind HEAD each knowledge document's basis_commit is.
#
# Usage:   ./scripts/check-staleness.sh
# Env:     MAX_BEHIND (default 200), DOCS_DIR (default docs/knowledge), STRICT (default 0)
# Exit:    0 always, unless STRICT=1, in which case any finding exits 1.
set -uo pipefail

MAX_BEHIND="${MAX_BEHIND:-200}"
DOCS_DIR="${DOCS_DIR:-docs/knowledge}"
STRICT="${STRICT:-0}"
STATUS=0
FOUND_DOC=0

for doc in "$DOCS_DIR"/*.md; do
  [ -f "$doc" ] || continue
  FOUND_DOC=1

  basis="$(awk -F':[[:space:]]*' '/^basis_commit:/{gsub(/[[:space:]"'\''"]/,"",$2); print $2; exit}' "$doc")"

  if [ -z "$basis" ]; then
    echo "MISSING basis_commit: $doc" >&2
    STATUS=1
    continue
  fi

  if ! git cat-file -e "${basis}^{commit}" 2>/dev/null; then
    echo "UNKNOWN commit in $doc: $basis" >&2
    STATUS=1
    continue
  fi

  behind="$(git rev-list --count "${basis}..HEAD" 2>/dev/null || echo 0)"
  if [ "$behind" -gt "$MAX_BEHIND" ]; then
    echo "STALE: $doc is $behind commits behind (limit $MAX_BEHIND)" >&2
    STATUS=1
  fi
done

if [ "$FOUND_DOC" -eq 0 ]; then
  echo "check-staleness: no documents in ${DOCS_DIR}, nothing to check."
  exit 0
fi

if [ "$STATUS" -ne 0 ]; then
  if [ "$STRICT" = "1" ]; then
    echo "check-staleness: failing because STRICT=1." >&2
    exit 1
  fi
  echo "check-staleness: warnings only. Set STRICT=1 to make findings a hard failure." >&2
fi

exit 0
