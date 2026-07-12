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
| `protect-files.sh` | PreToolUse | `Edit\|Write` | Block edits to `.env`, lockfiles, `.git/` |
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
| *(osascript)* | Notification | `permission_prompt\|idle_prompt` | Desktop alert when Claude needs input (macOS) |
| `cbm-session-reminder.sh` | SessionStart | `startup\|resume\|clear\|compact` | Re-inject the code-discovery protocol |

Audit logs land in `.claude/logs/` (gitignored). Override the log dir with
`CLAUDE_HOOK_LOGDIR` (used by the self-checks so they write to a tempdir).

## Notification portability

The `Notification` hook (issue #13) is registered with macOS `osascript`. On
Linux swap the command for `notify-send 'Claude Code' 'Claude Code needs your
attention'`; on Windows use a PowerShell `MessageBox`.

> A `PermissionRequest` auto-approve hook was considered (issue #18) and
> dropped: auto-approving `ExitPlanMode` removes the human plan-review gate,
> which contradicts the human-in-the-loop intent of this repo.

## Testing

```bash
bash .claude/hooks/test-hooks.sh        # run every hook's --selfcheck
bash scripts/ci-checks.sh               # whole-tree checks + the above
echo '{"tool_input":{"file_path":".env"}}' | .claude/hooks/protect-files.sh; echo $?  # expect 2
```

Debug a live session with `claude --debug-file /tmp/claude.log` then
`tail -f /tmp/claude.log`, or `/hooks` to see what's registered.
