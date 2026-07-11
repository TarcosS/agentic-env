#!/bin/bash
# PostToolUse Edit|Write: validate just the edited file by extension.
# Exit 2 blocks the turn so Claude sees the error and fixes it before continuing.
f=$(jq -r '.tool_input.file_path // empty')
[ -n "$f" ] && [ -f "$f" ] || exit 0

case "$f" in
  *.json) tool="python3 -m json.tool"; label="Invalid JSON" ;;
  *.sh)   tool="bash -n";              label="Shell syntax error" ;;
  *.py)   tool="python3 -m py_compile"; label="Python won't compile" ;;
  *) exit 0 ;;
esac

if ! out=$($tool "$f" 2>&1 >/dev/null); then
  echo "$label in $f — fix before continuing:" >&2
  echo "$out" >&2
  exit 2
fi
exit 0
