# Layer 1 — Git + CI

**Build first. Free. Catches destructive intentions at commit time, before
any infrastructure touches the change.**

Two halves:

- **Client-side (fast, advisory).** Runs on the developer's machine. Keeps
  feedback under 10 seconds. `--no-verify` can bypass it — that's fine.
- **Server-side (authoritative).** Runs on GitHub's runners. Required status
  checks, branch protection, merge queue. `--no-verify` is irrelevant here.

Client-side is the coffee sip. Server-side is the bouncer at the door.

---

## Files in this directory

```
.githooks/
  pre-commit                        destructive patterns, secrets, hostpath wipes
  commit-msg                        Conventional Commits + human Reviewed-by for AI commits
  pre-push                          protected-branch push guard, gitleaks protect
.pre-commit-config.yaml             pre-commit framework orchestration
scripts/install-hooks.sh            one-shot installer
terraform/branch-protection.tf      GitHub ruleset as code (preferred)
.github/
  CODEOWNERS                        required reviewers per path
  workflows/
    security-scan.yml               checkov, trivy-fs, gitleaks, kube-linter, kubesec
    policy-check.yml                conftest (OPA/Rego), kyverno CLI validation
    pr-validation.yml               title, AI-content detection, tamper-check
    merge-queue.yml                 merge_group all-green gate
policy/deny-destructive.rego        example OPA/Rego policy
```

## Install

```bash
cp -r .githooks ../.githooks
cp    .pre-commit-config.yaml ../.pre-commit-config.yaml
cp -r .github/ ../.github
cp -r scripts  ../scripts
chmod +x ../.githooks/* ../scripts/install-hooks.sh
../scripts/install-hooks.sh
```

Then set branch protection on `main` (either via `gh api` or the
`terraform/branch-protection.tf` in this directory — see the top-level
[START_HERE.md](../START_HERE.md) minute 20-25).

## Verify

```bash
# should be rejected
echo 'kubectl delete ns kube-system' >> /tmp/demo.sh
git add /tmp/demo.sh && git commit -m "feat: trip the destructive-pattern guard"
# expect: ✗ BLOCKED: Destructive pattern in /tmp/demo.sh
```

## What each hook catches

| Hook         | Blocks                                                                 |
|--------------|------------------------------------------------------------------------|
| pre-commit   | `rm -rf`, `kubeadm reset`, `etcdctl --force-new-cluster`, AWS/GH/Slack keys, `mkfs`, chmod 777 / |
| commit-msg   | non-Conventional messages; AI-coauthored commits without `Reviewed-by` |
| pre-push     | force-push to protected refs; gitleaks on push range                   |

## The `--no-verify` answer

Client hooks can be skipped. **Don't treat them as enforcement.** The real
enforcement is the required status checks on GitHub (`.github/workflows/*.yml`)
and the branch protection ruleset (`terraform/branch-protection.tf`). Those
run on GitHub's infrastructure, not the developer's laptop, and cannot be
bypassed by any local flag.

## Performance budget

Developers disable slow hooks. **Target: under 10 seconds for pre-commit.**

- Scope scans to `git diff --cached --name-only --diff-filter=ACMR`
- Skip binaries with `file --mime | grep charset=binary`
- Fast local: yamllint, shellcheck, actionlint, gitleaks (staged)
- Slow CI-only: checkov full-tree, trivy vuln DB, kube-linter

## Canonical reference

Full rationale, threat model, and edge cases: [../docs/three-layers.md](../docs/three-layers.md)
