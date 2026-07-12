#!/bin/bash
# PostToolUse Edit|Write: autoformat the touched file by extension. Never blocks.
if [ "${1:-}" = --selfcheck ]; then
  echo '{"tool_input":{"file_path":"/nonexistent"}}' | "$0" >/dev/null; [ $? -eq 0 ] || { echo FAIL; exit 1; }
  echo OK; exit 0
fi

f=$(jq -r '.tool_input.file_path // empty')
[ -n "$f" ] && [ -f "$f" ] || exit 0

run_prettier() {
  if command -v prettier >/dev/null 2>&1; then command prettier --write "$f"
  elif command -v npx >/dev/null 2>&1; then npx --no-install prettier --write "$f"
  else echo "autoformat: prettier not installed, skipping $f" >&2
  fi
}

case "$f" in
  *.json|*.js|*.ts|*.jsx|*.tsx|*.md) run_prettier ;;
  *.sh)
    command -v shfmt >/dev/null 2>&1 && shfmt -w "$f" || echo "autoformat: shfmt not installed, skipping $f" >&2
    ;;
  *.py)
    if command -v ruff >/dev/null 2>&1; then ruff format "$f"
    elif command -v black >/dev/null 2>&1; then black "$f"
    else echo "autoformat: ruff/black not installed, skipping $f" >&2
    fi
    ;;
esac
exit 0
