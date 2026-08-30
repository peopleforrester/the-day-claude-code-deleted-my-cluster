# Home Lab Incident Recovery — August/September 2025

Artifacts recovered from git history (via `git show <commit>:<path>`) related to
the August 2025 home lab cluster rebuild incident where a Claude Code session
initialized a new etcd cluster (overwriting the existing one) and modified
netplan files across the Linux nodes.

**Start here:** [`ANALYSIS.md`](ANALYSIS.md) — presentation-ready deep analysis
with timeline, root causes, and citations back into these artifacts.

## Source of truth
Files originate from commits `69a2f0b` (2025-08-28), `3e2d4a3` (2025-09-03),
and `e4719dd` (2025-09-03) in `mforrester-home-lab`. Most were moved into
`archive/k8s-cluster-build-v1.33.4/` by commit `72eff3f` (2026-01-20 "Major
cleanup"). Recovered on 2026-04-19.

## Second recovery pass (2026-04-19)
The initial recovery captured only the `archived-deployments/` tree. A second
pass pulled the live-cluster scripts that actually caused the damage:
- `session-artifacts/kubernetes-fresh-deploy-2025/` — the scripts that ran
  against production nodes `192.168.0.50–58` on 2025-08-23
- `session-artifacts/kubernetes-upgrade/` — the Ansible framework used earlier
  (including the 20,128-line `ansible-upgrade.log` from 2025-08-19)
- `session-artifacts/archive-v1.33.4/` — the full working tree from the
  post-incident rebuild, including `bridge-setup/`, `network/mac-fix-*.sh`,
  and `health-check/` reports that document the netplan/MAC fallout

## Note on raw session transcript
The original Claude Code session `.jsonl` transcript no longer exists on this
machine — `~/.claude/projects/` only retains sessions back to January 2026. The
artifacts below are the next-best substitute: step-by-step logs, scripts, and
state files the session produced as it ran.

---

## Directory layout

### prompts/
- **my-home-cluster-rebuild-2025-August.md** (480 lines)
  The exact prompt given to Claude that initiated the rebuild. Specifies
  Kubernetes v1.33.4, containerd v2.1.4, Cilium v1.18.0, etc. with strict
  "no workarounds" and "INTERACTIVE RESOLUTION" rules that were not followed.
  Originally committed 2025-09-03 in `e4719dd`.

### reports/
- **cluster-health-report-2025-07-16.md** — Baseline pre-incident health (commit `d5cd5b3`)
- **k8s01-crash-analysis.md** — k8s01 crash investigation from 2025-07-31 (commit `766754a`)
- **kubernetes-cluster-architecture-summary.md** — Architecture as of July 2025 (commit `eb828d0`)
- **cluster-health-report-2025-09-02.md** — Post-rebuild cluster state (commit `e4719dd`)
- **metrics-flow-investigation-report.md** — Observability analysis post-rebuild

### commit-diffs/
Commit metadata (file stats, not full diffs) for the three commits that
captured the rebuild work:
- **aug28-cluster-infrastructure-fixes.txt** — commit `69a2f0b`: 66 files, +49,795 lines
- **sep03-k8s-deployment-scripts.txt** — commit `3e2d4a3`: 384 files, +51,173 lines
- **sep03-documentation-update.txt** — commit `e4719dd`: the doc commit

### session-artifacts/
Contents of the `library/kubernetes/deployments/archived-deployments/` tree
from commit `3e2d4a3`. This is the closest thing to a session history we have.

Key subdirectories:
- **k8s-cluster-build/** — Main cluster build with 13 numbered step directories
  (01-connectivity through 13-final-validation). Each contains `status.json`,
  `*.log` files, and the scripts executed.
- **k8s-cluster-build_vAug24th/** — Earlier attempt from Aug 24 with a slightly
  different step breakdown (includes `05-ha-setup/etcd-encryption-config.yaml`)
- **kubeadm_k8s_deployment_v2/** / **kubeadm_k8s_deployment_v4/** — Deployment
  variants
- Plus top-level scripts: `deploy_k8s_cluster.sh`, `init_master.sh`,
  `fix_dns_and_install.sh`, etc.

---

## Recovery commands (for reference)
If you need to pull additional files from the same era:

```bash
# List files in the Sept 3 archive commit
git ls-tree -r --name-only 3e2d4a3 | grep archived-deployments

# Extract a specific file
git show e4719dd:"documentation/prompts/my home cluster rebuild 2025 August"

# Find all commits touching a path
git log --all --full-history -- "path/to/file"
```

## Related commits timeline

| Date       | Commit    | Summary                                         |
|------------|-----------|-------------------------------------------------|
| 2025-07-16 | d5cd5b3   | Repository reorganization (pre-incident)        |
| 2025-07-31 | 766754a   | Add k8s01 monitoring with email alerts          |
| 2025-08-24 | 765790e   | Add comprehensive health check scripts          |
| 2025-08-28 | 69a2f0b   | Add cluster infrastructure fixes and Longhorn   |
| 2025-09-03 | 3e2d4a3   | Add Kubernetes deployment scripts (archived)    |
| 2025-09-03 | e4719dd   | Update documentation and reports (+ prompt file)|
| 2026-01-20 | 72eff3f   | Major cleanup (deleted the files above)         |
