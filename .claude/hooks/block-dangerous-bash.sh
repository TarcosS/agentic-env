#!/bin/bash
# PreToolUse Bash: block destructive commands (grep-based best-effort guardrail).
# Exit 2 blocks the turn so Claude sees the error and picks another path.
if [ "${1:-}" = --selfcheck ]; then
  echo '{"tool_input":{"command":"rm -rf /"}}' | "$0"; [ $? -eq 2 ] || { echo "FAIL: expected block"; exit 1; }
  echo '{"tool_input":{"command":"ls -la"}}' | "$0"; [ $? -eq 0 ] || { echo "FAIL: expected allow"; exit 1; }
  echo OK; exit 0
fi

c=$(jq -r '.tool_input.command // empty')
[ -n "$c" ] || exit 0

block() { echo "Blocked: command matches destructive pattern ($1)" >&2; exit 2; }

echo "$c" | grep -qE 'rm[[:space:]]+-rf[[:space:]]+(/|~)([[:space:]]|$|\*)' && block "rm -rf /|~"
echo "$c" | grep -qE 'git[[:space:]]+push.*(--force|-f)([[:space:]]|$).*(main|master)' && block "force-push to main/master"
echo "$c" | grep -qE 'git[[:space:]]+push.*(main|master).*(--force|-f)([[:space:]]|$)' && block "force-push to main/master"
echo "$c" | grep -qE '(curl|wget)[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(sh|bash)([[:space:]]|$)' && block "pipe-to-shell install"
echo "$c" | grep -qE 'chmod[[:space:]]+-R[[:space:]]+777' && block "chmod -R 777"
echo "$c" | grep -qE '(^|[[:space:]])mkfs(\.|[[:space:]])' && block "mkfs"
echo "$c" | grep -qE 'dd[[:space:]]+.*of=/dev/' && block "dd of=/dev/"
echo "$c" | grep -qF ':(){' && block "fork bomb"

exit 0
