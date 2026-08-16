#!/usr/bin/env bash
# Staleness check: how far behind HEAD each knowledge document's basis_commit is.
#
# Usage:   ./scripts/check-staleness.sh
#          Runs from anywhere inside the repository: the script changes to the
#          repository root before doing anything. A relative DOCS_DIR is
#          therefore relative to the repository root, not to the caller's
#          working directory; an absolute DOCS_DIR is used as-is.
# Env:     MAX_BEHIND (default 200), DOCS_DIR (default docs/knowledge), STRICT (default 0)
#
# Exit:    0  ran; either no findings, or findings with STRICT=0
#          1  findings and STRICT=1
#          2  could not run at all: this is not a git repository, or it has no
#             HEAD to count against. Independent of STRICT, because an inability
#             to run is not a finding.
#
# Same three-code contract as check-docs.sh, and for the same reason: a check
# that cannot do its job must not be able to produce a green. The two scripts
# differ in what reaches 2. check-docs.sh compares against one base ref, so
# losing it stops the whole run; here the comparison point is per document -
# each file's own basis_commit - so a document that cannot be counted is a
# finding against that document and the remaining documents are still checked.
# Only a repository-level failure, where nothing could be counted, is a 2.
set -uo pipefail

MAX_BEHIND="${MAX_BEHIND:-200}"
DOCS_DIR="${DOCS_DIR:-docs/knowledge}"
STRICT="${STRICT:-0}"
STATUS=0
FOUND_DOC=0
INSPECTED=0
FINDINGS=0

# A relative DOCS_DIR is resolved against the repository root, and the script
# must stand there for its glob to see the documents. Run from a subdirectory,
# it would report "no documents" and exit 0 - a false green. So resolve the
# root instead of trusting the caller. An absolute DOCS_DIR is unaffected by
# the cd.
if ! ROOT="$(git rev-parse --show-toplevel)"; then
  echo "check-staleness: not inside a git repository - git's own message is above." >&2
  echo "                 Nothing was checked." >&2
  exit 2
fi
if ! cd "$ROOT"; then
  echo "check-staleness: could not change to the repository root '${ROOT}'. Nothing was checked." >&2
  exit 2
fi

# The root resolution above already proved this is a git repository, so what
# this catches is a repository with no commits yet.
if ! git rev-parse --verify --quiet HEAD >/dev/null; then
  echo "check-staleness: no HEAD to count against - this repository has no" >&2
  echo "                 commits yet. Nothing was checked." >&2
  exit 2
fi

for doc in "$DOCS_DIR"/*.md; do
  [ -f "$doc" ] || continue
  FOUND_DOC=1
  INSPECTED=$((INSPECTED + 1))

  basis="$(awk -F':[[:space:]]*' '/^basis_commit:/{gsub(/[[:space:]"'\''"]/,"",$2); print $2; exit}' "$doc")"

  if [ -z "$basis" ]; then
    echo "MISSING basis_commit: $doc" >&2
    STATUS=1
    FINDINGS=$((FINDINGS + 1))
    continue
  fi

  if ! git cat-file -e "${basis}^{commit}" 2>/dev/null; then
    echo "UNKNOWN commit in $doc: $basis" >&2
    STATUS=1
    FINDINGS=$((FINDINGS + 1))
    continue
  fi

  # Never substitute a value here. `|| echo 0` recorded a failed count as zero
  # commits behind, which is the healthiest result the check can report: the
  # inability to answer was rendered as perfect health. A shallow or partial
  # clone is the case that reaches this, since the commit can be present while
  # the history between it and HEAD is not.
  if ! behind="$(git rev-list --count "${basis}..HEAD" 2>&1)"; then
    echo "UNCOUNTABLE: $doc - 'git rev-list --count ${basis}..HEAD' failed: ${behind}" >&2
    STATUS=1
    FINDINGS=$((FINDINGS + 1))
    continue
  fi

  # An empty or non-numeric count would make the comparison below a bash syntax
  # error on stderr, leaving STATUS untouched and the document skipped inside an
  # exit-0 run.
  case "$behind" in
    ''|*[!0-9]*)
      echo "UNCOUNTABLE: $doc - commit count for ${basis}..HEAD was not a number: '${behind}'" >&2
      STATUS=1
      FINDINGS=$((FINDINGS + 1))
      continue
      ;;
  esac

  if [ "$behind" -gt "$MAX_BEHIND" ]; then
    echo "STALE: $doc is $behind commits behind (limit $MAX_BEHIND)" >&2
    STATUS=1
    FINDINGS=$((FINDINGS + 1))
  fi
done

if [ "$FOUND_DOC" -eq 0 ]; then
  echo "check-staleness: no documents in ${DOCS_DIR}, nothing to check."
  exit 0
fi

if [ "$STATUS" -ne 0 ]; then
  # A run that says nothing cannot be told apart from a run that never happened,
  # so the count is printed on the finding path too.
  echo "check-staleness: ${INSPECTED} documents inspected, ${FINDINGS} with findings." >&2
  if [ "$STRICT" = "1" ]; then
    echo "check-staleness: failing because STRICT=1." >&2
    exit 1
  fi
  echo "check-staleness: warnings only. Set STRICT=1 to make findings a hard failure." >&2
  exit 0
fi

echo "check-staleness: ${INSPECTED} documents checked, none stale."
exit 0
