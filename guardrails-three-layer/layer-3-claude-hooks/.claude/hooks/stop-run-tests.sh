#!/usr/bin/env bash
# ABOUTME: Layer 3 Stop hook - refuse to end the turn if the project's test suite is failing.
# ABOUTME: Exit 2 + stderr forces Claude to keep working. Skip when stop_hook_active=true to avoid recursion.
set -euo pipefail
INPUT="$(cat)"
ACTIVE="$(jq -r '.stop_hook_active' <<<"${INPUT}")"
[[ "${ACTIVE}" == "true" ]] && exit 0

fail() {
    echo "Stop blocked: $1. Fix before ending the turn." >&2
    exit 2
}

# Test output goes to the project's own tmp/, never a system tempdir. Keep tmp/ in
# the project's .gitignore.
LOG_DIR="${CLAUDE_PROJECT_DIR:-${PWD}}/tmp"

run_suite() {
    local name="$1"
    shift
    mkdir -p "${LOG_DIR}"
    "$@" >"${LOG_DIR}/claude-tests.log" 2>&1 || fail "${name} failed"
}

if [[ -f package.json ]]; then
    run_suite "npm test" npm test --silent
fi
if [[ -f pyproject.toml || -f setup.py ]]; then
    if command -v pytest >/dev/null 2>&1; then
        run_suite "pytest" pytest -q
    fi
fi
if [[ -f Cargo.toml ]]; then
    run_suite "cargo test" cargo test --quiet
fi
if [[ -f go.mod ]]; then
    run_suite "go test" go test ./...
fi

exit 0
