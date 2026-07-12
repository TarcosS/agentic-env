#!/bin/bash
# Run every hook script's --selfcheck; fail if any doesn't finish with OK.
# Wired into scripts/ci-checks.sh so a broken hook fails CI and the commit gate.
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 1
fail=0
for h in .claude/hooks/*.sh; do
  base=$(basename "$h")
  [ "$base" = test-hooks.sh ] && continue
  grep -q -- '--selfcheck' "$h" || continue
  out=$("$h" --selfcheck 2>&1)
  if [ "$(printf '%s\n' "$out" | tail -n1)" = OK ]; then
    echo "ok: $base"
  else
    echo "FAIL: $base -> $out" >&2
    fail=1
  fi
done
[ $fail -eq 0 ] && echo "all hook selfchecks passed"
exit $fail
