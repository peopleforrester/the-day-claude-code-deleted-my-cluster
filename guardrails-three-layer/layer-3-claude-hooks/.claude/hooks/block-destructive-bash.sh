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

# netplan apply requires an explicit prior backup, netplan-backup-*.yaml in the project's
# own tmp/. A system tempdir is no place for it: it does not survive the reboot a bad
# apply ends in.
if [[ "${CMD}" =~ netplan[[:space:]]+apply ]]; then
    BACKUP_DIR="${CLAUDE_PROJECT_DIR:-${PWD}}/tmp"
    if ! ls "${BACKUP_DIR}"/netplan-backup-*.yaml >/dev/null 2>&1; then
        jq -n --arg d "${BACKUP_DIR}" '($d | @sh) as $q | {
          hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: "netplan apply requires a backup at \($d)/netplan-backup-*.yaml first. Create one with: mkdir -p \($q) && cp /etc/netplan/*.yaml \($q)/netplan-backup-$(date +%s).yaml"
          }
        }'
        exit 0
    fi
fi

exit 0
