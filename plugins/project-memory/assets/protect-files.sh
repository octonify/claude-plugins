#!/usr/bin/env bash
# PreToolUse hook for Edit|Write. Blocks writes to paths that must not change.
#
# Exit codes, per the Claude Code hooks documentation:
#   2 -> block the tool call, stderr is fed back to the model
#   0 -> no decision, the normal permission flow continues
# Do not mix these with hookSpecificOutput JSON in the same hook.
#
# Edit PROTECTED below to match the project.
PROTECTED=("docs/decisions/" ".env" "infra/prod")

INPUT="$(cat)"

# The discarded output is deliberate: the probe's only question is whether jq
# is on PATH, both answers are handled by the branch, and the fallback below
# says out loud when the answer forced it to degrade.
if command -v jq >/dev/null 2>&1; then
  FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')"
  READ_BY="jq"
else
  # Fallback so a missing jq degrades to "allow", never to a spurious block.
  FILE_PATH="$(printf '%s' "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
  # The extracted body still carries JSON escaping: a Windows path arrives as
  # D:\\Projects\\..., normalises to D://Projects//..., and then matches no
  # pattern - the hook would allow a write to a protected file. Undo \\, \"
  # and \/ in one left-to-right pass (one sed substitution, so \\/ becomes \/
  # and is not mangled by sequential replacements). This is still not a JSON
  # parser: \n, \uXXXX and escaped quotes inside the path defeat it.
  # Installing jq is what makes this hook reliable.
  FILE_PATH="$(printf '%s' "$FILE_PATH" | sed 's@\\\(["/\\]\)@\1@g')"
  READ_BY="sed"
fi

# Failing open is the right decision for a protection hook: exit 2 on every call
# would block all editing. Failing open in silence is not, because exit 0 then
# means both "checked, and this file is not protected" and "could not check at
# all", and nothing tells the user which protection they are getting.
if [ -z "$FILE_PATH" ]; then
  if [ "$READ_BY" = "jq" ]; then
    echo "protect-files: the tool input carried no file_path; nothing to check, not enforcing." >&2
  else
    echo "protect-files: could not read the tool input (jq not found, and the fallback found no file_path); not enforcing." >&2
  fi
  exit 0
fi

# Compare with forward slashes so Windows-style paths match the same patterns.
NORMALISED="${FILE_PATH//\\//}"

for pattern in "${PROTECTED[@]}"; do
  case "$NORMALISED" in
    *"$pattern"*)
      echo "Blocked: $FILE_PATH is protected. Accepted decisions are immutable; supersede with a new record instead of editing this one." >&2
      exit 2
      ;;
  esac
done

exit 0
