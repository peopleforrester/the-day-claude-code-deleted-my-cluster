#!/usr/bin/env bash
# ABOUTME: Layer 3 UserPromptSubmit hook - block a prompt carrying a credential before the model sees it.
# ABOUTME: Same eight patterns as Layer 1's pre-commit; the reason names the pattern, never the value.
set -euo pipefail
INPUT="$(cat)"
PROMPT="$(jq -r '.prompt // empty' <<<"${INPUT}")"
[[ -z "${PROMPT}" ]] && exit 0

SECRET_PATTERNS=(
    'AKIA[0-9A-Z]{16}'
    'ASIA[0-9A-Z]{16}'
    '-----BEGIN (RSA|OPENSSH|DSA|EC|PGP) PRIVATE KEY-----'
    'ghp_[A-Za-z0-9]{36,}'
    'github_pat_[A-Za-z0-9_]{22,}'
    'xox[baprs]-[A-Za-z0-9-]{10,}'
    'sk-[A-Za-z0-9]{32,}'
    'AIza[0-9A-Za-z_-]{35}'
)

for pat in "${SECRET_PATTERNS[@]}"; do
    if [[ "${PROMPT}" =~ ${pat} ]]; then
        jq -n --arg r "Blocked by Layer 3 policy: the prompt looks like it carries a secret (pattern: ${pat}). Remove it and use an environment variable or secret store instead." '{
          decision: "block",
          reason: $r
        }'
        exit 0
    fi
done
exit 0
