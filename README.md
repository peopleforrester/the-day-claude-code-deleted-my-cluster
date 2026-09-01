# The Day Claude Code Deleted My Cluster

**Canonical home for the talk, its evidence, and the guardrails that came out of it.**

This repo is named for the talk rather than for any one conference, because the
talk has been given more than once and will be again. Event-specific repos point
here; the material lives here.

## Given at

| Event | Date | Format | What that version emphasised |
|---|---|---|---|
| DevOpsDays Atlanta 2026 | 2026-04-21 | 5-minute Ignite, 20 slides | The incident, closing on three deterministic layers |
| SREday Austin Q2 2026 | 2026-05-11, 12:30 | 30 minutes | Full incident forensics plus the Eight Guardrails Framework |
| DevOpsDays Portland 2026 | 2026-09-10, 13:50 | 5-minute Ignite, 20 slides | In preparation |

The Ignite came first and the long form followed. The three-layer model is the
five-minute condensation; the Eight Guardrails Framework is the full articulation.
Neither supersedes the other, and which one you want depends on how many minutes
you have.

## The incident

A home-lab Kubernetes cluster, August and September 2025. An agent session with
cluster access initialised a new etcd cluster over the existing one and modified
netplan across the Linux nodes. The cluster was gone and the nodes lost their
networking.

It is documented from primary sources, not reconstructed from memory: the session
transcripts, the command history, and the scripts that actually ran, all recovered
from git history in `mforrester-home-lab` and cited back to specific commits. See
[`incident/INDEX.md`](incident/INDEX.md) for the provenance and
[`incident/ANALYSIS.md`](incident/ANALYSIS.md) for the timeline and root causes.

**The 2026 escalation.** AI Engineer World's Fair, San Francisco, 2026-06-29. A
250-cluster workshop fleet was requested two hours before the room. The agent
reported "150 clusters are provisioning concurrently" while the count was zero,
because it measured `grep` hits over local Terraform logs instead of asking AWS.
Roughly 250 people sat down to eleven instructor clusters, claimed in eight
seconds. See [`incident/2026-FLEET-INCIDENT.md`](incident/2026-FLEET-INCIDENT.md)
for the timeline, quoted from the session transcript.

## What's in this repo

- [**`incident/`**](incident/) — the forensics. Session artifacts, the prompts that
  ran, recovered scripts, commit diffs, and the analysis with citations, plus the 2026
  fleet incident. Credential
  values are redacted; see [`incident/REDACTIONS.md`](incident/REDACTIONS.md).
- [**`docs/`**](docs/) — the **Eight Guardrails Framework**
  ([`the-framework.md`](docs/the-framework.md)), with the bypass column filled in for
  every enforcement artifact.
- [**`hooks/`**](hooks/) — the enforcement artifacts themselves: eight agent
  lifecycle hooks and two git hooks, copy-paste ready.
- [**`workflows/`**](workflows/) — CI and end-to-end workflows, the defence-in-depth
  backstop.
- [**`guardrails-three-layer/`**](guardrails-three-layer/) — the Ignite-length
  condensation: three layers, an install script each, and a Monday-morning rollout
  with a clock on it.
- [**`abstract/`**](abstract/) — as-submitted abstracts and speaker bio. The
  canonical text is [`abstract/abstract.md`](abstract/abstract.md).
- [**`presentations/`**](presentations/) — decks. The SREday PPTX is the editable
  source; the Atlanta PDF is the Ignite cut.
- [**`tests/`**](tests/) — consistency checks over the repo's own claims.

## Just saw the talk

Two entry points.

**Understand the model.** [`docs/the-framework.md`](docs/the-framework.md) is the
full four-layer mental model with what each control catches and what gets past it.

**Install it Monday morning.**
[`guardrails-three-layer/START_HERE.md`](guardrails-three-layer/START_HERE.md) is
the fastest path: Layer 1 green by lunch, Layer 3 by end of day, Layer 2 planned by
Friday. About thirty minutes for the minimum posture.

## Provenance

Seeded from `peopleforrester/SREday-Texas-2026`, whose git history this repo
carries, with the incident forensics and the three-layer install brought over from
`peopleforrester/DevOpsDaysAtlanta_2026_Cluster_Destruction_Ignite`. Both remain in
place as records of their own deliveries and point here.

## Open

The two incidents are different failures. 2025 is an agent that destroyed
infrastructure; 2026 is an agent that reported infrastructure it had never
created. The Eight Guardrails Framework was written against the first. Whether
it needs a ninth control for verification-of-claims, or whether that belongs
inside an existing guardrail, is unsettled.

## License

MIT. See [`LICENSE`](LICENSE). The incident artifacts are included as evidence for
the talk; reuse them freely.
