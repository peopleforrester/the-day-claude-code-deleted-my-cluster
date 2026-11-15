#!/usr/bin/env bash
# ABOUTME: Layer 3 Stop hook - refuse to end the turn if the project's test suite is failing.
# ABOUTME: Exit 2 + stderr forces Claude to keep working. Skip when stop_hook_active=true to avoid recursion.
set -euo pipefail
INPUT="$(cat)"
ACTIVE="$(jq -r '.stop_hook_active' <<<"${INPUT}")"
[[ "${ACTIVE}" == "true" ]] && exit 0

# Test output goes to the project's own tmp/, not the system tempdir, so it
# stays with the project and nothing else on the machine can overwrite it.
LOG_DIR="${CLAUDE_PROJECT_DIR:-${PWD}}/tmp"
LOG="${LOG_DIR}/claude-tests.log"

fail() {
    echo "Stop blocked: $1. Fix before ending the turn. Output: ${LOG}" >&2
    exit 2
}

# run_tests LABEL COMMAND... - run one suite with its output in the log.
# A tmp/ this hook creates ignores itself, so it never shows in git status.
run_tests() {
    local label="$1"
    shift
    if [[ ! -d "${LOG_DIR}" ]]; then
        mkdir -p "${LOG_DIR}"
        printf '*\n' >"${LOG_DIR}/.gitignore"
    fi
    "$@" >"${LOG}" 2>&1 || fail "${label} failed"
}

if [[ -f package.json ]]; then
    run_tests "npm test" npm test --silent
fi
if [[ -f pyproject.toml || -f setup.py ]]; then
    if command -v pytest >/dev/null 2>&1; then
        run_tests "pytest" pytest -q
    fi
fi
if [[ -f Cargo.toml ]]; then
    run_tests "cargo test" cargo test --quiet
fi
if [[ -f go.mod ]]; then
    run_tests "go test" go test ./...
fi

exit 0
