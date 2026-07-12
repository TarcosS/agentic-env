#!/bin/bash
# SessionEnd: append a JSONL audit record, then best-effort clean scratch temp files.
LOGDIR="${CLAUDE_HOOK_LOGDIR:-${CLAUDE_PROJECT_DIR:-.}/.claude/logs}"
if [ "${1:-}" = --selfcheck ]; then
  d=$(mktemp -d)
  echo '{"session_id":"abc","reason":"test"}' | CLAUDE_HOOK_LOGDIR="$d" "$0" >/dev/null
  [ -s "$d/sessions.log" ] && echo OK || echo FAIL
  exit 0
fi

mkdir -p "$LOGDIR"
jq -c --arg ts "$(date -u +%FT%TZ)" \
  '{timestamp:$ts, session:.session_id, reason:.reason}' \
  >> "$LOGDIR/sessions.log"
rm -f /tmp/claude-scratch-* 2>/dev/null
exit 0
