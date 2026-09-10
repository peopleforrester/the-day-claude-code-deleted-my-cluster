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

# --- Step 4: Only check git commit commands ---
# Match "git commit" anywhere in the command (handles chained commands with &&)
if ! echo "$COMMAND" | grep -qE 'git\s+commit'; then
    exit 0  # Not a git commit - allow it
fi

# --- Step 5: Extract the commit message, not the full command ---
# The full command may contain file paths (e.g., git add claude-config/)
# that would false-positive on pattern matching. Extract only the message.
MSG=""

# Heredoc style, any delimiter: git commit -F - <<'MSG' ... MSG
#
# This matched only the literal word EOF until 2026-08-16, so a commit written
# with any other delimiter was never examined and the attribution rule below
# silently did not apply to it. The delimiter is now read from the redirection
# itself and the body is taken up to the line that closes it.
DELIM=$(echo "$COMMAND" | grep -oP "<<-?\s*['\"]?\K[A-Za-z_][A-Za-z0-9_]*" | head -1)
if [ -n "$DELIM" ]; then
    MSG=$(echo "$COMMAND" | awk -v d="$DELIM" '
        !found && $0 ~ ("<<-?[[:space:]]*[\"'\'']?" d "[\"'\'']?[[:space:]]*$") { found=1; next }
        found && $0 ~ ("^[[:space:]]*" d "[[:space:]]*$") { found=0; next }
        found { print }
    ')
fi

# -m "message" or -m 'message' style (if heredoc extraction found nothing)
#
# -z plus (?s) so the match spans newlines. Without it, grep worked line by line
# and `head -1` kept only the first line, so every line after the subject of a
# multi-line -m message went unchecked.
if [ -z "$MSG" ]; then
    MSG=$(printf '%s' "$COMMAND" \
        | grep -ozP "(?s)git\s+commit\s+.*?-m\s+['\"]\K[^'\"]*" \
        | tr -d '\0')
fi

# --message="message" style
if [ -z "$MSG" ]; then
    MSG=$(echo "$COMMAND" | grep -oP -- "--message=['\"]?\K[^'\"]*" | head -1)
fi

# If extraction failed entirely, skip check rather than false-positive
if [ -z "$MSG" ]; then
    exit 0
fi

# --- Steps 6-7: Product-name scrub + AI/Claude pattern check ---
# Shared with the native git commit-msg hook (scripts/git-hooks/commit-msg) so
# the two enforcement points can never drift onto different pattern lists.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${SCRIPT_DIR}/../../scripts/git-hooks/lib/check-ai-attribution.sh"
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
    if ! echo "$MSG" | grep -qiE '(^|[^a-z])(issue|closes|fixes|refs) +#[0-9]+'; then
        if ! echo "$MSG" | grep -qE '^[[:space:]]*Trivial:[[:space:]]*\S'; then
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
