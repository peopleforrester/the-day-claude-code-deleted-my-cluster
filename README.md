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

## What is here

| Path | What |
|---|---|
| [`incident/`](incident/) | The forensics. Session artifacts, the prompts that ran, recovered scripts, commit diffs, and the analysis with citations |
| [`docs/the-framework.md`](docs/the-framework.md) | The **Eight Guardrails Framework**, with the bypass column filled in for every enforcement artifact |
| [`hooks/`](hooks/) | The enforcement artifacts themselves: eight agent lifecycle hooks and two git hooks, copy-paste ready |
| [`workflows/`](workflows/) | CI and end-to-end workflows as the defence-in-depth backstop |
| [`guardrails-three-layer/`](guardrails-three-layer/) | The Ignite-length condensation: three layers, an install script each, and a Monday-morning rollout with a clock on it |
| [`abstract/`](abstract/) | As-submitted abstracts and speaker bio |
| [`presentations/`](presentations/) | Decks. The SREday PPTX is the editable source; the Atlanta PDF is the Ignite cut |
| [`tests/`](tests/) | Consistency checks over the repo's own claims |

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

The incident is told slightly differently across versions. The long form describes
a networking task and a forty-minute timeline; the Portland abstract describes full
pipeline access and stepping away for thirty seconds. Both are probably true of the
same event, the first being the damage window and the second the moment of handing
over. A five-minute talk has no room to be vague about which, so the deck should
commit to one telling and check it against `incident/ANALYSIS.md`.
