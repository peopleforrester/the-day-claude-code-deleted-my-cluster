#!/usr/bin/env bash
# ABOUTME: Self-assessment for the Three Layers of Guardrails.
# ABOUTME: Read-only. Reports a traffic-light score and next action per layer.
set -euo pipefail

# ---- ansi ----
if [[ -t 1 ]]; then
    RED='\033[0;31m'; GRN='\033[0;32m'; YEL='\033[1;33m'
    CYA='\033[0;36m'; DIM='\033[2m';    NC='\033[0m'
else
    RED=''; GRN=''; YEL=''; CYA=''; DIM=''; NC=''
fi

l1_pass=0; l1_total=0
l2_pass=0; l2_total=0
l3_pass=0; l3_total=0

check() {
    # check <layer> <label> <ok|fail|unknown> [detail]
    local layer="$1" label="$2" status="$3" detail="${4:-}"
    local mark
    case "$status" in
        ok)      mark="${GRN}PASS${NC}"; eval "${layer}_pass=\$((${layer}_pass+1))" ;;
        fail)    mark="${RED}MISS${NC}" ;;
        unknown) mark="${YEL}  ? ${NC}" ;;
    esac
    eval "${layer}_total=\$((${layer}_total+1))"
    printf "  %-54s [%s]" "${label}" "${mark}"
    [[ -n "$detail" ]] && printf " ${DIM}%s${NC}" "$detail"
    printf "\n"
}

section() {
    printf "\n${CYA}=== %s ===${NC}\n" "$1"
}

# =====================================================================
# Layer 1: git + CI
# =====================================================================
section "Layer 1 - Git + CI"

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    repo_root="$(git rev-parse --show-toplevel)"
    cd "${repo_root}"
    check l1 "inside a git repo" ok "${repo_root}"

    hp="$(git config --get core.hooksPath || true)"
    if [[ -n "${hp}" && -d "${hp}" ]]; then
        check l1 "core.hooksPath points at a dir" ok "${hp}"
    else
        check l1 "core.hooksPath points at a dir" fail "set with 'git config core.hooksPath .githooks'"
    fi

    if [[ -x ".githooks/pre-commit" ]]; then
        check l1 ".githooks/pre-commit present and executable" ok
    else
        check l1 ".githooks/pre-commit present and executable" fail
    fi

    if [[ -f ".pre-commit-config.yaml" ]]; then
        check l1 ".pre-commit-config.yaml present" ok
    else
        check l1 ".pre-commit-config.yaml present" fail
    fi

    if command -v pre-commit >/dev/null 2>&1; then
        check l1 "pre-commit framework installed" ok "$(pre-commit --version 2>/dev/null | head -1)"
    else
        check l1 "pre-commit framework installed" fail "pip install --user pre-commit"
    fi

    if [[ -d ".github/workflows" ]] && ls .github/workflows/*.yml .github/workflows/*.yaml 2>/dev/null | grep -qiE 'security|policy|scan|check'; then
        check l1 "GitHub Actions workflow for security/policy" ok
    else
        check l1 "GitHub Actions workflow for security/policy" fail "see layer-1-git-ci/.github/workflows"
    fi

    if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
        repo_slug="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)"
        if [[ -n "${repo_slug}" ]]; then
            if gh api "repos/${repo_slug}/branches/main/protection" >/dev/null 2>&1; then
                check l1 "branch protection active on main" ok "${repo_slug}"
            else
                check l1 "branch protection active on main" fail "see START_HERE.md minute 20-25"
            fi
        else
            check l1 "branch protection active on main" unknown "gh installed but no repo slug"
        fi
    else
        check l1 "branch protection active on main" unknown "gh not installed or not auth'd"
    fi
else
    check l1 "inside a git repo" fail "run from inside a git working tree"
fi

# =====================================================================
# Layer 2: K8s admission + runtime
# =====================================================================
section "Layer 2 - Kubernetes admission + runtime"

if command -v kubectl >/dev/null 2>&1; then
    ctx="$(kubectl config current-context 2>/dev/null || true)"
    if [[ -n "${ctx}" ]] && kubectl cluster-info >/dev/null 2>&1; then
        check l2 "kubectl reachable" ok "ctx=${ctx}"

        if kubectl get ns kyverno >/dev/null 2>&1; then
            pods_ready="$(kubectl -n kyverno get pods --no-headers 2>/dev/null | awk '$3=="Running"' | wc -l | tr -d ' ')"
            check l2 "Kyverno installed and running" ok "${pods_ready} running pod(s)"
        else
            check l2 "Kyverno installed and running" fail "helm install kyverno kyverno/kyverno -n kyverno"
        fi

        if kubectl get clusterpolicies >/dev/null 2>&1; then
            cp_count="$(kubectl get clusterpolicies --no-headers 2>/dev/null | wc -l | tr -d ' ')"
            if [[ "${cp_count}" -gt 0 ]]; then
                check l2 "Kyverno ClusterPolicies applied" ok "${cp_count} policy(ies)"
            else
                check l2 "Kyverno ClusterPolicies applied" fail "kubectl apply -f layer-2-kubernetes/kyverno/"
            fi
        else
            check l2 "Kyverno ClusterPolicies applied" fail "Kyverno CRDs not present"
        fi

        if kubectl get ns falco >/dev/null 2>&1 || kubectl get ds -A 2>/dev/null | grep -qi falco; then
            check l2 "Falco installed" ok
        else
            check l2 "Falco installed" fail "helm install falco falcosecurity/falco -n falco"
        fi

        if kubectl get ns 2>/dev/null | awk 'NR>1 {print $1}' | grep -qx "ai-workspace"; then
            pss="$(kubectl get ns ai-workspace -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null || true)"
            if [[ "${pss}" == "restricted" ]]; then
                check l2 "ai-workspace ns with PSS restricted" ok
            else
                check l2 "ai-workspace ns with PSS restricted" fail "missing pod-security.kubernetes.io/enforce=restricted"
            fi
        else
            check l2 "ai-workspace ns with PSS restricted" fail "kubectl apply -f layer-2-kubernetes/rbac/ai-agent.yaml"
        fi

        if kubectl auth can-i --list 2>/dev/null | grep -q .; then
            if kubectl get clusterroles cluster-admin -o yaml 2>/dev/null | grep -q 'name: cluster-admin'; then
                check l2 "cluster-admin bindings audited" unknown "run: kubectl get clusterrolebindings -o wide | grep cluster-admin"
            fi
        fi
    else
        check l2 "kubectl reachable" fail "kubectl cluster-info failed; Layer 2 checks skipped"
    fi
else
    check l2 "kubectl reachable" unknown "kubectl not installed; Layer 2 checks skipped"
fi

# =====================================================================
# Layer 3: Claude Code hooks
# =====================================================================
section "Layer 3 - Claude Code hooks"

if [[ -f "${HOME}/.claude/settings.json" ]]; then
    check l3 "~/.claude/settings.json exists" ok
else
    check l3 "~/.claude/settings.json exists" fail "missing user-scope settings"
fi

project_settings=""
if [[ -f ".claude/settings.json" ]]; then
    project_settings=".claude/settings.json"
elif [[ -f ".claude/settings.local.json" ]]; then
    project_settings=".claude/settings.local.json"
fi
if [[ -n "${project_settings}" ]]; then
    check l3 "project .claude/settings.json present" ok "${project_settings}"

    if command -v jq >/dev/null 2>&1; then
        if jq -e '.hooks.PreToolUse' "${project_settings}" >/dev/null 2>&1; then
            check l3 "PreToolUse hooks configured" ok
        else
            check l3 "PreToolUse hooks configured" fail "no PreToolUse matchers in settings"
        fi

        if jq -e '.disableAllHooks == true' "${project_settings}" >/dev/null 2>&1; then
            check l3 "disableAllHooks NOT set to true" fail "disableAllHooks:true DEFEATS this layer"
        else
            check l3 "disableAllHooks NOT set to true" ok
        fi
    else
        check l3 "PreToolUse hooks configured" unknown "install jq for a deeper check"
        check l3 "disableAllHooks NOT set to true" unknown "install jq for a deeper check"
    fi
else
    check l3 "project .claude/settings.json present" fail "cp -r layer-3-claude-hooks/.claude ./.claude"
    check l3 "PreToolUse hooks configured" fail "no project settings to inspect"
    check l3 "disableAllHooks NOT set to true" unknown "no project settings to inspect"
fi

hooks_dir=""
[[ -d ".claude/hooks" ]] && hooks_dir=".claude/hooks"
if [[ -n "${hooks_dir}" ]]; then
    count="$(find "${hooks_dir}" -maxdepth 1 -type f -perm -u+x 2>/dev/null | wc -l | tr -d ' ')"
    if [[ "${count}" -gt 0 ]]; then
        check l3 "executable hook scripts present" ok "${count} file(s) in ${hooks_dir}"
    else
        check l3 "executable hook scripts present" fail "chmod +x ${hooks_dir}/*.sh"
    fi
else
    check l3 "executable hook scripts present" fail "no .claude/hooks dir"
fi

if [[ -f "CLAUDE.md" ]]; then
    if grep -qiE 'destructive|forbidden|MUST NOT|guardrail' CLAUDE.md 2>/dev/null; then
        check l3 "CLAUDE.md states destructive-op policy" ok
    else
        check l3 "CLAUDE.md states destructive-op policy" fail "add a 'Destructive operations policy' section"
    fi
else
    check l3 "CLAUDE.md states destructive-op policy" fail "create CLAUDE.md with destructive-op policy"
fi

# =====================================================================
# Summary
# =====================================================================
total_pass=$((l1_pass + l2_pass + l3_pass))
total_total=$((l1_total + l2_total + l3_total))

printf "\n${CYA}=== Summary ===${NC}\n"
printf "  Layer 1 (Git + CI)         %d / %d\n" "${l1_pass}" "${l1_total}"
printf "  Layer 2 (K8s admission)    %d / %d\n" "${l2_pass}" "${l2_total}"
printf "  Layer 3 (Claude Code)      %d / %d\n" "${l3_pass}" "${l3_total}"
printf "  ${CYA}Total                      %d / %d${NC}\n" "${total_pass}" "${total_total}"

printf "\n${CYA}=== Next action ===${NC}\n"
if [[ "${l1_pass}" -lt "${l1_total}" ]]; then
    printf "  ${YEL}Start with Layer 1.${NC} It is free, fast, and covers the commit path.\n"
    printf "  See: ${DIM}layer-1-git-ci/README.md${NC}\n"
elif [[ "${l2_pass}" -lt "${l2_total}" ]]; then
    printf "  ${YEL}Layer 1 is healthy. Move to Layer 2.${NC} Requires cluster infrastructure.\n"
    printf "  See: ${DIM}layer-2-kubernetes/README.md${NC}\n"
elif [[ "${l3_pass}" -lt "${l3_total}" ]]; then
    printf "  ${YEL}Layers 1+2 healthy. Finish with Layer 3 (Claude Code hooks).${NC}\n"
    printf "  See: ${DIM}layer-3-claude-hooks/README.md${NC}\n"
else
    printf "  ${GRN}All three layers present.${NC} Re-run this script after any config change.\n"
fi

exit 0
