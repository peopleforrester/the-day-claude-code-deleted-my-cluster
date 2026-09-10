#!/usr/bin/env bash
# ABOUTME: Blocks creating prds/N-slug.md when GitHub issue N does not exist.
# ABOUTME: Enforces issue-first numbering structurally, so PRD numbers cannot drift.

set -euo pipefail

# PRDs created before the issue-first convention was adopted. Their numbers were
# assigned locally while repo issue numbers ran ahead, so they have no matching
# issue and never will. Retrofitting would rename files referenced by decisions.md
# and by sealed contract checksums. See prds/README.md.
PRD_GRANDFATHERED="${PRD_GRANDFATHERED:-}"

# ─── Pure helpers (sourced directly by the tests) ─────────────────────

# PRD number for path $1, or empty when the path is not a new PRD file.
#
# Only `prds/<digits>-<slug>.md` qualifies. README, the template, anything
# without a leading number, and files already moved to prds/done/ are not new
# work and are left alone.
prd_number_from_path() {
    local path="$1" rest base
    case "$path" in
        */prds/*) rest="${path##*/prds/}" ;;
        prds/*)   rest="${path#prds/}" ;;
        *)        printf ''; return 0 ;;
    esac
    # Anything in a subdirectory (done/, .draft/, .amend/) is not a new PRD.
    case "$rest" in */*) printf ''; return 0 ;; esac
    base="$rest"
    case "$base" in
        [0-9]*-*.md) printf '%s' "${base%%-*}" ;;
        *)           printf '' ;;
    esac
}

# Whether PRD number $1 predates the convention.
is_grandfathered() {
    local n="$1" g
    for g in ${PRD_GRANDFATHERED:-}; do
        [ "$n" = "$g" ] && { printf 'yes'; return 0; }
    done
    printf 'no'
}

# Whether GitHub issue $1 exists in the current repo: yes, no, or unknown.
#
# "unknown" covers no gh, no auth, or no network. The caller allows the write in
# that case and says so out loud, because blocking all PRD work when GitHub is
# unreachable is worse than a missed check. This is a stated escape, not a silent
# fallback.
issue_exists() {
    local n="$1"
    if [ -n "${PRD_HOOK_ASSUME_EXISTS:-}" ]; then
        [ "$PRD_HOOK_ASSUME_EXISTS" = "1" ] && { printf 'yes'; return 0; }
        printf 'no'; return 0
    fi
    command -v gh >/dev/null 2>&1 || { printf 'unknown'; return 0; }
    if gh issue view "$n" --json number >/dev/null 2>&1; then
        printf 'yes'
    elif gh auth status >/dev/null 2>&1; then
        printf 'no'
    else
        printf 'unknown'
    fi
}

# ─── Main ─────────────────────────────────────────────────────────────

main() {
    local input file number grandfathered exists
    input=$(cat)
    file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || printf '')
    [ -n "$file" ] || exit 0

    number=$(prd_number_from_path "$file")
    [ -n "$number" ] || exit 0

    grandfathered=$(is_grandfathered "$number")
    [ "$grandfathered" = "yes" ] && exit 0

    # Editing a PRD that already exists is ordinary work.
    [ -e "$file" ] && exit 0

    exists=$(issue_exists "$number")
    case "$exists" in
        yes) exit 0 ;;
        unknown)
            printf 'NOTE: could not reach GitHub to verify issue #%s exists. Allowing the write unverified.\n' \
                "$number" >&2
            exit 0
            ;;
    esac

    cat >&2 <<EOF
BLOCKED: refusing to create $file because GitHub issue #$number does not exist.

PRD numbers are not chosen locally. Create the issue first and let GitHub assign
the number, then name the file after it. This is what stranded PRDs 6 through 11.

Use the /prd skill, which does this in the right order:

    /prd new

It runs 'gh issue create', reads the number N from the result, and writes
prds/N-slug.md. See prds/README.md for the convention.
EOF
    exit 2
}

if [ -z "${PRD_LIB_ONLY:-}" ]; then
    main "$@"
fi
