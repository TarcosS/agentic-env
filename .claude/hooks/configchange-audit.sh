#!/bin/bash
# ConfigChange: append a JSONL audit record. Log-only; could exit 2 / emit {"decision":"block"} to block instead.
LOGDIR="${CLAUDE_HOOK_LOGDIR:-${CLAUDE_PROJECT_DIR:-.}/.claude/logs}"
if [ "${1:-}" = --selfcheck ]; then
  d=$(mktemp -d)
  echo '{"source":"test","file_path":"/tmp/x"}' | CLAUDE_HOOK_LOGDIR="$d" "$0" >/dev/null
  [ -s "$d/config-audit.log" ] && echo OK || echo FAIL
  exit 0
fi

mkdir -p "$LOGDIR"
jq -c --arg ts "$(date -u +%FT%TZ)" \
  '{timestamp:$ts, source:.source, file_path:.file_path}' \
  >> "$LOGDIR/config-audit.log"
exit 0
