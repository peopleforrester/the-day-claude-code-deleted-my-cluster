#!/bin/bash
# ABOUTME: PostToolUse hook that prompts a cross-PRD re-evaluation when a decision
# ABOUTME: lands in an active PRD's Decision Log. Advisory only; never blocks.
#
# HOW THIS HOOK WORKS:
# =====================
# Claude Code runs this after every Write or Edit. It receives JSON on stdin:
#   {"tool_name": "Edit", "tool_input": {"file_path": "/path/prds/10-fleet.md"}}
#
# A decision recorded in one PRD frequently invalidates a milestone in another.
# Several PRDs are open at once here, and nothing connects them: the Decision Log
# is append-only and per-file, so a choice made in PRD 10 can silently contradict
# a planned milestone in PRD 11 and neither file knows. The contradiction is
# usually found later, during implementation, when it is expensive.
#
# This hook fires on an edit to an active PRD and asks whether a Decision Log row
# was added. If so, it asks for the cascade: re-check the remaining milestones in
# this PRD, then scan the other open PRDs. It cannot tell whether a row was
# actually added, so it hands that judgment back rather than guessing, and tells
# the agent to skip when nothing was logged.
#
# Output goes to stdout as PostToolUse JSON so the guidance lands in the model's
# additionalContext rather than only in a terminal a human may not read.
#
# EXIT CODES:
#   0 = always (advisory only)
#
# REGISTERED IN: ~/.claude/settings.json under hooks.PostToolUse
# MATCHER: "Edit|Write"

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

case "$TOOL_NAME" in
    Write|Edit) ;;
    *) exit 0 ;;
esac

[ -n "$FILE_PATH" ] || exit 0

# --- Active PRDs only: prds/<name>.md, never prds/done/<name>.md ---
# An archived PRD is a historical record; a decision added there changes nothing
# downstream, so cascading from it is noise.
case "$FILE_PATH" in
    */prds/done/*) exit 0 ;;
    */prds/*.md) ;;
    *) exit 0 ;;
esac

# --- The file must actually carry a Decision Log ---
# Without that section there is no decision to cascade, and firing on every PRD
# body edit would train the reader to ignore this hook.
[ -f "$FILE_PATH" ] || exit 0
grep -qiE '^#{1,3}[[:space:]]+Decision Log' "$FILE_PATH" || exit 0

PRD_NAME=$(basename "$FILE_PATH")

MSG="PRD edited (${PRD_NAME}). If this edit added a row to '## Decision Log', run the cascade before moving on:
  1. Re-read the remaining milestones in ${PRD_NAME} and update any the new decision affects.
  2. Scan the other open PRDs in prds/ by title and summary. Open any that look related and update affected milestones.
  3. Append the decision to decisions.md, which is the append-only audit log across the repo, per the state-persistence rule.
  4. If the decision rules an approach out, record it under 'Rejected approaches' so a later session does not re-propose it.
Skip all of this if no Decision Log row was added."

python3 -c "
import json, sys
print(json.dumps({
    'hookSpecificOutput': {
        'hookEventName': 'PostToolUse',
        'additionalContext': sys.argv[1],
    }
}))
" "$MSG"

exit 0
