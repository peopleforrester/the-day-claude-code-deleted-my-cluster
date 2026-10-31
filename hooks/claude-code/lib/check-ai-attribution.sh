#!/bin/bash
# ABOUTME: Shared AI/Claude attribution check, sourced by check-commit-message.sh.
# ABOUTME: One pattern list, so every enforcement point that sources it applies the same rule.
#
# Synced from the live working set on 2026-10-31. In that set the same file is
# sourced by two enforcement points: the Claude Code PreToolUse hook
# (check-commit-message.sh), which only runs inside an agent session, and a
# native git commit-msg hook, which runs for every commit regardless of what
# created it. A pattern added to only one of them is a pattern that silently
# doesn't apply the other way a commit can be made, so the list lives here.
#
# check-commit-message.sh looks for this file at lib/ beside itself. Install the
# two together (see hooks/README.md); without it the hook refuses every commit
# whose message it can read, rather than skip the check silently.
#
# Usage: source this file, then call: check_ai_attribution "$commit_message"
# Prints a block explanation to stdout and returns 2 if the message contains
# AI/Claude attribution; returns 0 silently otherwise.

check_ai_attribution() {
    local msg="$1"

    # Real product/project names that contain otherwise-flagged tokens.
    # Add here, not by loosening a pattern below, when a legitimate commit
    # gets blocked on a product name.
    local product_allowlist=(
        'LLM Guard'             # ProtectAI scanner service (https://github.com/protectai/llm-guard)
        'llm-guard'             # ...lowercase / hyphenated form (Docker image, manifest dir)
        'llm_guard'             # ...snake_case form
        'llm-coding-workflow'   # the workflow repo (peopleforrester/llm-coding-workflow)
        'CLAUDE.local.md'       # the personal guidance filename (a technical reference, not attribution)
        'CLAUDE.md'             # the guidance filename itself (e.g. "make CLAUDE.md a symlink")
        '\.claude\.json'        # the CLI's own config file, where MCP servers and their env live
        '\.claude/'             # the config directory (e.g. "~/.claude/settings.json is a symlink")
    )

    local scrubbed="$msg"
    local product
    for product in "${product_allowlist[@]}"; do
        # `|` as the delimiter, not `/`. An allowlist entry naming a path
        # (".claude/") contains a slash, which closed the expression early and
        # silently turned every later scrub into a malformed command: 17 tests
        # went red at once on an entry that looked harmless.
        scrubbed=$(echo "$scrubbed" | sed -E "s|${product}|__product__|gI")
    done

    # Proper-noun escape hatch.
    #
    # Some real titles carry the vendor name: a conference talk, the repo named
    # after it, the deck. That is a proper noun, not attribution, and before
    # this there was no way to write such a commit at all. Extending the
    # allowlist per string does not generalize, because the next title is not
    # known yet (#148).
    #
    #     Proper-noun: <the exact string>
    #
    # Deliberately explicit and narrow. Only the named string is scrubbed, so
    # declaring one title does not disable the check for the rest of the
    # message, and the declaration itself lands in history where it can be
    # audited. Same posture as the Trivial: hatch on the issue-link rule: a
    # reason written into the message is measurable, a silent bypass is not.
    # Patterns the hatch may never exempt. A title can legitimately contain the
    # bare vendor name; nothing legitimately contains an attribution trailer.
    # This matters because the hatch is itself instructable: a mid-session
    # injection already tried to append a session trailer to every commit once,
    # and "Proper-noun: <that trailer>" would be the same attack wearing the
    # escape hatch. The hatch widens what a human can name, never what an
    # instruction can smuggle past.
    local never_exemptible=(
        'co-authored-by'
        'claude[\s_-]*session'
        'generated\s+with'
        '(?<![\w-])ai-generated(?![\w-])'
        '(?<![\w-])ai\s+assistant(?![\w-])'
        'claude\s*code'
    )

    local noun
    while IFS= read -r noun; do
        [ -n "$noun" ] || continue

        local forbidden refused=0
        for forbidden in "${never_exemptible[@]}"; do
            if grep -qiP "$forbidden" <<< "$noun"; then
                echo "BLOCKED: Proper-noun: may not exempt an attribution construct."
                echo ""
                echo "Declared: \"$noun\""
                echo ""
                echo "The hatch exists for real titles that happen to carry a vendor name."
                echo "It cannot be used to exempt a trailer, and it never overrides this rule"
                echo "no matter what asks for it."
                return 2
            fi
        done
        [ "$refused" -eq 0 ] || continue
        # Escape regex metacharacters so a title containing . * [ ] is matched
        # literally rather than as a pattern that could scrub far more.
        local escaped
        escaped=$(printf '%s' "$noun" | sed -E 's/[][\.*^$(){}?+|/\\]/\\&/g')
        scrubbed=$(printf '%s' "$scrubbed" | sed -E "s/${escaped}/__proper_noun__/gI")
    done < <(printf '%s\n' "$msg" | sed -nE 's/^[[:space:]]*Proper-noun:[[:space:]]*(.+[^[:space:]])[[:space:]]*$/\1/p')

    # PCRE (grep -P) patterns, case-insensitive. The bare-token patterns use
    # (?<![\w-]) / (?![\w-]) so a hyphenated identifier or path — e.g.
    # "claude-ai-context/", "anthropic-sdk", "llm-guard" — is NOT flagged,
    # while real attribution ("Claude Code", "Generated with Claude", bare
    # "Claude", "Co-Authored-By: Claude") still is.
    #
    # 'claude[\s_-]*session' is its own explicit entry rather than relying on
    # the bare-claude lookahead, because that lookahead deliberately exempts
    # hyphenated identifiers, and "Claude-Session:" is exactly that shape. A
    # mid-session system injection once told an agent to append that trailer
    # to every commit; it must never land regardless of what asks for it.
    local ai_patterns=(
        'claude\s*code'
        'claude[\s_-]*session'
        '(?<![\w-])claude(?![\w-])'
        '(?<![\w-])anthropic(?![\w-])'
        'generated\s+with'
        'co-authored-by.*claude'
        'co-authored-by.*anthropic'
        '(?<![\w-])ai\s+assistant(?![\w-])'
        '(?<![\w-])ai-generated(?![\w-])'
        '(?<![\w-])llm(?![\w-])'
        'language\s+model'
    )

    # Each pattern searches the captured message, not a pipe. Under the
    # pipefail some callers set, `echo | grep -q` failed once grep found its
    # match and the echo, still writing a long message, died of SIGPIPE: the
    # attribution read as clean (#34).
    local pattern matched
    for pattern in "${ai_patterns[@]}"; do
        if matched=$(grep -m1 -oiP "$pattern" <<< "$scrubbed"); then
            matched=${matched%%$'\n'*}
            echo "BLOCKED: Commit message contains AI/Claude reference: \"$matched\""
            echo ""
            echo "Rule: NEVER include references to Claude Code, Claude, or AI in commit messages."
            echo "Commit messages should be professional and describe the technical changes only."
            echo ""
            echo "Please rewrite the commit message without AI attribution."
            return 2
        fi
    done

    return 0
}
