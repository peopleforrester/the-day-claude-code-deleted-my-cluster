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

# netplan apply requires an explicit prior backup (named /tmp/netplan-backup-*.yaml).
if [[ "${CMD}" =~ netplan[[:space:]]+apply ]]; then
    if ! ls /tmp/netplan-backup-*.yaml >/dev/null 2>&1; then
        jq -n '{
          hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: "netplan apply requires a backup at /tmp/netplan-backup-*.yaml first. Create one with: cp /etc/netplan/*.yaml /tmp/netplan-backup-$(date +%s).yaml"
          }
        }'
        exit 0
    fi
fi

exit 0
