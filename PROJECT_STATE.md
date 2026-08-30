# Project State: the-day-claude-code-deleted-my-cluster

Phase: 3.3 Promote
Approved: pending

Canonical repo: `peopleforrester/the-day-claude-code-deleted-my-cluster` (private).
Durable project state. Read this first at the start of any session, then reconcile
against `git log`, `git status`, and the test suite.

## Lifecycle
- [x] 1.1 Research
- [x] 1.2 Plan
- [ ] 1.3 Approve
- [x] 2.1 Test
- [x] 2.2 Implement
- [x] 2.3 Verify
- [x] 3.1 Stage
- [ ] 3.2 Confirm CI
- [x] 3.3 Promote

## Contracts
None sealed. The consolidation was carried out under an explicit instruction on
2026-08-30 rather than a written plan.

## What this repo is

The canonical home for the talk, named for the talk rather than any one
conference, because it has been delivered three times under three formats. Event
repos point here; the material lives here.

Seeded from the SREday Austin history, which carried the Eight Guardrails
Framework, the hook implementations, the CI workflows, and the only editable deck
source. The incident forensics and the runnable three-layer install came from the
DevOpsDays Atlanta ignite repo.

## Delivery record

| Event | Date | Format | Status |
|---|---|---|---|
| DevOpsDays Atlanta 2026 | 2026-04-21 | 5-minute Ignite | Delivered |
| SREday Austin Q2 2026 | 2026-05-11 12:30 | 30 minutes | Delivered |
| DevOpsDays Portland 2026 | 2026-09-10 13:50 | 5-minute Ignite | Upcoming |

## Next step

Portland is the live work, and it is tracked as issues on
`peopleforrester/DevOpsDaysAtlanta_2026_Cluster_Destruction_Ignite` because they
were filed before this repo existed. Move or re-file them here.

In priority order:

1. **Settle the incident account.** The long form describes a networking task and a
   forty-minute damage window; the Portland abstract describes full pipeline access
   and stepping away for thirty seconds. Both are probably true of the same event.
   Five minutes has no room to be vague. Check the deck against
   `incident/ANALYSIS.md`.
2. **Resolve what the 2026 escalation actually is.** The submitted Portland abstract
   says 250 clusters were deleted. Michael's account on 2026-08-27 is that the agent
   reported provisioning a 250-cluster set it had not provisioned. Those are
   different stories and the abstract is public.
3. **Build the Portland deck.** Five minutes, twenty slides, auto-advancing. The
   SREday PPTX is the editable base; the Atlanta PDF is the previous Ignite cut.
4. **Consider the redaction beat for the close.** See `incident/REDACTIONS.md`.

## Branch & Tests
- Branch: main. Content repo, no staging gate.
- Working tree: reconcile with `git status`.
- Tests: `uv run pytest -q`. The suite checks the repo's claims against its own
  contents, not application behaviour.
- CI: none configured.

## Phase history
- 2026-08-30 repo established from the SREday and Atlanta material, pushed private
