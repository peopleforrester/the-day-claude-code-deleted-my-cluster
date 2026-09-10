#!/bin/bash
# ABOUTME: Post-edit validation hook for Claude Code.
# ABOUTME: Validates Python syntax, formatting, indentation, line-length, and naming conventions via ruff. YAML via yamllint.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Exit silently if no file path
if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# Skip courseware repos — lab/instructional code intentionally violates
# project style (ABOUTME headers, line length, naming) and yamllint on
# course.yml produces noise without value.
case "$FILE_PATH" in
    "$HOME"/repos/courses/*) exit 0 ;;
esac

case "$FILE_PATH" in
    *.py)
        # Syntax check (fast, catches parse errors)
        python3 -m py_compile "$FILE_PATH" 2>&1

        # Style checks: indentation (4-space), line length (100), naming conventions
        # E111: indentation not a multiple of 4
        # W191: indentation contains tabs
        # E501: line too long (>100 chars)
        # N801: class names should use CapWords
        # N802: function names should be lowercase
        # N803: argument names should be lowercase
        # N806: variable in function should be lowercase
        if command -v ruff &> /dev/null; then
            ruff check --preview --select E111,W191,E501,N801,N802,N803,N806 \
                --line-length 100 "$FILE_PATH" 2>&1
        fi
        ;;
    *.yaml|*.yml)
        if command -v yamllint &> /dev/null; then
            yamllint -d relaxed "$FILE_PATH" 2>&1
        fi
        ;;
    *.md|*.adoc|*.rst)
        # A skill can be bypassed; this fires on the write itself. Only the
        # deterministic half runs here, because the semantic pass is a judgement
        # a hook cannot make. Threshold is major so ordinary prose stays quiet
        # and a warning still means something.
        # Resolved relative to this hook, not through $HOME. Both files ship in
        # claude-config, and ~/.claude/{hooks,skills} are symlinks into it, so
        # one relative path works from the repo and from the deployed tree. The
        # $HOME form silently found nothing anywhere ~/.claude was absent.
        HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        AI_ISMS="$HOOK_DIR/../skills/check-ai-isms/check.py"
        if [ -f "$AI_ISMS" ]; then
            if ! python3 "$AI_ISMS" "$FILE_PATH" --threshold=major >/dev/null 2>&1; then
                python3 "$AI_ISMS" "$FILE_PATH" --format=brief 2>/dev/null
                echo "Semantic pass still required: ~/.claude/skills/check-ai-isms/PROSE_GATE.md"
            fi
        fi
        ;;
esac
