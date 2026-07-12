#!/bin/bash
# Stop hook: run whole-tree checks when Claude finishes a turn; block (soft) so it keeps fixing.
if [ "${1:-}" = --selfcheck ]; then
  echo '{"stop_hook_active":true}' | "$0" >/dev/null; [ $? -eq 0 ] || { echo FAIL; exit 1; }
  echo OK; exit 0
fi

active=$(jq -r '.stop_hook_active // false')
[ "$active" = true ] && exit 0

out=$("${CLAUDE_PROJECT_DIR:-.}/scripts/ci-checks.sh" 2>&1) || \
  jq -n --arg r "$out" '{decision:"block",reason:("Checks are red, fix before finishing:\n"+$r)}'
exit 0
