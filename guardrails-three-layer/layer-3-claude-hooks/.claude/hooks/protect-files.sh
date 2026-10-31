#!/usr/bin/env bash
# ABOUTME: Layer 3 PreToolUse hook - block Edit/Write/MultiEdit against credentials, system files, lockfiles.
# ABOUTME: Uses exit code 2 + stderr for the coarse-grained deny signal.
set -euo pipefail
INPUT="$(cat)"
FP="$(jq -r '.tool_input.file_path // empty' <<<"${INPUT}")"
[[ -z "${FP}" ]] && exit 0

PROTECTED_PATTERNS=(
    '/\.env($|\.)'
    '/\.git/'
    'package-lock\.json$'
    'Cargo\.lock$'
    'poetry\.lock$'
    'yarn\.lock$'
    '/\.ssh/'
    '/\.kube/config'
    '^/etc/'
    '^/boot/'
    '/id_rsa'
    '/id_ed25519'
    'credentials\.json$'
    '\.pem$'
)

for pat in "${PROTECTED_PATTERNS[@]}"; do
    if [[ "${FP}" =~ ${pat} ]]; then
        echo "Blocked: ${FP} is a protected file (pattern: ${pat})." >&2
        exit 2
    fi
done
exit 0
