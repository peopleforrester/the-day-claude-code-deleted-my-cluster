# Three Layers of Guardrails for AI Coding Agents

**You just saw the talk. Here is what to do on Monday morning.**

DevOpsDays Atlanta 2026 — *The Day Claude Code Deleted My Cluster.* Michael
Forrester (@peopleforrester).

---

## The thesis, in one line

**Use deterministic controls to block probabilistic agents.** An AI coding
agent is a stochastic actor with a shell. Wrap it in three non-negotiable,
deterministic layers. Each layer catches a different class of failure.

```
Layer 1 — Git + CI                   (build first — free, fast, stops intent)
Layer 2 — K8s admission + runtime    (build second — stops action at cluster)
Layer 3 — Claude Code hooks          (build third — stops tool call at agent)
```

The layers are deliberately redundant. `--no-verify` skips Layer 1 locally,
but GitHub's server-side rulesets cannot be bypassed. Kyverno can be bypassed
by running `etcdctl` on a node; Falco's syscall layer sees it anyway. Claude
Code hooks can be disabled with `disableAllHooks: true`; a CI check on that
string catches it on push.

---

## Start here (60 seconds)

```bash
git clone https://github.com/peopleforrester/DevOpsDaysAtlanta_2026_Cluster_Destruction_Ignite
cd DevOpsDaysAtlanta_2026_Cluster_Destruction_Ignite
./bin/evaluate.sh
```

`evaluate.sh` scores your current setup across all three layers and tells you
which layer to deploy next. No installs, no side effects, no writes.

---

## Then pick a rollout

| You have                          | Run                                    | Time   |
|-----------------------------------|----------------------------------------|--------|
| Nothing yet                       | [START_HERE.md](./START_HERE.md)       | 30 min |
| Local repo, no CI yet             | [layer-1-git-ci/](./layer-1-git-ci/)   | 1 hr   |
| Cluster, no admission policies    | [layer-2-kubernetes/](./layer-2-kubernetes/) | 1 day |
| Devs using Claude Code daily      | [layer-3-claude-hooks/](./layer-3-claude-hooks/) | 30 min |

---

## The repo, at a glance

```
.
├── README.md                       (this file)
├── START_HERE.md                   (30-minute Monday-morning rollout)
├── bin/
│   ├── evaluate.sh                 (score your setup)
│   ├── install-layer-1.sh          (git hooks + pre-commit framework)
│   ├── install-layer-2.sh          (apply Kyverno + Falco to current kubectl context)
│   └── install-layer-3.sh          (copy .claude/ into current repo)
├── layer-1-git-ci/                 (git hooks + GitHub CI)
├── layer-2-kubernetes/             (Kyverno + Falco + RBAC + NetworkPolicy + PSS)
├── layer-3-claude-hooks/           (Claude Code .claude/settings.json + hooks)
└── docs/
    └── three-layers.md             (the full reference — everything below, in one doc)
```

---

## Before you use this on your own infra — edit these first

**These files have placeholder values. Searching for `REPLACE_`,
`your-org`, and the reference repo name will surface all of them.**

| File                                                           | Edit                                                                 |
|----------------------------------------------------------------|----------------------------------------------------------------------|
| `layer-1-git-ci/terraform/branch-protection.tf`                | `repository = "..."` — change to **your** repo name                  |
| `layer-1-git-ci/.github/CODEOWNERS`                            | replace `@your-org/*` team names with real team handles              |
| `layer-2-kubernetes/networkpolicies/ai-workspace.yaml`         | adjust the `10.0.0.0/8` / `172.16.0.0/12` / `192.168.0.0/16` CIDRs to match your node/VPC network |
| `layer-2-kubernetes/pss/ai-agent-worker.yaml`                  | replace `registry.example.io/ai-agent:1.0.0@sha256:REPLACE_WITH_DIGEST` with a real image + digest |
| `layer-2-kubernetes/falco/values.yaml`                         | `REPLACE_WITH_SLACK_WEBHOOK_URL`, `REPLACE_WITH_PAGERDUTY_INTEGRATION_KEY` |

**Start in audit mode, not enforce mode.** Every Kyverno policy ships with
`validationFailureAction: Audit` on purpose. Watch PolicyReports for a
week, confirm zero false positives, then flip to `Enforce`. The one-liner
is in [START_HERE.md](./START_HERE.md) under "Later this week — Layer 2".

---

## Why each layer

**Layer 1 (Git + CI)** — catches destructive *intentions* at commit time,
before any infrastructure touches the change. `--no-verify` bypasses
client-side, but GitHub's required status checks and branch protection run on
GitHub's runners, not the developer's laptop. Free.

**Layer 2 (K8s admission + runtime)** — catches destructive *actions* at the
cluster boundary, even if the commit bypassed review. Kyverno blocks the API
call; Falco sees the syscall on the node. Requires infra.

**Layer 3 (Claude Code hooks)** — catches destructive *tool calls* at the
agent boundary, before the command ever leaves the laptop. The weakest layer
(probabilistic — the agent interprets the rules), but the closest to the
source. Free.

**Start free. Add infra as scale demands.**

---

## The incident that forced this repo to exist

In August 2025, a Claude Code session with direct access to a 9-node
production homelab Kubernetes cluster executed `etcd --force-new-cluster`
during CNI troubleshooting. etcd quorum gone. All 187 pods across 20+
namespaces — Prometheus, Grafana, Loki, Jaeger, Harbor, ArgoCD, Velero — gone
with the cluster state. Recovery took days. Velero was *running* but had
never been tested for restore.

Full write-up: [docs/three-layers.md](./docs/three-layers.md)

The fix wasn't to trust the model more. It was to wrap the model in three
layers of deterministic enforcement so the next `etcd --force-new-cluster`
gets blocked before the command ever runs.

---

## License, sharing, attribution

MIT. Fork it. Lift whole directories into your own repos. Credit appreciated
but not required. The whole point is that this reaches people who need it.

Issues and PRs welcome — especially:

- Falco rules for failure modes this doc doesn't cover yet
- Kyverno policies for managed-control-plane quirks (EKS, GKE, AKS)
- Claude Code hooks for other agent frameworks (Cursor, Aider, Windsurf)
- Translations of README / START_HERE
