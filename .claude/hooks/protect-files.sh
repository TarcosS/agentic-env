#!/bin/bash
# PreToolUse Edit|Write: block edits to protected files (secrets, locks, git internals, settings).
# Exit 2 blocks the turn so Claude sees the error and picks another path.
if [ "${1:-}" = --selfcheck ]; then
  echo '{"tool_input":{"file_path":".env"}}' | "$0"; [ $? -eq 2 ] || { echo "FAIL: expected block"; exit 1; }
  echo '{"tool_input":{"file_path":"src/app.js"}}' | "$0"; [ $? -eq 0 ] || { echo "FAIL: expected allow"; exit 1; }
  echo OK; exit 0
fi

f=$(jq -r '.tool_input.file_path // empty')
[ -n "$f" ] || exit 0

case "$f" in
  *.env|*.env.*|*/.env|*/.env.*) echo "Blocked: $f is a protected env file" >&2; exit 2 ;;
  *.lock|*/package-lock.json|package-lock.json) echo "Blocked: $f is a protected lockfile" >&2; exit 2 ;;
  .git/*|*/.git/*) echo "Blocked: $f is inside .git/" >&2; exit 2 ;;
  .claude/settings.json|*/.claude/settings.json) echo "Blocked: $f is the Claude settings file" >&2; exit 2 ;;
esac
exit 0
