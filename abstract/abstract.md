# The Day an AI Agent Deleted My Cluster (And the Guardrails That Would Have Stopped It)

The current abstract for the 30-minute talk, corrected against the incident
artifacts on 2026-10-31. This is the canonical text: the README defers to this
file rather than carrying its own paraphrase. Use it for the next submission.

The version SREday Austin / Texas 2026 accepted is kept unedited in
[`sreday-austin-2026-as-submitted.md`](sreday-austin-2026-as-submitted.md).

## Format

- **Format:** Talk
- **Duration:** 30 minutes
- **Level:** Intermediate

## Abstract

I gave Claude Code root SSH to my nine-node home-lab Kubernetes cluster
and a prompt to build a cluster to exact versions, with a rule to stop
and ask when stuck. Six minutes into the session it ran `kubeadm reset -f`
across all nine nodes, deleting the etcd data on all three control-plane
members in turn, and flushed iptables and removed the CNI configuration on
every node, workers included. The cluster was gone. Six minutes. No gate
stopped it anywhere in the chain.

This talk is the full incident, rebuilt from the logs, scripts and health
reports the session left behind: the actual command sequence, the reason
the session wrote down for wiping a working cluster, the moment I realized
what was happening, and why the obvious fix (put a human back in the loop)
is the wrong lesson.

The whole point of AI agents in operations is autonomous speed. If
you slow them down with manual approval on every action, you've
just built an expensive autocomplete. The real question is: how do
you let an agent operate fast inside a boundary it can't break out
of?

I spent the next six months answering that question. The result is
an Eight Guardrails Framework enforced across multiple layers of
the stack. I'll show you what those layers are, how they interact,
where each one catches failures the others miss, and why the most
important guardrail is the one most teams skip entirely.

If your team is experimenting with AI agents in infrastructure,
you're going to hit this wall. The question is whether you hit it
in production or in this talk.

## Track Themes

- **Lessons learned**: Real incident, real commands, real recovery.
  Nothing theoretical.
- **Deep dives**, Three-layer guardrail architecture: Git hooks
  (deterministic, local), Claude Code hooks (pre-tool-use blocking),
  Kubernetes infrastructure (admission webhooks, RBAC, Falco
  runtime detection).
- **Culture and ways of working**: Why "the AI knows what it's
  doing" is the most dangerous assumption in modern SRE, and how to
  build operational habits that treat AI agents as nondeterministic
  systems.

## What changed from the as-submitted text

Only the first two paragraphs changed. Paths are under [`../incident/`](../incident/).

| As submitted | Corrected | Source |
|---|---|---|
| "Forty minutes." | "Six minutes into the session" and "Six minutes." | Discovery opens at 21:54:22 UTC (`session-artifacts/kubernetes-fresh-deploy-2025/logs/01-discovery/state-20250823_215422.json`); the etcd wipe is logged at 22:00:35 UTC (`logs/02-reset/reset-20250823_220035.log`, quoted in `ANALYSIS.md` sections 4 and 8). No artifact supports forty. |
| "force-overrode etcd" | "ran `kubeadm reset -f` across all nine nodes, deleting the etcd data on all three control-plane members in turn" | `02-reset-nodes.sh` runs `kubeadm reset -f` in a loop over all nine nodes; the reset log shows kubeadm's own "Deleted contents of the etcd data directory: /var/lib/etcd", and k8s01 to k8s03 ran it in sequence (`ANALYSIS.md` section 4). No artifact shows `--force-new-cluster` or any other force override. |
| "deleted netplan configurations across all control plane nodes" | "flushed iptables and removed the CNI configuration on every node, workers included" | The same script removes `/etc/cni`, `/opt/cni` and `/var/lib/cni` and flushes iptables on every node in `ALL_NODES`, workers included. The netplan changes came later, during the rebuild, and touched the six workers' bridge configuration (`ANALYSIS.md` section 5). |
| "told it to fix a networking issue. It escalated through troubleshooting sessions" | "a prompt to build a cluster to exact versions, with a rule to stop and ask when stuck" | The only surviving prompt is a cluster build (`prompts/my-home-cluster-rebuild-2025-August.md`, rules 2 and 6; `ANALYSIS.md` section 2). The reset came out of that build session's discovery step, not out of troubleshooting. |
| "why the AI thought each escalation was reasonable" | "the reason the session wrote down for wiping a working cluster" | The session transcript no longer exists (`ANALYSIS.md` section 7). What survives of its reasoning is `logs/01-discovery/issues-01.md`: "k8s03 has 4 running containers (damaged cluster)", "Need complete reset before fresh install". |
| (not stated) | "rebuilt from the logs, scripts and health reports the session left behind" | Says what the evidence is, since the transcript is gone (`ANALYSIS.md` section 7, `INDEX.md`). |
| "full Kubernetes cluster access" | "root SSH to my nine-node home-lab Kubernetes cluster" | Every command in `02-reset-nodes.sh` runs as `ssh root@$ip`. Nine nodes per `reports/cluster-health-report-2025-07-16.md`. |
