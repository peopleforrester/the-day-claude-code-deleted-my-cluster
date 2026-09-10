#!/bin/bash
# ABOUTME: PostToolUse hook that flags a rule whose paths: gate contradicts the scope
# ABOUTME: its own body claims. Advisory only; warns but never blocks.
#
# HOW THIS HOOK WORKS:
# =====================
# Claude Code runs this after every Write or Edit. It receives JSON on stdin:
#   {"tool_name": "Write", "tool_input": {"file_path": "/path/to/rules/foo.md"}}
#
# A rule file's frontmatter decides when it loads. `paths:` scopes it to sessions
# where a matching file is in play; no `paths:` means it loads every session.
# That gate is invisible from the body, so a file can declare itself an
# "Always-loaded rule" in prose while its frontmatter quietly restricts it to a
# handful of paths. That exact contradiction kept the Monday GraphQL cookbook out
# of nearly every session that needed it, and nothing surfaced it for months.
#
# This hook reads the frontmatter of a rule being written and asks the questions
# that would have caught it. It never blocks, because a narrow gate is often
# correct and only the author knows the intent.
#
# EXIT CODES:
#   0 = always (advisory only)
#
# REGISTERED IN: ~/.claude/settings.json under hooks.PostToolUse
# MATCHER: "Edit|Write"

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# --- Only Write/Edit ---
case "$TOOL_NAME" in
    Write|Edit) ;;
    *) exit 0 ;;
esac

[ -n "$FILE_PATH" ] || exit 0
[ -f "$FILE_PATH" ] || exit 0

# --- Only rule files: a .md living under a rules/ directory ---
# Covers both the repo (claude-config/rules/...) and the live assembly
# (~/.claude/rules/...), including nested subdirs like rules/languages/.
case "$FILE_PATH" in
    */rules/*.md) ;;
    *) exit 0 ;;
esac

# --- Split frontmatter from body ---
# Frontmatter is the block between the first two --- lines at the very top.
FRONTMATTER=$(awk '
    NR==1 && $0=="---" { inside=1; next }
    inside && $0=="---" { exit }
    inside { print }
' "$FILE_PATH")

BODY=$(awk '
    NR==1 && $0=="---" { inside=1; next }
    inside && $0=="---" { inside=0; started=1; next }
    started || NR==1 && $0!="---" { print }
' "$FILE_PATH")

HAS_PATHS=0
echo "$FRONTMATTER" | grep -qE '^paths:' && HAS_PATHS=1

HAS_DESCRIPTION=0
echo "$FRONTMATTER" | grep -qE '^description:' && HAS_DESCRIPTION=1

# Does the prose claim THIS file loads everywhere?
# Anchored to the start of a line, because that is the convention ("Always-loaded
# rule." opens the body). Mid-line matches are usually a statement about a
# different rule, e.g. "see [[external-services]]: always loaded", and treating
# those as self-claims produces false positives.
CLAIMS_ALWAYS=0
echo "$BODY" | grep -qiE '^[[:space:]]*(\*\*)?always[- ]loaded|^[[:space:]]*this rule (is )?always loads?|^[[:space:]]*loaded in every session' && CLAIMS_ALWAYS=1

FINDINGS=""

# --- The contradiction that motivated this hook ---
if [ "$HAS_PATHS" -eq 1 ] && [ "$CLAIMS_ALWAYS" -eq 1 ]; then
    FINDINGS="${FINDINGS}
  CONTRADICTION: the body calls this an always-loaded rule, but the frontmatter
  has a paths: gate, so it loads only when a matching file is in play. Pick one:
  drop the gate, or reword the body to state the real scope."
fi

# --- A gated rule is worth a second look, even when self-consistent ---
if [ "$HAS_PATHS" -eq 1 ] && [ "$CLAIMS_ALWAYS" -eq 0 ]; then
    GLOBS=$(echo "$FRONTMATTER" | awk '/^paths:/{p=1;next} /^[a-zA-Z_-]+:/{p=0} p' | tr -d ' -' | tr '\n' ' ')
    FINDINGS="${FINDINGS}
  GATE REVIEW: paths: ${GLOBS}
  Does the work this rule governs actually happen in files matching that glob?
  A rule about a service is needed wherever the session runs, not only in a
  directory named after it."
fi

# --- description: feeds the generated README rules table ---
if [ "$HAS_DESCRIPTION" -eq 0 ]; then
    FINDINGS="${FINDINGS}
  Frontmatter is missing a description: line. The README rules table falls back
  to the first body line, which is usually the wrong summary."
fi

if [ -n "$FINDINGS" ]; then
    {
        echo ""
        echo "ADVISORY: rule frontmatter — $(basename "$FILE_PATH")"
        echo "$FINDINGS"
        echo ""
    } >&2
fi

exit 0
