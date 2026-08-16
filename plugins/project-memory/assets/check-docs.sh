#!/usr/bin/env bash
# Drift check: if code under a path a knowledge document claims to cover changed,
# and the document did not, say so.
#
# Usage:   ./scripts/check-docs.sh [base-ref]
#
# Base ref: the first argument if given, otherwise the first of
# origin/main, origin/master, main, master that exists, is not the branch that
# is currently checked out, and does not point at HEAD. A ref that fails those
# last two tests is not a base: `git diff <it>...HEAD` is empty by construction
# and the check would report success without having compared anything.
#
# Exit:    0  ran against a named base; either no drift, or drift with STRICT=0
#          1  drift found and STRICT=1
#          2  could not run: no usable base ref, or an explicitly given base
#             that is not usable by the same rules. Independent of STRICT —
#             this is an inability to run, not a finding.
#
# Reads the `covers_paths:` list from the YAML frontmatter of each
# docs/knowledge/*.md file. Documents without that key are skipped.
set -uo pipefail

DOCS_DIR="${DOCS_DIR:-docs/knowledge}"
STRICT="${STRICT:-0}"
CANDIDATES="origin/main origin/master main master"

HEAD_SHA="$(git rev-parse --verify --quiet HEAD || true)"
CURRENT_BRANCH="$(git symbolic-ref --quiet --short HEAD || true)"

# Why a candidate cannot serve as a base, or empty if it can.
reject_reason() {
  candidate="$1"
  sha="$(git rev-parse --verify --quiet "${candidate}^{commit}" || true)"
  if [ -z "$sha" ]; then
    printf '%s\n' "does not exist"
  elif [ -n "$CURRENT_BRANCH" ] && [ "$candidate" = "$CURRENT_BRANCH" ]; then
    printf '%s\n' "is the branch currently checked out"
  elif [ -n "$HEAD_SHA" ] && [ "$sha" = "$HEAD_SHA" ]; then
    printf '%s\n' "points at HEAD ($(git rev-parse --short "$sha")), so the diff is empty by construction"
  fi
}

if [ "$#" -ge 1 ] && [ -n "${1:-}" ]; then
  BASE="$1"
  reason="$(reject_reason "$BASE")"
  if [ -n "$reason" ]; then
    echo "check-docs: base ref '${BASE}' was given explicitly but ${reason}." >&2
    echo "check-docs: refusing to fall back to a default; nothing was checked." >&2
    exit 2
  fi
  echo "check-docs: base ref ${BASE} (given explicitly)."
else
  BASE=""
  for candidate in $CANDIDATES; do
    reason="$(reject_reason "$candidate")"
    if [ -z "$reason" ]; then
      BASE="$candidate"
      break
    fi
    echo "check-docs: candidate ${candidate} rejected: ${reason}." >&2
  done

  if [ -z "$BASE" ]; then
    cat >&2 <<EOF
check-docs: no usable base ref. Tried: ${CANDIDATES}. Each was rejected above.
check-docs: nothing was compared, so this run proves nothing. Pass the ref this
            work branched from, explicitly:
              ./scripts/check-docs.sh <ref>
              ./scripts/check-docs.sh HEAD~1   # last commit only; fails on a
                                               # repository with one commit
EOF
    exit 2
  fi
  echo "check-docs: base ref ${BASE} (resolved from: ${CANDIDATES})."
fi

# `git diff A...HEAD` needs a merge base. Without one git errors and prints
# nothing, which would read as "no changes" — the same silent success again.
if [ -z "$(git merge-base "$BASE" HEAD 2>/dev/null || true)" ]; then
  echo "check-docs: ${BASE} and HEAD have no common ancestor, so there is no" >&2
  echo "            three-dot diff to take. Nothing was compared." >&2
  exit 2
fi

CHANGED="$(git diff --name-only "$BASE"...HEAD 2>/dev/null || true)"

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
  exit 0
fi

echo "check-docs: no drift against ${BASE}."
exit 0
