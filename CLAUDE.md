# CLAUDE.md — The Day Claude Code Deleted My Cluster

Project-specific instructions for Claude Code sessions in this repo.
Global rules in `~/.claude/CLAUDE.md` still apply; this file only adds
context specific to this talk.

## What this repo is

This is the **canonical, event-neutral home** for the talk. It is named for
the talk rather than for any conference, because the talk has been delivered
more than once and will be again. **This repo owns the material.** Event repos
point here.

It is **public**.

## Source of truth

This repo is the source of truth. Two repos that used to hold pieces of it are
now records of their own delivery only, and both link back here:

- `peopleforrester/SREday-Texas-2026` (public)
- `peopleforrester/DevOpsDaysAtlanta_2026_Cluster_Destruction_Ignite` (public)

`~/repos/_archive/events/claude-deleted-my-cluster-2026/` is an **archived**
predecessor. Do not treat it as authoritative; its forensics were folded into
`incident/` during the 2026-08-30 consolidation.

## Delivery record

| Event | Date | Format | Status |
|---|---|---|---|
| DevOpsDays Atlanta 2026 | 2026-04-21 | 5-minute Ignite, 20 slides | Delivered |
| SREday Austin Q2 2026 | 2026-05-11 12:30 | 30 minutes | Delivered |
| DevOpsDays Portland 2026 | 2026-09-10 13:50 PT | 5-minute Ignite, 20 slides | Upcoming |

## The two incidents

Keep them distinct. They are different failures and the talk needs both.

**2025, home lab.** An agent with cluster access initialised a new etcd cluster
over the existing one and modified netplan across the Linux nodes. Documented
in [`incident/ANALYSIS.md`](incident/ANALYSIS.md), recovered from git history in
`mforrester-home-lab`.

**2026, AI Engineer World's Fair.** An agent reported a 250-cluster workshop
fleet as provisioning when **zero clusters existed**, and held that report
through to showtime in front of roughly 250 people. Documented in
[`incident/2026-FLEET-INCIDENT.md`](incident/2026-FLEET-INCIDENT.md), quoted
with timestamps from the `Unleash an Agent, Watch It Burn` session transcript.

**The 250 were never created. They were not deleted.** Any phrasing that says
250 clusters were destroyed is wrong and must not reach a slide. The number 250
is correct as the fleet that was requested, promised and falsely reported.

## Deck sources

The decks are **native Google Slides**, not files in this repo. The editable
source for the Ignite line is `devopsdays-atlanta-ignite-arcade-v5-with-notes`
(`1e8pZupiww6PlAjrMMhU22vCJsN_e9zmmrd5rp-OmA54`) in Michael's personal Drive.
Use `gog -a michaelrishiforrester@gmail.com` to reach it. The twenty-slide
scripts live beside them as `devopsdays-atlanta-ignite-outline-*.md`.

## Workflow in this repo

- `main` is the working branch. `staging` exists and is kept fast-forwarded to
  `main`; it carries no independent work.
- Commits: professional tone, no AI or Claude attribution.
- Public repo. Nothing lands here that is not safe to publish. Session
  transcripts with credentials, attendee emails, AWS account identifiers, and
  unredacted customer data stay out; cite them by path instead.

## Asset policy

- **Presentation source is committed; PDF exports are not.** `.gitignore`
  ignores `presentations/*.pdf` and `outline/*.pdf`.
- **Publishable PDFs** (a slides-as-delivered handout) belong in `post-event/`.
- **Rehearsal recordings** (`*.wav`, `*.m4a`) are gitignored.

## When working on deck / outline / speaker notes

- The Eight Guardrails Framework is the load-bearing structure. Do not rename,
  renumber, or reorder the guardrails; they are referenced externally.
- Quotes and command lines pulled from either incident must match the session
  record exactly. Never paraphrase a destructive command, or a false status
  report, for slide polish. If it reads awkwardly, annotate it; do not rewrite.
- Ignite is 5 minutes and 20 auto-advancing slides. Script and slide count are
  locked together, so a revision is a rewrite, not a find-and-replace.

## Framework evolution: `agentic-covenants`

The next evolution beyond the Eight Guardrails lives in
`~/repos/events/agentic-covenants` (<https://github.com/peopleforrester/agentic-covenants>).
It may be gestured at as a direction in a closing beat. It does not replace the
eight guardrails in any talk whose abstract promised them.

## State persistence

Keep `PROJECT_STATE.md` current at every transition. `/continue` reads it.
