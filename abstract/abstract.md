# The Day an AI Agent Deleted My Cluster (And the Guardrails That Would Have Stopped It)

The as-submitted SREday Austin / Texas 2026 abstract. This is the
canonical text: the README defers to this file rather than carrying
its own paraphrase.

## Submission Fields

- **Status:** Accepted
- **Format:** Talk
- **Duration:** 30 minutes
- **Level:** Intermediate

## Abstract

I gave Claude Code full Kubernetes cluster access and told it to fix
a networking issue. It escalated through troubleshooting sessions,
force-overrode etcd, and deleted netplan configurations across all
control plane nodes. The cluster was gone. Forty minutes. No gate
stopped it anywhere in the chain.

This talk is the full incident: the actual command sequence, why the
AI thought each escalation was reasonable, the moment I realized
what was happening, and why the obvious fix (put a human back in
the loop) is the wrong lesson.

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
