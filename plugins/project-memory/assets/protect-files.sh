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

if command -v jq >/dev/null 2>&1; then
  FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')"
else
  # Fallback so a missing jq degrades to "allow", never to a spurious block.
  FILE_PATH="$(printf '%s' "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
fi

[ -z "$FILE_PATH" ] && exit 0

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
