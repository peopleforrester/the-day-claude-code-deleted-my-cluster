# Monday-Morning Rollout

**Goal: Layer 1 green by lunch, Layer 3 green by end of day, Layer 2 planned
by Friday.**

Clock time: ~30 minutes for the minimum posture.

---

## Prerequisites

- You have a git repo you can commit to
- You have GitHub CLI (`gh`) authenticated OR GitHub web access
- You have `pre-commit` installed, or can `pip install --user pre-commit`
- (Layer 2 only) You have `kubectl` pointed at a cluster you can admin

---

## Minute 0–5 — Assess

```bash
cd <your-repo>
git clone --depth=1 https://github.com/peopleforrester/DevOpsDaysAtlanta_2026_Cluster_Destruction_Ignite /tmp/three-layers
/tmp/three-layers/bin/evaluate.sh
```

Write down your score. You will run this again at the end.

---

## Minute 5–20 — Layer 1: git hooks + pre-commit

Copy the client-side hooks into your repo and activate them:

```bash
cp -r /tmp/three-layers/layer-1-git-ci/.githooks ./.githooks
cp    /tmp/three-layers/layer-1-git-ci/.pre-commit-config.yaml ./.pre-commit-config.yaml
cp    /tmp/three-layers/layer-1-git-ci/scripts/install-hooks.sh ./scripts/install-hooks.sh
chmod +x ./.githooks/* ./scripts/install-hooks.sh
./scripts/install-hooks.sh
```

Verify:

```bash
# Should reject this commit
echo 'kubectl delete ns kube-system' > /tmp/bad.sh
git add /tmp/bad.sh 2>/dev/null || git -C . add -f /tmp/bad.sh
git commit -m "feat: trigger the destructive-pattern guard"
# expect: ✗ BLOCKED: Destructive pattern in /tmp/bad.sh
```

Commit the hooks to your repo:

```bash
git add .githooks .pre-commit-config.yaml scripts/install-hooks.sh
git commit -m "security: add Layer 1 git hooks (three-layers)"
```

Layer 1 local is green.

---

## Minute 20–25 — Layer 1 server-side (GitHub branch protection)

Pick **one** path.

**Path A — gh CLI (no IaC):**

```bash
# Requires admin on the repo
REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
gh api -X PUT "repos/$REPO/branches/main/protection" \
  -H "Accept: application/vnd.github+json" \
  -F required_status_checks.strict=true \
  -F 'required_status_checks.contexts[]=security-scan / checkov' \
  -F 'required_status_checks.contexts[]=security-scan / gitleaks' \
  -F enforce_admins=true \
  -F required_pull_request_reviews.required_approving_review_count=1 \
  -F required_pull_request_reviews.dismiss_stale_reviews=true \
  -F required_linear_history=true \
  -F allow_force_pushes=false \
  -F allow_deletions=false \
  -F required_conversation_resolution=true
```

**Path B — Terraform:**

```bash
cp /tmp/three-layers/layer-1-git-ci/terraform/branch-protection.tf ./terraform/
# edit the repository name at the top, then:
cd terraform && terraform init && terraform apply
```

Then copy the GitHub Actions workflows:

```bash
cp -r /tmp/three-layers/layer-1-git-ci/.github/workflows/* ./.github/workflows/
git add .github/workflows
git commit -m "ci: add Layer 1 security-scan + policy-check workflows"
git push
```

Open a PR and watch the checks run. `--no-verify` can no longer ship.

Layer 1 is done.

---

## Minute 25–30 — Layer 3: Claude Code hooks

The fast win for anyone using Claude Code locally:

```bash
cp -r /tmp/three-layers/layer-3-claude-hooks/.claude ./.claude
chmod +x ./.claude/hooks/*.sh
```

Test:

```bash
# In a Claude Code session in this repo, ask it to run:
#   rm -rf /var/lib/etcd
# expected: the hook denies with a clear reason before the tool call
```

Commit the hooks so every developer on the team inherits them:

```bash
git add .claude
git commit -m "security: add Layer 3 Claude Code hooks (three-layers)"
git push
```

Done. Re-run `evaluate.sh` — score should have jumped.

---

## Later this week — Layer 2

Layer 2 requires cluster infrastructure (Kyverno controller, Falco DaemonSet,
~1–2 GiB RAM per replica, three replicas for HA). Plan it on Friday, deploy
it next week.

Start with Kyverno in `validationFailureAction: Audit` mode for one week,
read the PolicyReports, then flip to `Enforce`:

```bash
# install Kyverno
helm repo add kyverno https://kyverno.github.io/kyverno/
helm install kyverno kyverno/kyverno -n kyverno --create-namespace \
  --set replicaCount=3

# apply the policies in Audit mode first
kubectl apply -f /tmp/three-layers/layer-2-kubernetes/kyverno/

# watch what would have been blocked
kubectl get policyreports -A
kubectl get clusterpolicyreports

# after a week: flip every policy to Enforce
sed -i 's/validationFailureAction: Audit/validationFailureAction: Enforce/' \
  /tmp/three-layers/layer-2-kubernetes/kyverno/*.yaml
kubectl apply -f /tmp/three-layers/layer-2-kubernetes/kyverno/
```

Falco comes next:

```bash
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco -n falco --create-namespace \
  --values /tmp/three-layers/layer-2-kubernetes/falco/values.yaml
```

Full Layer 2 guidance: [layer-2-kubernetes/README.md](./layer-2-kubernetes/README.md)

---

## After rollout

Re-run `./bin/evaluate.sh`. If you started at 3/15 and you finish this
playbook at 11/15, you did the work.

**If your AI agent ever types `etcd --force-new-cluster` from now on: at
least four different layers say no before the command runs.** That is the
whole job.
