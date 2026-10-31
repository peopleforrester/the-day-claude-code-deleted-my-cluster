#!/usr/bin/env bash
# ABOUTME: Layer 3 PermissionRequest hook - auto-allow safe reads, auto-deny credential paths / sudo / curl|bash.
# ABOUTME: Everything else falls through to the normal permission dialog.
set -euo pipefail

INPUT="$(cat)"
TOOL="$(jq -r '.tool_name' <<<"${INPUT}")"
CMD="$(jq -r '.tool_input.command // empty' <<<"${INPUT}")"
FP="$(jq -r '.tool_input.file_path // empty' <<<"${INPUT}")"

allow() {
    jq -n '{
      hookSpecificOutput: {
        hookEventName: "PermissionRequest",
        decision: { behavior: "allow" }
      }
    }'
    exit 0
}

deny() {
    jq -n --arg r "$1" '{
      hookSpecificOutput: {
        hookEventName: "PermissionRequest",
        decision: { behavior: "deny", message: $r }
      }
    }'
    exit 0
}

# Hard denies
case "${CMD}" in
    *sudo*) deny "sudo requires human approval" ;;
    *"curl "*"| sh"*|*"curl "*"| bash"*|*"wget "*"| sh"*|*"wget "*"| bash"*)
        deny "curl|bash / wget|bash is forbidden" ;;
esac
case "${FP}" in
    /etc/*|/boot/*|/root/*) deny "system path requires human approval" ;;
    *.ssh/*|*.kube/config)  deny "credential directory requires human approval" ;;
esac

# Fast allows for read-only tools
case "${TOOL}" in
    Read|Glob|Grep|WebSearch) allow ;;
esac

# Fast allows for canonical read-only commands
case "${CMD}" in
    "ls"|"ls "*|"pwd"|"whoami"|"date"|"hostname") allow ;;
    "cat "*|"head "*|"tail "*|"less "*|"file "*|"stat "*) allow ;;
    "git status"|"git status "*|"git diff"|"git diff "*|"git log"*|"git branch"*) allow ;;
    "kubectl get"*|"kubectl describe"*|"kubectl logs"*|"kubectl top"*) allow ;;
    "docker ps"*|"docker images"*|"docker inspect"*|"docker logs"*) allow ;;
    "terraform plan"*|"terraform validate"*|"terraform show"*) allow ;;
    "npm test"*|"pytest"*|"cargo test"*|"go test"*) allow ;;
esac

# Fall through - normal dialog runs
exit 0
