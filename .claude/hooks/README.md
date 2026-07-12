# SDLC hooks

Deterministic guardrails, automation, and audit wired into the Claude Code
[hooks lifecycle](https://code.claude.com/docs/en/hooks-guide). Registered in
`.claude/settings.json`. Each script reads the event JSON on stdin and blocks
via exit 2 / structured JSON, or logs / injects context. Every script also
supports a `--selfcheck` mode; `test-hooks.sh` runs them all and is called by
`scripts/ci-checks.sh`, so a broken hook fails CI and the commit gate.

## Registered hooks

| Script | Event | Matcher | Does |
| :-- | :-- | :-- | :-- |
| `cbm-code-discovery-gate.sh` | PreToolUse | `Grep\|Glob` | Nudge toward codebase-memory-mcp before raw text search |
| `protect-files.sh` | PreToolUse | `Edit\|Write` | Block edits to `.env`, lockfiles, `.git/`, `settings.json` |
| `pre-commit-gate.sh` | PreToolUse | `Bash` + `if: Bash(git commit *)` | Block a commit when `ci-checks.sh` is red |
| `block-dangerous-bash.sh` | PreToolUse | `Bash` | Block `rm -rf /`, force-push to main, pipe-to-shell, etc. |
| `validate-edit.sh` | PostToolUse | `Edit\|Write` | Validate the edited file (JSON/shell/Python), block on error |
| `autoformat.sh` | PostToolUse | `Edit\|Write` | Format the edited file (prettier/shfmt/ruff) if installed; never blocks |
| `prompt-context.sh` | UserPromptSubmit | — | Inject branch, dirty files, recent commits, active rules |
| `stop-ci-gate.sh` | Stop | — | Re-run `ci-checks.sh` at turn end; soft-block if red |
| *(inline)* | Stop | — | Prompt hook: LLM checks all requested tasks are complete |
| `subagent-audit.sh` | SubagentStart / SubagentStop | — | Append a JSONL record per subagent event |
| `configchange-audit.sh` | ConfigChange | — | Log settings/skills changes (JSONL) |
| `session-end.sh` | SessionEnd | — | Log session end + clean `/tmp/claude-scratch-*` |
| `cbm-session-reminder.sh` | SessionStart | `startup\|resume\|clear\|compact` | Re-inject the code-discovery protocol |

Audit logs land in `.claude/logs/` (gitignored). Override the log dir with
`CLAUDE_HOOK_LOGDIR` (used by the self-checks so they write to a tempdir).

## Not auto-registered (need your approval)

Two hooks change the agent's own permission surface, so they are left for you
to add to a settings file directly (the auto-mode classifier blocks the agent
from self-applying them).

**`auto-approve.sh` — PermissionRequest (issue #18).** Auto-approves only
`ExitPlanMode`. Add to `.claude/settings.json` under `"hooks"`:

```json
"PermissionRequest": [
  {
    "matcher": "ExitPlanMode",
    "hooks": [
      { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/auto-approve.sh" }
    ]
  }
]
```

**Desktop notification (issue #13).** Machine-local, so it belongs in
`~/.claude/settings.json`, not this repo:

```json
"Notification": [
  {
    "matcher": "permission_prompt|idle_prompt",
    "hooks": [
      { "type": "command", "command": "osascript -e 'display notification \"Claude Code needs your attention\" with title \"Claude Code\"'" }
    ]
  }
]
```
Linux: `notify-send 'Claude Code' '...'`. Windows: PowerShell `MessageBox`.

## Testing

```bash
bash .claude/hooks/test-hooks.sh        # run every hook's --selfcheck
bash scripts/ci-checks.sh               # whole-tree checks + the above
echo '{"tool_input":{"file_path":".env"}}' | .claude/hooks/protect-files.sh; echo $?  # expect 2
```

Debug a live session with `claude --debug-file /tmp/claude.log` then
`tail -f /tmp/claude.log`, or `/hooks` to see what's registered.
