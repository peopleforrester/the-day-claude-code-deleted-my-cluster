# Repository rules for Claude Code

This repo runs a three-layer defense: Git/CI (Layer 1), Kubernetes admission
+ Falco (Layer 2), Claude Code hooks (Layer 3). Policies are in code. This
file restates the destructive-operations policy so you follow it without
depending on hooks alone.

## Destructive operations policy

You (Claude) MUST NOT:

- Run `rm -rf`, `mkfs`, `dd` to a block device, or `curl | bash` /
  `wget | bash`.
- Run `kubectl delete namespace` (or `-n <ns> delete`) against any of:
  `kube-system`, `kube-public`, `kube-node-lease`, `kyverno`, `argocd`,
  `flux-system`, `cert-manager`, `falco`, `monitoring`, `gatekeeper-system`,
  `prod`, `production`.
- Run `kubeadm reset` on any node.
- Run `etcd --force-new-cluster` or `etcdctl snapshot restore
  --force-new-cluster` without explicit human approval.
- Edit files in `/etc/`, `/boot/`, `/root/`, `~/.ssh/`, `~/.kube/config`,
  `.env*`, lockfiles (`package-lock.json`, `Cargo.lock`, `poetry.lock`,
  `yarn.lock`), or `.git/`.
- Run `sudo` or elevate privileges.
- Apply `netplan` changes without first backing up the current config to
  `/tmp/netplan-backup-<timestamp>.yaml`.
- Disable Claude Code hooks (`"disableAllHooks": true`).

## If you think you need an exception

Use `AskUserQuestion`. Propose the exact change, the reversibility story,
and why the safer alternative won't work. Wait for approval. The
`.claude/hooks/block-destructive-bash.sh` and
`.claude/hooks/block-kubectl-destructive.sh` hooks will reject these
anyway, so asking is actually faster than discovering the block.

## Why this policy exists

The incident that forced this repo to exist (DevOpsDays Atlanta 2026) was
a Claude Code session with direct cluster access executing
`etcd --force-new-cluster` during CNI troubleshooting. etcd quorum gone.
All 187 pods across 20+ namespaces gone with the cluster state. Velero
was running but never tested for restore. Hours of downtime.

The goal is not to slow you down. It is to make the next
`etcd --force-new-cluster` impossible even when you think it's the
efficient path.

## What is safe to do without asking

- Any `Read`, `Glob`, `Grep`, or `WebSearch` tool call.
- `git status`, `git diff`, `git log`, `git branch`.
- `kubectl get`, `kubectl describe`, `kubectl logs`, `kubectl top`.
- `docker ps`, `docker images`, `docker inspect`, `docker logs`.
- `terraform plan`, `terraform validate`, `terraform show`.
- Running tests: `npm test`, `pytest`, `cargo test`, `go test`.
- Editing any file under the repo working tree that is not in the
  protected list above.
