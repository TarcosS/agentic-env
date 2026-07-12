#!/bin/bash
# PermissionRequest: auto-approve ExitPlanMode only. All else falls through to the normal prompt.
if [ "${1:-}" = --selfcheck ]; then
  out=$(echo '{"tool_name":"ExitPlanMode"}' | "$0"); echo "$out" | jq -e '.hookSpecificOutput.decision.behavior=="allow"' >/dev/null || { echo FAIL; exit 1; }
  out=$(echo '{"tool_name":"Bash"}' | "$0"); [ -z "$out" ] || { echo "FAIL: should not approve Bash"; exit 1; }
  echo OK; exit 0
fi

t=$(jq -r '.tool_name // empty')
# real scoping is done by the settings.json matcher ExitPlanMode; this is a defensive double-check.
[ "$t" = ExitPlanMode ] && jq -n '{hookSpecificOutput:{hookEventName:"PermissionRequest",decision:{behavior:"allow"}}}'
exit 0
