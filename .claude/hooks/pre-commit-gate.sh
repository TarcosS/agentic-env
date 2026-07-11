#!/bin/bash
# PreToolUse Bash (if: git commit): run the canonical whole-tree checks.
# Exit 2 blocks the commit so Claude never creates a red-CI commit.
"${CLAUDE_PROJECT_DIR:-.}/scripts/ci-checks.sh" >&2 || {
  echo "Commit blocked: checks failed (see above). Fix, then retry." >&2
  exit 2
}
exit 0
