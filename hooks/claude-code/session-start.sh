#!/usr/bin/env bash
# ABOUTME: SessionStart hook — syncs with origin, detects pending work and uncommitted changes, re-anchors after compaction.
# ABOUTME: Pulls-when-safe so cross-machine work starts from latest; reports what PROJECT_STATE.md holds.

set -euo pipefail

# ---------------------------------------------------------------------------
# Read hook input (JSON on stdin)
# ---------------------------------------------------------------------------
INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
# startup, resume, clear or compact. SessionStart is the only event that can
# put text in context after a compaction: PostCompact cannot add context, and
# stderr from a hook that exits 0 never reaches the model
# (llm-coding-workflow#332, which retired auto-reanchor.sh for this block).
SOURCE=$(echo "$INPUT" | jq -r '.source // empty')

if [ -z "$CWD" ]; then
    exit 0
fi

# Claude Code caps hook output at 10,000 characters per string; past that the
# model gets a file path and a preview it is not asked to read. Stay under it.
MAX_OUTPUT_CHARS=9000

# ---------------------------------------------------------------------------
# Opt-out: .skip-session-resume suppresses the directive for this repo
# ---------------------------------------------------------------------------
if [ -f "$CWD/.skip-session-resume" ]; then
    exit 0
fi

# ---------------------------------------------------------------------------
# Detect pending state
# ---------------------------------------------------------------------------
FINDINGS=()
# The closing line, stated as a fact: the hooks docs warn that text framed as
# an out-of-band command can trip prompt-injection defenses and be surfaced to
# the user instead of used as context (llm-coding-workflow#321). Empty without
# PROJECT_STATE.md.
RESUME_LINE=""

# ---------------------------------------------------------------------------
# Sync-on-session-start — fetch origin and pull when it's safe, so work on
# any machine starts from the latest commit. This is the "pull before you do
# anything" discipline, automated.
#
# Safety contract:
#   - Opt out per-repo with a .skip-session-sync file.
#   - Auto-pull ONLY when the working tree is clean AND the update is a
#     fast-forward (clean ff can never lose local work). Otherwise just warn.
#   - fetch is timeout-capped and every git call is non-fatal — the hook
#     always degrades to a finding, never blocks or fails the session.
#   - Never operates outside a git work tree.
# ---------------------------------------------------------------------------
if [ ! -f "$CWD/.skip-session-sync" ] && \
   git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1 && \
   git -C "$CWD" remote get-url origin >/dev/null 2>&1; then
    if command -v timeout >/dev/null 2>&1; then
        timeout 15 git -C "$CWD" fetch --quiet origin 2>/dev/null || true
    else
        git -C "$CWD" fetch --quiet origin 2>/dev/null || true
    fi
    UPSTREAM=$(git -C "$CWD" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
    if [ -n "$UPSTREAM" ]; then
        BEHIND=$(git -C "$CWD" rev-list --count 'HEAD..@{u}' 2>/dev/null || echo 0)
        if [ "${BEHIND:-0}" -gt 0 ]; then
            CLEAN=$(git -C "$CWD" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
            if [ "${CLEAN:-1}" -eq 0 ] && \
               git -C "$CWD" merge-base --is-ancestor HEAD '@{u}' 2>/dev/null; then
                if git -C "$CWD" pull --ff-only --quiet 2>/dev/null; then
                    FINDINGS+=("Auto-pulled $BEHIND commit(s) from $UPSTREAM (clean fast-forward)")
                else
                    FINDINGS+=("BEHIND $UPSTREAM by $BEHIND — PULL before editing")
                fi
            else
                FINDINGS+=("BEHIND $UPSTREAM by $BEHIND commit(s) — PULL/rebase before editing (tree dirty or not fast-forward)")
            fi
        fi
    fi
fi

# ---------------------------------------------------------------------------
# Reconcile the assembled config directories with the tracked config.
#
# The auto-pull above brings new rules and skills onto this machine, but
# ~/.claude/{rules,skills} are assembled directories of symlinks, so a pulled
# file never appears until the assembly re-runs. That gap is silent: the drift
# check deliberately excludes both, because they are real directories by design.
#
# Repairs only a directory the assembly generated (marker present) and never
# fails the session. Anything else is reported and left alone.
# ---------------------------------------------------------------------------
# cd -P resolves the symlink: ~/.claude/hooks points into claude-config/hooks,
# so a plain dirname would walk up from ~/.claude and miss the repo entirely.
HOOK_REAL="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
RECONCILE="$HOOK_REAL/../../scripts/reconcile-assembly.sh"
if [ -f "$RECONCILE" ]; then
    while IFS= read -r line; do
        [ -n "$line" ] && FINDINGS+=("config assembly: $line")
    done < <(bash "$RECONCILE" 2>/dev/null || true)
fi

# Check PROJECT_STATE.md for lifecycle phase + pending tasks
if [ -f "$CWD/PROJECT_STATE.md" ]; then
    # Lead with current phase if present (lifecycle-phases schema)
    PHASE_LINE=$(grep -m1 '^Phase: ' "$CWD/PROJECT_STATE.md" 2>/dev/null | sed 's/^Phase: //' || true)
    if [ -n "$PHASE_LINE" ]; then
        FINDINGS+=("Resuming in Phase $PHASE_LINE")
    else
        # Pre-lifecycle PROJECT_STATE.md. Per state-persistence rule
        # this MUST be migrated before non-trivial work.
        FINDINGS+=("PROJECT_STATE.md predates the lifecycle schema. Run /init-state to auto-migrate (mandatory).")
    fi

    PENDING_COUNT=$(grep -c '^\- \[ \]' "$CWD/PROJECT_STATE.md" 2>/dev/null || true)
    if [ "$PENDING_COUNT" -gt 0 ]; then
        RESUME_LINE="PROJECT_STATE.md has $PENDING_COUNT pending tasks; /continue resumes from it."
    else
        RESUME_LINE="PROJECT_STATE.md has no pending tasks; /continue resumes from it."
    fi
    if [ "$PENDING_COUNT" -gt 0 ]; then
        # Extract the next step line if present
        NEXT_STEP=$(grep -A1 '^\*\*Next step\*\*' "$CWD/PROJECT_STATE.md" 2>/dev/null | tail -1 | sed 's/^- //' || true)
        if [ -n "$NEXT_STEP" ]; then
            FINDINGS+=("PROJECT_STATE.md: $PENDING_COUNT pending tasks. Next: $NEXT_STEP")
        else
            FINDINGS+=("PROJECT_STATE.md: $PENDING_COUNT pending tasks")
        fi
    fi
elif git -C "$CWD" rev-parse --git-dir > /dev/null 2>&1; then
    # Repo with no PROJECT_STATE.md at all. Recommend bootstrap before
    # non-trivial work per state-persistence rule.
    FINDINGS+=("No PROJECT_STATE.md found. Run /init-state to bootstrap (or proceed if this is a trivial one-off).")
fi

# Check for Ralph loop state
if [ -f "$CWD/.claude/ralph-loop.local.md" ]; then
    FINDINGS+=("Ralph loop state detected (.claude/ralph-loop.local.md)")
fi

# Check for tasks.yaml state
if [ -f "$CWD/tasks.yaml" ] && command -v yq >/dev/null 2>&1; then
    INTERRUPTED_COUNT=$(yq '[.tasks[] | select(.status == "interrupted")] | length' "$CWD/tasks.yaml" 2>/dev/null || echo "0")
    READY_COUNT=$(yq '[.tasks[] | select(.status == "ready")] | length' "$CWD/tasks.yaml" 2>/dev/null || echo "0")
    CLAIMED_COUNT=$(yq '[.tasks[] | select(.status == "claimed")] | length' "$CWD/tasks.yaml" 2>/dev/null || echo "0")
    if [ "$INTERRUPTED_COUNT" -gt 0 ]; then
        INTERRUPTED_TITLES=$(yq '.tasks[] | select(.status == "interrupted") | .id + " — " + .title' "$CWD/tasks.yaml" 2>/dev/null || true)
        FINDINGS+=("tasks.yaml: $INTERRUPTED_COUNT interrupted task(s): $INTERRUPTED_TITLES")
    fi
    if [ "$CLAIMED_COUNT" -gt 0 ]; then
        FINDINGS+=("tasks.yaml: $CLAIMED_COUNT task(s) still claimed from previous session")
    fi
    if [ "$READY_COUNT" -gt 0 ]; then
        FINDINGS+=("tasks.yaml: $READY_COUNT task(s) ready to work on")
    fi
fi

# Check for uncommitted changes
if git -C "$CWD" rev-parse --git-dir > /dev/null 2>&1; then
    DIRTY_COUNT=$(git -C "$CWD" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if [ "$DIRTY_COUNT" -gt 0 ]; then
        FINDINGS+=("$DIRTY_COUNT uncommitted/untracked files")
    fi
fi

# ---------------------------------------------------------------------------
# Config drift: the documented ~/.claude symlink set must resolve into
# claude-config. A stale plain file silently ignores every edit made to the
# repo copy, which is how a registered hook can never fire. Loud every session
# until fixed, never blocking: the check's own exit status is discarded.
# ---------------------------------------------------------------------------
DRIFT_CHECK="$HOME/repos/workflow/llm-coding-workflow/scripts/check-config-drift.sh"
if [ -x "$DRIFT_CHECK" ]; then
    DRIFT_OUT=$("$DRIFT_CHECK" --quiet 2>&1) || true
    if [ -n "$DRIFT_OUT" ]; then
        FINDINGS+=("CONFIG DRIFT detected — the repo is not the source of truth for some ~/.claude paths. Run scripts/check-config-drift.sh for detail.")
    fi
fi

# ---------------------------------------------------------------------------
# Re-anchor after a compaction: the summary that replaced the conversation can
# drop the rules and the state, so name where they live and what was in hand.
# Stated as facts, not a command (llm-coding-workflow#321).
# ---------------------------------------------------------------------------
REANCHOR=""
if [ "$SOURCE" = "compact" ] && \
   git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    RA_ROOT=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null || echo "$CWD")
    RA_BRANCH=$(git -C "$RA_ROOT" branch --show-current 2>/dev/null || true)
    RA_RECENT=$(git -C "$RA_ROOT" log --oneline -3 2>/dev/null || true)
    # Captured first, then cut: under pipefail `git status | head` kills git
    # with SIGPIPE on a very dirty tree (#34 here, llm-coding-workflow#482 live).
    RA_STATUS=$(git -C "$RA_ROOT" status --short 2>/dev/null || true)
    RA_DIRTY=$(head -10 <<< "$RA_STATUS")
    RA_GUIDANCE=""
    for f in AGENTS.md CLAUDE.md; do
        [ -f "$RA_ROOT/$f" ] && RA_GUIDANCE="$RA_GUIDANCE $f"
    done
    [ -f "$RA_ROOT/PROJECT_STATE.md" ] && RA_GUIDANCE="$RA_GUIDANCE PROJECT_STATE.md"
    RA_NEXT=""
    if [ -f "$RA_ROOT/PROJECT_STATE.md" ]; then
        RA_NEXT=$(grep -A1 '^\*\*Next step\*\*' "$RA_ROOT/PROJECT_STATE.md" 2>/dev/null | tail -1 | sed 's/^- //' || true)
    fi
    RA_TASK=""
    if [ -f "$RA_ROOT/tasks.yaml" ] && command -v yq >/dev/null 2>&1; then
        RA_CLAIMED=$(yq '.tasks[] | select(.status == "claimed") | .id + " — " + .title' "$RA_ROOT/tasks.yaml" 2>/dev/null || true)
        RA_INTERRUPTED=$(yq '.tasks[] | select(.status == "interrupted") | .id + " — " + .title' "$RA_ROOT/tasks.yaml" 2>/dev/null || true)
        if [ -n "$RA_CLAIMED" ]; then
            RA_TASK="Active task in tasks.yaml (claimed): $RA_CLAIMED"
        elif [ -n "$RA_INTERRUPTED" ]; then
            RA_TASK="Interrupted task in tasks.yaml: $RA_INTERRUPTED"
        fi
    fi

    REANCHOR="Re-anchor after compaction:"
    REANCHOR="$REANCHOR"$'\n'"  Repo: $(basename "$RA_ROOT") | Branch: ${RA_BRANCH:-detached}"
    REANCHOR="$REANCHOR"$'\n'"  Recent commits:"$'\n'"$(printf '%s\n' "${RA_RECENT:-none}" | sed 's/^/    /')"
    if [ -n "$RA_DIRTY" ]; then
        REANCHOR="$REANCHOR"$'\n'"  Dirty files:"$'\n'"$(printf '%s\n' "$RA_DIRTY" | sed 's/^/    /')"
    else
        REANCHOR="$REANCHOR"$'\n'"  Working tree clean"
    fi
    [ -n "$RA_NEXT" ] && REANCHOR="$REANCHOR"$'\n'"  Next step: $RA_NEXT"
    [ -f "$RA_ROOT/_execution-state.md" ] && \
        REANCHOR="$REANCHOR"$'\n'"  _execution-state.md holds an active plan execution."
    [ -n "$RA_TASK" ] && REANCHOR="$REANCHOR"$'\n'"  $RA_TASK"
    if [ -n "$RA_GUIDANCE" ]; then
        REANCHOR="$REANCHOR"$'\n'"  The compaction summary replaced the conversation; the rules and state it may have dropped are in:$RA_GUIDANCE."
    fi
fi

# ---------------------------------------------------------------------------
# If no state found, exit silently
# ---------------------------------------------------------------------------
if [ ${#FINDINGS[@]} -eq 0 ] && [ -z "$REANCHOR" ]; then
    exit 0
fi

# ---------------------------------------------------------------------------
# Build the message
# ---------------------------------------------------------------------------
MESSAGE=""
if [ ${#FINDINGS[@]} -gt 0 ]; then
    SUMMARY="Session state detected:"
    for finding in "${FINDINGS[@]}"; do
        SUMMARY="$SUMMARY\n  - $finding"
    done

    MESSAGE="$SUMMARY"
    if [ -n "$RESUME_LINE" ]; then
        MESSAGE="$MESSAGE\n\n$RESUME_LINE"
    fi
    MESSAGE=$(echo -e "$MESSAGE")
fi

# The re-anchor goes first, so the cap below trims the routine findings, not it.
PARTS=()
[ -n "$REANCHOR" ] && PARTS+=("$REANCHOR")
[ -n "$MESSAGE" ] && PARTS+=("$MESSAGE")
OUTPUT=""
for part in "${PARTS[@]}"; do
    [ -n "$OUTPUT" ] && OUTPUT="$OUTPUT"$'\n\n'
    OUTPUT="$OUTPUT$part"
done

if [ ${#OUTPUT} -gt "$MAX_OUTPUT_CHARS" ]; then
    OUTPUT="${OUTPUT:0:$((MAX_OUTPUT_CHARS - 40))}"$'\n'"[session-start output truncated]"
fi

# Output as plain text (SessionStart hooks add this as context)
printf '%s\n' "$OUTPUT"

exit 0
