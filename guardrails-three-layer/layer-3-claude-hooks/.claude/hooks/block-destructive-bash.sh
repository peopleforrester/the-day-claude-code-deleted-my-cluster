#!/usr/bin/env bash
# ABOUTME: Layer 3 PreToolUse hook - deny destructive shell commands before the Bash tool fires.
# ABOUTME: deny is enforceable even under --dangerously-skip-permissions.
set -euo pipefail
INPUT="$(cat)"
CMD="$(jq -r '.tool_input.command // empty' <<<"${INPUT}")"

BLOCK_PATTERNS=(
    'rm[[:space:]]+-[a-zA-Z]*[rR][a-zA-Z]*[fF]'
    'rm[[:space:]]+-[a-zA-Z]*[fF][a-zA-Z]*[rR]'
    ':\(\)\{[[:space:]]*:\|:&[[:space:]]*\};:'
    'mkfs\.'
    'dd[[:space:]]+if=.*of=/dev/(sd|nvme|xvd)'
    '>/dev/sda'
    'kubeadm[[:space:]]+reset'
    'etcd(ctl)?[[:space:]]+.*--force-new-cluster'
    'iptables[[:space:]]+-F'
    'chmod[[:space:]]+-R[[:space:]]+777[[:space:]]+/'
    'curl[[:space:]]+[^|]*\|[[:space:]]*(bash|sh|zsh)'
    'wget[[:space:]]+[^|]*-O-[[:space:]]*\|[[:space:]]*(bash|sh)'
)

for pat in "${BLOCK_PATTERNS[@]}"; do
    if [[ "${CMD}" =~ ${pat} ]]; then
        jq -n --arg r "Blocked by Layer 3 policy (pattern: ${pat})." '{
          hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: $r
          }
        }'
        exit 0
    fi
done

# netplan apply requires an explicit prior backup, named netplan-backup-*.yaml,
# in the project's own tmp/ (not the system tempdir, which any process shares).
# A tmp/ this hook creates ignores itself: a netplan file can carry Wi-Fi
# passphrases, and the backup must not be committed by a later `git add`.
if [[ "${CMD}" =~ netplan[[:space:]]+apply ]]; then
    BACKUP_DIR="${CLAUDE_PROJECT_DIR:-${PWD}}/tmp"
    if ! ls "${BACKUP_DIR}"/netplan-backup-*.yaml >/dev/null 2>&1; then
        if [[ ! -d "${BACKUP_DIR}" ]]; then
            mkdir -p "${BACKUP_DIR}"
            printf '*\n' >"${BACKUP_DIR}/.gitignore"
        fi
        jq -n --arg d "${BACKUP_DIR}" '{
          hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: "netplan apply requires a backup at \($d)/netplan-backup-*.yaml first. Create one with: cp /etc/netplan/*.yaml \"\($d)/netplan-backup-$(date +%s).yaml\""
          }
        }'
        exit 0
    fi
fi

exit 0
