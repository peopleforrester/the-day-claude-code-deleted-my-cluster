# Three Layers of Guardrails for AI Coding Agents — Canonical Reference

This is the long-form reference. For the actionable rollout, start with the
repo root [README](../README.md) and [START_HERE.md](../START_HERE.md).

**Deterministic gates for probabilistic agents.** An AI coding agent is a
stochastic actor with a shell. It will occasionally — predictably — do the
wrong thing, and if that thing is `kubeadm reset` on a production control
plane, apologies after the fact won't restore your etcd quorum. The answer
is not to trust the model more; it is to wrap it in three layers of
non-negotiable, deterministic enforcement: **Git + CI (Layer 1)**,
**Kubernetes admission control + runtime detection (Layer 2)**, and
**Claude Code hooks (Layer 3)**. Each layer catches a different class of
failure, and together they turn a dangerous autonomous agent into a
productive, bounded collaborator.

Every snippet in this doc is copy-paste-ready and mirrors files checked in
under [`../layer-1-git-ci/`](../layer-1-git-ci/),
[`../layer-2-kubernetes/`](../layer-2-kubernetes/), and
[`../layer-3-claude-hooks/`](../layer-3-claude-hooks/). The structure is
intentional: a DevOps engineer clones the repo Monday morning, reads this
doc, and has the first layer green by lunch.

---

## The threat model and why three layers

The 2025–2026 wave of "cluster destruction" incidents — Claude Code
invoking `kubeadm reset`, Cursor agents running
`etcdctl --force-new-cluster`, Aider running `rm -rf /var/lib/etcd` —
share a signature. The agent has legitimate shell and `kubectl` access, a
task description that sounds recoverable ("fix the broken node"), and a
context window too small to hold the cluster's state. When the model
improvises, it improvises at root.

Each layer addresses a distinct failure mode. **Layer 1 (Git + GitHub)**
catches destructive *intentions* at commit time — before any
infrastructure touches the change. **Layer 2 (Kubernetes admission +
runtime)** catches destructive *actions* at the cluster boundary — even if
the commit bypassed review. **Layer 3 (Claude Code hooks)** catches
destructive *tool calls* at the agent boundary — before the command ever
leaves the laptop. `--no-verify` skips Layer 1 client-side, but GitHub's
server-side rulesets and required status checks cannot be bypassed.
Kyverno can be bypassed by running `etcdctl` over SSH on a node, but
Falco's syscall layer sees it anyway. Claude Code hooks can be disabled
with `disableAllHooks: true`, but a CI check on that exact string catches
it on push. The layers are deliberately redundant.

The economics matter: **Layer 1 and Layer 3 are free** (GitHub Actions
public-repo minutes, branch protection, local shell hooks), while **Layer
2 requires infrastructure** (Kyverno controller pods, Falco DaemonSet, OPA
sidecars). Start free, add infra as scale demands.

---

## Layer 1 — Git hooks and GitHub CI/CD

Layer 1 has two halves: **fast client-side hooks that give developers
instant feedback**, and **authoritative server-side gates that cannot be
bypassed**. Keep the client side under ten seconds or developers will
`--no-verify` it; put the real enforcement on GitHub, where `--no-verify`
is irrelevant.

### Client-side: fast local feedback

The core insight: **client hooks are advisory, not authoritative**. Their
job is to save developers (and agents) a round-trip to CI. Scope every
check to `git diff --cached --name-only --diff-filter=ACMR` so scans only
see staged files. Skip binaries. Parallelize. Cache.

The full scripts live in [`../layer-1-git-ci/.githooks/`](../layer-1-git-ci/.githooks/).
Highlights:

- `pre-commit` — blocks `rm -rf`, `kubeadm reset`,
  `etcd(ctl) --force-new-cluster`, AWS/GitHub/Slack keys, `mkfs`,
  `chmod -R 777 /`, and fork-bombs before the commit is recorded.
- `commit-msg` — enforces Conventional Commits and requires a human
  `Signed-off-by` / `Reviewed-by` trailer when AI coauthor markers are
  present.
- `pre-push` — last-chance defense: blocks direct pushes to protected
  branches, detects force-push on protected refs, and runs
  `gitleaks protect` on the push range.

The `.pre-commit-config.yaml` orchestrates the fast/slow split: trivial
checks (yamllint, shellcheck, actionlint) run locally; heavy scanners
(checkov, trivy) run only on changed files, with full-tree scans deferred
to CI.

### Server-side: the `--no-verify` answer

**Client hooks run on developer laptops and can be skipped with
`--no-verify`.** An AI agent with shell access will skip them by default
if prompted to. The authoritative control is server-side, where GitHub
runs required checks on *its* runners, not the developer's, and where
branch protection rules execute before any merge.

See:

- [`../layer-1-git-ci/terraform/branch-protection.tf`](../layer-1-git-ci/terraform/branch-protection.tf)
  for the ruleset as code (preferred).
- [`../START_HERE.md`](../START_HERE.md) minute 20–25 for the `gh api`
  equivalent if you don't want Terraform.
- [`../layer-1-git-ci/.github/workflows/`](../layer-1-git-ci/.github/workflows/)
  for the required status checks: `security-scan.yml`, `policy-check.yml`,
  `pr-validation.yml`, `merge-queue.yml`.

Every workflow triggers on **both** `pull_request` and `merge_group`.
Omitting `merge_group` is the #1 reason merge queues stall. Every job sets
explicit `permissions:`, a `concurrency:` group, and caching.

### The `pr-validation` tamper-check

A small but important job in `pr-validation.yml`: it diffs `.claude/`
against main and fails any PR that flips `"disableAllHooks": true`. That
is the server-side backstop against a developer (or agent) silencing
Layer 3.

### Performance — keeping client hooks under ten seconds

Developers disable slow hooks. The rule is a coffee-sip budget: under ten
seconds or you've lost them.

- Scope every hook to `git diff --cached --name-only --diff-filter=ACMR`.
- Skip binaries with `file --mime | grep charset=binary`.
- Let pre-commit run hooks in parallel (`fail_fast: false`).
- Cache tool binaries in CI with `actions/cache` keyed on
  `hashFiles('.pre-commit-config.yaml')`.
- Split fast hooks (yamllint, shellcheck, actionlint) into local and slow
  ones (checkov full-tree, trivy vuln DB) into CI-only.

The **client-side layer is the sip of coffee; the server-side layer is the
bouncer at the door.**

---

## Layer 2 — Kubernetes admission control and runtime detection

Kyverno and OPA/Gatekeeper are admission controllers — they intercept
writes at the API server boundary. Falco is the runtime detector — it sees
what happens *after* admission, including host-level operations the API
server never saw. You need both because the incident playbook has actions
in both domains: `kubectl delete ns kube-system` is admission-time;
`kubeadm reset` on a node is runtime.

### Kyverno ClusterPolicies — admission-time blocks

The full policies live in [`../layer-2-kubernetes/kyverno/`](../layer-2-kubernetes/kyverno/).
All six follow the same shape — match, exclude, validate-deny.

- **`01-protect-system-namespaces.yaml`** — blocks DELETE/UPDATE of
  `kube-system`, `kube-public`, `default`, `kyverno`, `argocd`,
  `flux-system`, `cert-manager`, `ingress-nginx`, `monitoring`, `falco`,
  `gatekeeper-system`. This policy alone would have stopped the first
  `kubectl delete ns kube-system` of the incident.
- **`02-disallow-sensitive-hostpaths.yaml`** — blocks pods mounting
  `/var/lib/etcd`, `/etc/netplan`, `/etc/kubernetes`, `/`, `/proc`,
  `/sys`, container-runtime sockets. Directly addresses the incident
  vector.
- **`03-pss-baseline.yaml`** — privileged containers, host namespaces
  (`hostNetwork`, `hostPID`, `hostIPC`), privilege escalation.
- **`04-block-exec-kube-system.yaml`** — `kubectl exec` into protected
  namespaces is denied. Prevents the "get a shell in kube-apiserver and
  run etcdctl" escalation path.
- **`05-restrict-clusteradmin-binding.yaml`** — no new bindings to
  `cluster-admin`, `system:masters`, `system:node`,
  `system:kube-scheduler`, `system:kube-controller-manager`.

### Mass-pod-deletion note

**Kubernetes splits `kubectl delete pods --all` into per-pod DELETE
requests at the API server.** Kyverno cannot count "N deletions in one API
call" because that call does not exist. The practical answer is
namespace-scoped and label-scoped blocking, combined with RBAC that simply
does not grant `delete` on `pods` with broad scope. Rate-based enforcement
belongs at the Falco / observability layer, not admission.

### Kyverno's real limitations

Kyverno is an **admission controller**, so everything it cannot see is a
potential bypass:

- **Host-level commands.** `kubeadm reset`, `etcdctl` on a local etcd
  socket, `rm -rf /var/lib/etcd` from SSH — the API server never sees any
  of these. Mitigation: immutable OS (Talos, Bottlerocket), no SSH, sudo
  policies, and Falco at runtime.
- **Kubelet bypass.** A worker node with
  `kubectl --kubeconfig=/etc/kubernetes/kubelet.conf`, or direct hits on
  `https://node:10250/pods`, skips the API server admission chain
  entirely. Mitigation: kubelet `authorization-mode: Webhook`, the
  built-in `NodeRestriction` admission plugin, firewall port 10250.
- **Ephemeral containers and `kubectl debug`.** Historically leaky. Make
  sure your Kyverno webhook config covers `pods/ephemeralcontainers`, and
  deny the verb via RBAC.
- **Fail-open during outage.** `failurePolicy: Ignore` on the Kyverno
  webhook lets requests through when the controller is down. Run three
  replicas and set `failurePolicy: Fail` with narrow exclusions.
- **`PolicyException` abuse.** Anyone who can `create policyexceptions` in
  any namespace can exempt themselves. Lock that CRD down.
- **Already-running privileged pods.** If one exists (legitimately or
  otherwise), `kubectl exec` into it skips admission-time controls. Block
  exec, and use Pod Security Admission to prevent the privileged pod in
  the first place.

### Kyverno vs OPA/Gatekeeper

| Dimension                         | Kyverno                                | OPA/Gatekeeper                        |
|-----------------------------------|----------------------------------------|---------------------------------------|
| Language                          | YAML (K8s-native)                      | Rego DSL                              |
| Learning curve                    | Low — resembles k8s manifests          | Steep                                 |
| Mutation                          | First-class, strategic merge + JSON patch | Limited (`Assign`, observed-fields)  |
| Generation (create new resources) | Yes, `generate:` with clone+sync        | No                                    |
| Existing-resource enforcement     | `mutateExisting`, background scans     | Audit-only                            |
| Image verification                | Cosign/sigstore first-class            | External tool needed                  |
| Non-K8s use                       | K8s-only                               | General-purpose (Envoy, TF, CI/CD)    |
| Managed offerings                 | —                                      | Azure Policy for AKS, GKE Policy Controller |

**Choose Kyverno** when your policy domain is K8s-only, you want YAML, and
you need mutation/generation. **Choose Gatekeeper** when Rego is already
in your stack or you need referential policies across resources. For this
demo, **Kyverno is the primary**; both can coexist since they're just
validating webhooks.

### RBAC least privilege for AI agents

The most common deployment mistake is giving the agent `cluster-admin` "so
it doesn't get blocked." The correct posture is read-heavy, namespace-
scoped writes, and explicit absence of `delete` / `exec` / `portforward`
verbs. See [`../layer-2-kubernetes/rbac/ai-agent.yaml`](../layer-2-kubernetes/rbac/ai-agent.yaml).

The contrast: the typical AI agent gets `cluster-admin` (every verb on
every resource in every namespace). The correct AI agent gets read-only at
cluster scope, narrow create/update/patch in one namespace, and never
`delete` on critical kinds, `secrets`, or `pods/exec`. When the model
invents `kubectl delete ns kube-system`, it gets RBAC-denied before Kyverno
even sees it.

### Network policies to block control-plane paths

See [`../layer-2-kubernetes/networkpolicies/ai-workspace.yaml`](../layer-2-kubernetes/networkpolicies/ai-workspace.yaml).

A single policy blocks three entire incident vectors: cloud metadata IAM
theft (`169.254.169.254`), direct kubelet API (`10250` on node IPs in
`10.0.0.0/8`), and etcd ports (`2379`, `2380` on node IPs). **On GKE
Dataplane V2, validate IMDS block with
`curl -m 3 http://169.254.169.254/` from inside a pod** — there's
historical special-case handling.

### Pod Security Standards and ValidatingAdmissionPolicy

The namespace label `pod-security.kubernetes.io/enforce: restricted`
(built-in, no controller needed) enforces no-privileged, no-host-
namespaces, `runAsNonRoot`, `allowPrivilegeEscalation=false`,
`seccompProfile: RuntimeDefault`, and capability drop-all.

`ValidatingAdmissionPolicy` (GA in K8s 1.30) runs inside `kube-apiserver`
using CEL — no external controller. Use it as the last-resort backstop
that stays running even when Kyverno is down. See
[`../layer-2-kubernetes/vap/deny-privileged.yaml`](../layer-2-kubernetes/vap/deny-privileged.yaml).

### Falco: catching what admission cannot see

Kyverno sees API-server traffic. **Falco sees syscalls and audit events.**
The incident's `kubeadm reset` on a node,
`etcdctl --force-new-cluster`, `netplan apply`, `rm -rf /var/lib/etcd` —
none of these pass through the API server. Only Falco (via its eBPF driver
on the node, plus the `k8saudit` plugin for API events) catches them.

The full rule set is in
[`../layer-2-kubernetes/falco/falco-rules-ai-agent.yaml`](../layer-2-kubernetes/falco/falco-rules-ai-agent.yaml).
Key rules:

- `AI Agent Ran kubeadm reset` (EMERGENCY)
- `AI Agent Destructive etcdctl or etcd Invocation` (EMERGENCY)
- `AI Agent Modified Netplan Configuration` (CRITICAL)
- `Unauthorized Access to etcd Data Directory` (CRITICAL)
- `Static Pod Manifest Modified` (CRITICAL)
- `Shell Spawned In Kubernetes System Pod` (CRITICAL)
- `Container Runtime Socket Accessed From Container` (CRITICAL)
- `ServiceAccount Token Read By Unexpected Process` (CRITICAL)
- `AI Agent Recursive Force Delete` (EMERGENCY)
- `Pod Deleted In Kubernetes System Namespace` (CRITICAL) — audit source
- `Exec Into Kubernetes System Pod` (CRITICAL) — audit source
- `Privileged Pod Created At Runtime` (CRITICAL) — backstop for Kyverno bypass

Wire kube-apiserver's audit webhook to Falco's `:9765/k8s-audit` (the
k8saudit plugin), and pair Falco with **Falco Talon** to auto-remediate:
quarantine-label a pod, attach a deny-all NetworkPolicy, page on-call.
That transforms detection into response inside seconds.

---

## Layer 3 — Claude Code hooks

Claude Code's hook system is the final layer, and it lives on the
developer's machine — the closest possible point of enforcement to the
agent itself. The current Anthropic docs list **25 hook events** (the
original "~19" figure is outdated; the feature expanded rapidly through
2025–2026). Hooks fire at defined lifecycle points, receive a JSON event
on stdin, and influence behavior via exit codes or `hookSpecificOutput`
JSON on stdout. Four handler types exist — `command`, `http`, `prompt`,
`agent` — mixable within a single matcher.

### The event set (highlights)

| Event              | Fires when                       | Can block | Typical use                                   |
|--------------------|----------------------------------|-----------|-----------------------------------------------|
| `SessionStart`     | Session begins/resumes           | No        | Inject CLAUDE.md, current ticket, kubectl ctx |
| `UserPromptSubmit` | User submits prompt              | Yes       | Block secrets in prompts                      |
| `PreToolUse`       | Before a tool call               | Yes       | **Primary enforcement point**                 |
| `PermissionRequest`| Permission dialog about to show  | Yes       | Auto-approve/auto-deny                        |
| `PostToolUse`      | Tool succeeded                   | No        | Audit, auto-format                            |
| `Notification`     | Claude Code sending notification | No        | Route to Slack/PagerDuty                      |
| `Stop`             | Main agent finishes turn         | Yes       | **Run tests, force continue if fails**        |
| `PreCompact`       | Context compaction imminent      | Yes       | Snapshot critical state                       |

### Settings.json — the full example

See [`../layer-3-claude-hooks/.claude/settings.json`](../layer-3-claude-hooks/.claude/settings.json).
Place in:

- `.claude/settings.json` (project, committed)
- `~/.claude/settings.json` (user)
- Enterprise managed policy settings — override everything and cannot be
  bypassed by `disableAllHooks` at user/project scope.

### Exit codes, JSON output, and decision precedence

**Exit 0** is success; stdout is parsed as JSON if structured, or injected
as context for `UserPromptSubmit`/`SessionStart`. **Exit 2** is a blocking
error; stderr is fed back to Claude. Other non-zero exits are non-blocking
errors logged to debug. You choose one: either exit 2 with stderr, or exit
0 with `hookSpecificOutput` JSON — never mix.

For `PreToolUse`, the canonical decision shape is:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Blocked: rm -rf against /var/lib/etcd",
    "updatedInput": { "command": "git status --porcelain" },
    "additionalContext": "You are on the main branch; be careful."
  }
}
```

`permissionDecision` is one of `allow` | `deny` | `ask` | `defer`. When
multiple PreToolUse hooks fire in parallel, the precedence is
**deny > defer > ask > allow**; `deny` is enforceable even under
`--dangerously-skip-permissions`, which is why hook-based denies are
actually stronger than CLI permission flags. `updatedInput` is
last-writer-wins across parallel hooks, so never have two hooks mutating
the same field.

### Matcher patterns

Matchers are evaluated as exact strings when they contain only
`[A-Za-z0-9_|]`, otherwise as JavaScript regex. `Edit|Write|MultiEdit`
matches any of three tools; `mcp__memory__.*` matches every tool from the
`memory` MCP server (the bare `mcp__memory` form matches nothing because
it's treated as an exact string). Built-in tool names: `Bash`, `Edit`,
`Write`, `MultiEdit`, `Read`, `Glob`, `Grep`, `Agent`, `WebFetch`,
`WebSearch`, `AskUserQuestion`, `ExitPlanMode`, plus any
`mcp__<server>__<tool>`. The newer `if:` filter narrows further using
permission-rule syntax — `if: "Bash(git push *)"` or `if: "Edit(*.ts)"`.

### The four handler types

- **`command`** — a shell script that reads JSON on stdin and signals
  decisions via exit code or stdout JSON. The workhorse for 90% of
  enforcement.
- **`http`** — POSTs the same JSON to a URL; 2xx-with-JSON is parsed as a
  decision, non-2xx is non-blocking. Ideal for calling a central
  OPA/Kyverno policy service.
- **`prompt`** — sends a single-turn LLM evaluation (Haiku by default) with
  `$ARGUMENTS` replaced by the event JSON. Perfect for semantic judgment.
- **`agent`** — spawns a subagent with `Read`/`Grep`/`Glob` tools (up to 50
  turns) and lets it inspect the codebase before deciding. Use for
  verification that needs actual file reads, not vibes.

### Combining hooks with CLAUDE.md

**CLAUDE.md is soft guidance; hooks are hard enforcement.** The model
reads CLAUDE.md and usually follows it, but a long session, context
compaction, or a confusing task can drift the behavior. State the rule in
both places. See
[`../layer-3-claude-hooks/CLAUDE.md`](../layer-3-claude-hooks/CLAUDE.md)
for a drop-in example.

When the model forgets the CLAUDE.md rule (and it will), the hook blocks
the action. When someone tries to disable the hook with
`disableAllHooks: true`, the `tamper-check` job in `pr-validation.yml`
(Layer 1) catches the diff and fails the PR. Each layer covers the failure
modes of the others.

### `disableAllHooks` and why it exists

The setting lives at the top level of any settings file — user, project,
local, or managed — and turns off every hook. It's useful for debugging,
testing hooks in isolation, or as an emergency kill-switch when a broken
hook is stopping work. **The key security property: managed policy
settings (IT-controlled) cannot be disabled by user/project/local
`disableAllHooks`.** So enterprise governance teams should ship the real
enforcement hooks via managed settings and accept that developers can turn
off their own hooks but not the mandatory ones. A belt-and-suspenders move
is a CI check on the diff — the `tamper-check` job in
`pr-validation.yml` — that fails any PR introducing
`"disableAllHooks": true`.

---

## Principles, costs, and the path to Monday-afternoon readiness

**Deterministic gates for probabilistic agents** is the right mental
model. An LLM produces a distribution over possible next actions; each
layer above is a deterministic filter that rejects the tail of that
distribution you can't afford. The agent gets faster, not slower, because
safe operations pass through instantly and only the dangerous ones bear
friction.

**Least privilege for AI agents** inverts the default. Most teams give an
agent the credentials of the developer running it — often `cluster-admin`
or equivalent. The correct posture is a dedicated ServiceAccount with
read-cluster-wide, write-narrow-namespace, never-delete-critical scope, no
`pods/exec`, no `secrets`, no `rbac.authorization.k8s.io/*`, no
`namespaces.delete`. When the model invents `kubectl delete ns
kube-system`, the RBAC layer rejects it before any policy engine sees it.

**GitOps as structural Layer 1.** The cleanest architecture keeps the
agent out of direct cluster access entirely: the agent writes YAML to a
Git PR, Layer 1 validates it, a human approves, and ArgoCD (or Flux)
applies the change. The agent literally has no `kubectl` credentials —
there is no cluster-destruction primitive available. This is the
highest-leverage control on the list; if your org can adopt it, Layers 2
and 3 become belt-and-suspenders rather than primary defense.

**The cost gradient favors starting free.** Branch protection, GitHub
Actions on public repos, pre-commit hooks, and Claude Code hooks cost
nothing. Kyverno, Falco, OPA/Gatekeeper, and Falco Talon require
controller pods and operational attention — budget 1–2 GiB RAM per
controller replica, three replicas for HA, and tuning time measured in
engineering weeks. Start with Layer 1 and Layer 3 (free, fast, covers the
laptop and the push), add Kyverno when your cluster justifies it, add
Falco when you need runtime detection, add Talon when you need
auto-remediation.

**The pragmatic rollout.** Clone the repo on Monday morning, run
`scripts/install-hooks.sh`, apply the branch protection Terraform, and
push. By lunch you have client hooks, required checks, and no more
force-pushes to `main`. Drop `.claude/settings.json` and the hooks
directory into your working repos; by early afternoon Claude cannot
`rm -rf` or delete `kube-system` from any machine running those settings.
Apply the Kyverno policies to a staging cluster in
`validationFailureAction: Audit` mode, watch the PolicyReports for a week,
then flip to `Enforce`. Install Falco with the AI-agent ruleset at
`NOTICE` priority, baseline the noise, promote to `WARNING`/`CRITICAL`
after tuning. The full three-layer posture is a month of work; the 80%
posture is an afternoon.

**The key insight to carry out of the talk.** The incident that inspired
this repo wasn't caused by a malicious agent — it was caused by a helpful
agent with too much trust and too few guardrails. You cannot make the
agent smarter, but you can make the environment around it dumber:
deterministic, bounded, and unforgiving of mistakes. That is the whole
job. Every line of code in this repo exists so that the next time an AI
coding agent decides `kubeadm reset` is a reasonable solution to a
problem, at least four different layers say no before the command ever
runs.
