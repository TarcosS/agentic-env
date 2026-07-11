#!/bin/bash
# Whole-tree checks. Single source of truth for CI and the pre-commit hook.
# Mirrors the checks in .github/workflows/ci.yml. Exit non-zero if anything fails.
set -u
fail=0

# JSON valid
while IFS= read -r -d '' f; do
  python3 -m json.tool "$f" >/dev/null 2>&1 || { echo "invalid JSON: $f" >&2; fail=1; }
done < <(find . -name '*.json' -not -path './.git/*' -print0)

# Shell syntax
while IFS= read -r -d '' f; do
  bash -n "$f" 2>/dev/null || { echo "shell syntax error: $f" >&2; fail=1; }
done < <(find . -name '*.sh' -not -path './.git/*' -print0)

# Python compiles
while IFS= read -r -d '' f; do
  python3 -m py_compile "$f" 2>/dev/null || { echo "py compile error: $f" >&2; fail=1; }
done < <(find . -name '*.py' -not -path './.git/*' -print0)

exit $fail
