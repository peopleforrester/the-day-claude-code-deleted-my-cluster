#!/bin/bash
# ABOUTME: PreToolUse hook that blocks git commits containing AI/Claude references.
# ABOUTME: Enforces professional commit messages by scanning for attribution patterns.
#
# HOW THIS HOOK WORKS:
# =====================
# Claude Code runs this script BEFORE every Bash tool call executes.
# It receives JSON on stdin describing what Claude wants to do:
#   {"tool_name": "Bash", "tool_input": {"command": "git commit -m 'message'"}}
#
# The hook extracts ONLY the commit message (from -m, heredoc, or --message)
# and checks for references to Claude, Claude Code, AI, Anthropic, or similar
# attribution. If found, it blocks the commit by exiting with code 2 and
# suggests a corrected message. File paths in the command are not scanned.
#
# EXIT CODES:
#   0 = allow the command to proceed
#   2 = BLOCK the command (Claude sees the error message and cannot execute it)
#
# WHAT IT CATCHES:
#   - "Claude Code", "Claude", "Anthropic" (case-insensitive)
#   - "Generated with", "Co-Authored-By.*Claude", "AI assistant"
#   - "LLM", "language model" in commit context
#
# PRODUCT-NAME ALLOWLIST:
#   Some real product/project names contain otherwise-flagged tokens (e.g.
#   "LLM Guard" by ProtectAI, the "llm-coding-workflow" repo). The hook
#   pre-scrubs these from the message before pattern matching so they do not
#   false-positive. Add to PRODUCT_ALLOWLIST below when a legitimate commit
#   gets blocked on a product name.
#
# REGISTERED IN: ~/.claude/settings.json under hooks.PreToolUse
# MATCHER: "Bash" (only runs for Bash tool calls)

# --- Step 1: Read the JSON input from Claude Code ---
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# --- Step 2: Only process Bash tool calls ---
if [ "$TOOL_NAME" != "Bash" ]; then
    exit 0
fi

# --- Step 3: Extract the command ---
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# --- Step 4: Find the commit's own message, heredoc-aware ---
#
# Deciding what to scan by pattern-matching the raw command failed three ways
# (llm-coding-workflow#154), all reproduced:
#
#   1. The delimiter was taken with `head -1` from anywhere in the command, so
#      a decoy heredoc earlier in the line supplied the scanned text.
#   2. Because of (1) it FAILED OPEN: attribution in the real message passed
#      whenever another heredoc came first.
#   3. It fired on commands running no git at all, because the literal string
#      `git commit` appeared inside a heredoc body as documentation. That one
#      blocked a `cat` writing these very tests on 2026-09-24.
#
# The helper walks the command tracking heredoc extent, so a line is known to
# be shell or body and only shell lines can carry an invocation. It ships in
# lib/ beside this script, as the attribution library does (hooks/README.md).
# Synced from the live working set on 2026-10-31 (#38), when the copy published
# here still took the first delimiter; that version is in the history at
# 3c3cb28, the commit tagged delivered/devopsdays-portland-2026.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTRACT="${SCRIPT_DIR}/lib/extract_commit_message.py"

if [ ! -f "$EXTRACT" ]; then
    echo "check-commit-message.sh: cannot find $EXTRACT — refusing to skip the AI-attribution check silently." >&2
    exit 2
fi

set +e
MSG=$(printf '%s' "$COMMAND" | python3 "$EXTRACT")
EXTRACT_STATUS=$?
set -e

case "$EXTRACT_STATUS" in
    1) exit 0 ;;   # no git commit in this command
    2) exit 0 ;;   # a commit runs but carries no inline message (editor, -F file)
    0) ;;
    *)
        echo "check-commit-message.sh: message extraction failed (status $EXTRACT_STATUS)." >&2
        exit 2
        ;;
esac

if [ -z "$MSG" ]; then
    exit 0
fi

# --- Steps 6-7: Product-name scrub + AI/Claude pattern check ---
# The pattern list lives in lib/check-ai-attribution.sh, shared with the native
# git commit-msg hook in the live set so the two enforcement points can never
# drift onto different pattern lists. It ships beside this script; install the
# lib/ directory with it (hooks/README.md).
#
# Until 2026-10-31 this looked for ../../scripts/git-hooks/lib/, the path in the
# working set it was synced from. Nothing at that path was published, so an
# installed copy refused every commit whose message it could read (#18).
LIB="${SCRIPT_DIR}/lib/check-ai-attribution.sh"
if [ -f "$LIB" ]; then
    # shellcheck source=/dev/null
    source "$LIB"
    if ! RESULT=$(check_ai_attribution "$MSG"); then
        echo "$RESULT" >&2
        exit 2
    fi
else
    echo "check-commit-message.sh: cannot find $LIB — refusing to skip the AI-attribution check silently." >&2
    exit 2
fi

# --- Step 8: Issue-link convention (PRD 39 M2) ---
# Every non-trivial commit should name the milestone issue it moves, so
# "which commits moved this spec forward" is a lookup rather than a guess.
#
# WARN ONLY for now, deliberately. A gate at full strength on day one teaches
# the --no-verify reflex, and this repo has already reached for it under load.
# The flip to blocking happens after the adoption rate is measured; see
# scripts/commit-link-rate.sh. Set COMMIT_LINK_ENFORCE=1 to block early.
#
# Accepted forms:
#   Issue #12          the milestone this commit moves
#   Closes #12         same, and closes it
#   Trivial: <reason>  the explicit hatch, for typos and comment tweaks
if [ -n "$MSG" ]; then
    if ! grep -qiE '(^|[^a-z])(issue|closes|fixes|refs) +#[0-9]+' <<< "$MSG"; then
        if ! grep -qE '^[[:space:]]*Trivial:[[:space:]]*\S' <<< "$MSG"; then
            echo "No issue link. Add a trailer naming the milestone this commit moves:" >&2
            echo "" >&2
            echo "    Issue #<n>          the milestone issue" >&2
            echo "    Trivial: <reason>   for a typo, comment, or formatting change" >&2
            echo "" >&2
            echo "Warning only for now; this becomes a block once adoption is measured." >&2
            if [ -n "${COMMIT_LINK_ENFORCE:-}" ]; then
                exit 2
            fi
        fi
    fi
fi

# Commit message is clean - allow it
exit 0
