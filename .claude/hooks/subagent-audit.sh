#!/bin/bash
# SubagentStart|SubagentStop: append a JSONL audit record of the event.
LOGDIR="${CLAUDE_HOOK_LOGDIR:-${CLAUDE_PROJECT_DIR:-.}/.claude/logs}"
if [ "${1:-}" = --selfcheck ]; then
  d=$(mktemp -d)
  echo '{"hook_event_name":"SubagentStart","agent_type":"test","session_id":"abc"}' | CLAUDE_HOOK_LOGDIR="$d" "$0" >/dev/null
  [ -s "$d/subagents.log" ] && echo OK || echo FAIL
  exit 0
fi

mkdir -p "$LOGDIR"
jq -c --arg ts "$(date -u +%FT%TZ)" \
  '{timestamp:$ts, event:.hook_event_name, agent:(.agent_type // .subagent_type // "unknown"), session:.session_id}' \
  >> "$LOGDIR/subagents.log"
exit 0
