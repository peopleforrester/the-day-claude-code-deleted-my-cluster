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

if [[ -f package.json ]]; then
    npm test --silent >/tmp/claude-tests.log 2>&1 || fail "npm test failed"
fi
if [[ -f pyproject.toml || -f setup.py ]]; then
    if command -v pytest >/dev/null 2>&1; then
        pytest -q >/tmp/claude-tests.log 2>&1 || fail "pytest failed"
    fi
fi
if [[ -f Cargo.toml ]]; then
    cargo test --quiet >/tmp/claude-tests.log 2>&1 || fail "cargo test failed"
fi
if [[ -f go.mod ]]; then
    go test ./... >/tmp/claude-tests.log 2>&1 || fail "go test failed"
fi

exit 0
