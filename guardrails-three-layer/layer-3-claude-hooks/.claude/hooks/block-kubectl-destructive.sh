#!/usr/bin/env bash
# ABOUTME: Layer 3 PreToolUse hook - guard kubectl deletes in protected namespaces and cluster-wide actions.
# ABOUTME: Node-level operations (drain/cordon/taint) escalate to 'ask' instead of 'deny'.
set -euo pipefail
INPUT="$(cat)"
CMD="$(jq -r '.tool_input.command // empty' <<<"${INPUT}")"
PROTECTED='(kube-system|kube-public|kube-node-lease|istio-system|cert-manager|prod|production|monitoring|argocd|flux-system|falco|kyverno|gatekeeper-system)'

deny() {
    jq -n --arg r "$1" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $r
      }
    }'
    exit 0
}

ask() {
    jq -n --arg r "$1" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "ask",
        permissionDecisionReason: $r
      }
    }'
    exit 0
}

# kubectl delete ns <protected>
if [[ "${CMD}" =~ kubectl[[:space:]]+delete[[:space:]]+(namespace|ns)[[:space:]]+([a-zA-Z0-9._-]+) ]]; then
    NS="${BASH_REMATCH[2]}"
    [[ "${NS}" =~ ${PROTECTED} ]] && deny "Refusing to delete protected namespace '${NS}'."
fi

# kubectl delete -n <protected> <anything>
if [[ "${CMD}" =~ kubectl[[:space:]]+delete ]] && [[ "${CMD}" =~ -n[[:space:]]+([a-zA-Z0-9._-]+) ]]; then
    NS="${BASH_REMATCH[1]}"
    [[ "${NS}" =~ ${PROTECTED} ]] && deny "Refusing kubectl delete in protected namespace '${NS}'."
fi

# Cluster-wide deletes
[[ "${CMD}" =~ kubectl[[:space:]]+delete.*--all-namespaces ]] && deny "Refusing cluster-wide kubectl delete."

# Node-level operations - escalate to human approval
if [[ "${CMD}" =~ kubectl[[:space:]]+(drain|cordon|uncordon|taint) ]]; then
    ask "Node-level operation requires human approval."
fi

exit 0
