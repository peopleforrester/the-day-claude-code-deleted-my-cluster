# Hooks: install this on your own machine

**Synced from a live working configuration on 2026-09-10, and verified against
the agent's published hook reference the same day.** If you are reading this
much later, check the dates below before trusting the event names: this surface
moves fast, and the previous version of this file was four months stale and
wrong about it.

These are the actual scripts behind [`docs/the-framework.md`](../docs/the-framework.md)
and the talk. Paths, hostnames and usernames are replaced with `$HOME`, `$USER`
and neutral placeholders; read each script before running it.

You already know CI. The extra for AI agents lives here.

## Layout

```
hooks/
├── claude-code/   agent lifecycle hooks
└── git/           pre-commit + pre-push (tiered local enforcement)
../workflows/      ci.yml (defense in depth for anyone without local hooks)
```

## Read this before copying anything

Three things changed since the first version of this material, and all three
matter more than the scripts themselves.

### 1. There are 33 lifecycle events, not 8

The set below is what these scripts use. It is a small slice. The events worth
knowing about for enforcement work, which did not exist in the earlier material:

| Event | Why it matters |
|---|---|
| `PermissionRequest` | Fires when a call needs a permission decision, so a policy layer can answer it. Note it does **not** honor exit code 2; it needs a JSON decision. |
| `PermissionDenied` | Fires when auto mode denies a call. Good audit surface for what the agent tried. |
| `ConfigChange` | **Blocks a configuration change mid-session**, which closes the "agent edits its own guardrails" hole. Note the exception: it cannot block `policy_settings`. |
| `PreModelSwitch` | Blocks a model switch. |
| `SubagentStart` | Spawn-time control, not only stop-time. |
| `PostToolUseFailure`, `PostToolBatch` | Separate the failure path and the parallel-batch path from the success path. |
| `InstructionsLoaded` | Fires when a CLAUDE.md or rules file loads. |
| `WorktreeCreate` | Aborts on **any** non-zero exit, unlike every other event. |

### 2. A hook is not necessarily a shell script any more

`type` now takes:

| `type` | What decides | Deterministic? |
|---|---|---|
| `command` | your shell script | **yes**, the harness enforces the verdict |
| `http` | a remote endpoint | only as much as that endpoint is |
| `mcp_tool` | an MCP tool call | depends on the tool |
| `prompt` | a model, Haiku by default | **no** |
| `agent` | a subagent | **no** |

Every script here is `type: command`, deliberately. If you are building
guardrails, know that choosing `prompt` or `agent` puts a probabilistic judgment
in the enforcement path, which is the exact thing this talk argues against. That
is sometimes the right call. It should be a decision, not an accident.

### 3. The output contract is structured JSON

Exit codes still work (`0` fine, `2` blocks, anything else is a non-blocking
error) and every script here uses them. The richer form is JSON on stdout:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Command not allowed"
  }
}
```

`PreToolUse` also accepts **`updatedInput`**, which **rewrites the tool call**
instead of only allowing or denying it. In Kubernetes terms the earlier material
described a validating admission controller; a mutating one is now available too.

Config also gained an `if` filter, so the script no longer has to re-parse the
command to decide whether it cares:

```json
{ "type": "command", "if": "Bash(git *)", "command": "..." }
```

## 1. Agent lifecycle hooks, to `~/.claude/hooks/`

| Script | Event | Purpose | How it is bypassed |
|---|---|---|---|
| `session-start.sh` | SessionStart | Detect pending work in `PROJECT_STATE.md` plus uncommitted changes; emit a directive to reconcile before editing | Advisory. The model can ignore the directive |
| `check-commit-message.sh` | PreToolUse (Bash) | Block a commit whose message carries AI attribution | `--no-verify`; `core.hooksPath=/dev/null`; committing without the CLI; **and see the heredoc defect below** |
| `block-sensitive-files.sh` | PreToolUse (Edit\|Write) | Exit 2 on writes to `.env`, `*.pem`, `*.key`, `id_*`, `*credential*`, `*secret*` | A `Bash` redirect writes the same file without touching Edit or Write. Pattern evasion |
| `enforce-prd-issue-first.sh` | PreToolUse (Edit\|Write) | Require a tracking issue before a spec file is created | Same Bash-redirect gap |
| `validate-file.sh` | PostToolUse (Edit\|Write) | Ruff and yamllint on every write | Post hoc. The write already happened. Non-Python, non-YAML files skip |
| `check-aboutme.sh` | PostToolUse (Edit\|Write) | Warn when a file is missing its `ABOUTME:` header | Warn only |
| `check-rule-frontmatter.sh` | PostToolUse (Edit\|Write) | Validate frontmatter on rule files | Warn only |
| `cascade-decision-check.sh` | PostToolUse (Edit\|Write) | Flag edits that should have been recorded as a decision | Warn only |
| `auto-reanchor.sh` | PostCompact | Re-read context after compaction and surface an orientation block | Reorientation, not enforcement |
| `auto-test-on-stop.sh` | Stop | Run the project's tests when a turn ends | Non-blocking. Failures do not roll anything back |

### A defect worth studying, in `check-commit-message.sh`

It is published **as it is**, defect included, because it is a better teaching
artifact that way.

The script tries to scan only the commit message rather than the whole command.
It finds the heredoc delimiter with `head -1`, which takes the **first** heredoc
in the command. A very common shape is a file write followed by a commit:

```bash
cat > notes.md <<'EOF'
...file content...
EOF
git commit -m "$(cat <<'EOF'
message
EOF
)"
```

Here the delimiter resolves against the **file-writing** heredoc, so the file
body gets scanned and **the real commit message is never examined**. That is a
bypass, and it is invisible: the hook reports success.

The lesson generalises past this script. **A control that parses a command
string is guessing.** The reliable version anchors on the invocation, or runs
where the action actually happens, which is why Layer 1 and Layer 2 sit above
this one.

### Install

```bash
mkdir -p ~/.claude/hooks
cp hooks/claude-code/*.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh
```

Then wire them up in `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [{"hooks": [{"type": "command", "command": "~/.claude/hooks/session-start.sh"}]}],
    "PreToolUse": [
      {"matcher": "Bash",       "hooks": [{"type": "command", "command": "~/.claude/hooks/check-commit-message.sh"}]},
      {"matcher": "Edit|Write", "hooks": [
        {"type": "command", "command": "~/.claude/hooks/block-sensitive-files.sh"},
        {"type": "command", "command": "~/.claude/hooks/enforce-prd-issue-first.sh"}
      ]}
    ],
    "PostToolUse": [
      {"matcher": "Edit|Write", "hooks": [
        {"type": "command", "command": "~/.claude/hooks/validate-file.sh"},
        {"type": "command", "command": "~/.claude/hooks/check-aboutme.sh"},
        {"type": "command", "command": "~/.claude/hooks/check-rule-frontmatter.sh"},
        {"type": "command", "command": "~/.claude/hooks/cascade-decision-check.sh"}
      ]}
    ],
    "PostCompact": [{"hooks": [{"type": "command", "command": "~/.claude/hooks/auto-reanchor.sh"}]}],
    "Stop":        [{"hooks": [{"type": "command", "command": "~/.claude/hooks/auto-test-on-stop.sh"}]}]
  }
}
```

Restart the agent. `session-start.sh` fires on entry; the rest fire on their
events.

### Deliberately not published

Three hooks from the working set are held back, so you know they exist rather
than wondering what was cut:

- `harvest-journal.sh` (SessionEnd) writes into a personal notes vault. Capture,
  not enforcement.
- `confirm-gitlab-push.sh` (PreToolUse) is bound to a corporate GitLab host.
- `statusline.sh` is cosmetic.

Client-side git hooks are a speed bump, not a wall: `--no-verify` defeats both.
The wall is CI, in [`../workflows/`](../workflows/), because the agent cannot
pass `--no-verify` to GitHub Actions.

## 2. Git hooks → `<repo>/.git/hooks/`

Tiered enforcement, fail-fast, language-aware. Detects Python /
Node / Rust / Go by config files at the repo root and runs the
appropriate linters and tests.

| Hook | Tier | Runs | Bypass |
|---|---|---|---|
| `pre-commit` | 1 | Fast lint + type check on **staged files only** (<5s target). Docs-only commits skip lint entirely. Per-repo opt-outs: `.skip-lint`, `.skip-typecheck` | `git commit --no-verify` |
| `pre-push` (any branch) | 2 | Secret scan (AKIA, ghp_*, sk-*, BEGIN PRIVATE KEY) + unit tests. `.skip-unit-tests` opts out | `git push --no-verify` |
| `pre-push` (main only) | 3 | e2e gate: Python `tests/e2e/`, Node `test:e2e` script, or `scripts/e2e-test.sh`. `.skip-e2e` opts out. `.direct-push-allowed` skips all pre-push checks | Admin force-push on a protected branch |

### Install (per repo)

```bash
cp hooks/git/pre-commit  /path/to/your-repo/.git/hooks/
cp hooks/git/pre-push    /path/to/your-repo/.git/hooks/
chmod +x /path/to/your-repo/.git/hooks/pre-{commit,push}
```

`.git/hooks/` is per-clone and not under version control. Re-install
after every `git clone`. Pair with `core.hooksPath` set to a tracked
directory if you want them versioned across the team.

## 3. GitHub Actions workflow → `<repo>/.github/workflows/`

Defense in depth for anyone who pushes without the local hooks
installed. See [`../workflows/ci.yml`](../workflows/ci.yml). Drop it
into your repo's `.github/workflows/` and adapt the test command to
your runner.

## What gets past all of this

Read [`../docs/the-framework.md`](../docs/the-framework.md) for the
full bypass column per artifact. Stacking layers is the point:
no single hook is unbypassable, but compromising the whole stack
requires multiple distinct moves at once.

## License

These scripts are MIT-licensed for free reuse (the talk repo
overall is CC BY 4.0 for prose; code artifacts are MIT). Steal
them, adapt them, ship them.
