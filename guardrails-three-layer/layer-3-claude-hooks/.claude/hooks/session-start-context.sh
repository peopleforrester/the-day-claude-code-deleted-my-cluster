#!/usr/bin/env bash
# ABOUTME: Layer 3 SessionStart hook - inject branch, recent commits, kubectl context, and CLAUDE.md head.
# ABOUTME: stdout is auto-injected as context for the session. Flag production kubectl contexts in red.
set -euo pipefail
INPUT="$(cat)"
SRC="$(jq -r '.source' <<<"${INPUT}")"

{
    echo "=== Claude Code session (${SRC}) on $(hostname) at $(date -u +%FT%TZ) ==="

    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Git branch: $(git branch --show-current 2>/dev/null || echo detached)"
        git --no-pager log --oneline -5 2>/dev/null
    fi

    if command -v kubectl >/dev/null 2>&1; then
        KCTX="$(kubectl config current-context 2>/dev/null || echo none)"
        echo "kubectl context: ${KCTX}"
        case "${KCTX}" in
            *prod*|*production*)
                echo "!! PRODUCTION CONTEXT - treat every command as destructive."
                ;;
        esac
    fi

    if [[ -f "${CLAUDE_PROJECT_DIR}/CLAUDE.md" ]]; then
        echo "--- CLAUDE.md (first 80 lines) ---"
        head -80 "${CLAUDE_PROJECT_DIR}/CLAUDE.md"
    fi
} 2>&1

exit 0
