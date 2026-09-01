# Project State: the-day-claude-code-deleted-my-cluster

Phase: 3.3 Promote
Approved: pending

Canonical repo: `peopleforrester/the-day-claude-code-deleted-my-cluster` (public).
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

Portland is the live work, 2026-09-10. Issues are filed on this repo.

Settled on 2026-09-01:

- **The 2026 incident account.** The 250-cluster fleet was never created; the
  agent reported it as provisioning while the count was zero. Written up in
  `incident/2026-FLEET-INCIDENT.md` from the session transcript with timestamps.
  The abstract's "it was 250, gone" is wrong and needs one word changed. (#1)
- **This repo is public**, and both event repos now point here. (#2, #4)
- **The deck source was never missing.** It is a native Google Slides file,
  `devopsdays-atlanta-ignite-arcade-v5-with-notes`
  (`1e8pZupiww6PlAjrMMhU22vCJsN_e9zmmrd5rp-OmA54`), plus the twenty-slide
  outline markdown beside it in Drive.

Remaining:

1. **Build the Portland deck as v6** from the Drive source. Five minutes, twenty
   slides, auto-advancing. The 2026 incident is the escalation and has to earn
   its slides without pushing out the guardrails payoff. (#3)
2. **Decide the outline-as-source question.** Committing the twenty-slide
   outline markdown makes v7 start from text rather than a PDF; the deck stays
   a rendering of it. (#3)
3. **Decide whether the framework needs a ninth guardrail** for
   verification-of-claims, or whether that folds into an existing one. The 2026
   incident is not covered by the eight as written.
4. **Consider the redaction beat for the close.** See `incident/REDACTIONS.md`.

## Branch & Tests
- Branch: main. `staging` is kept fast-forwarded to main and carries no
  independent work.
- Working tree: reconcile with `git status`.
- Tests: `uv run pytest -q`. The suite checks the repo's claims against its own
  contents, not application behaviour.
- CI: none configured.

## Phase history
- 2026-08-30 repo established from the SREday and Atlanta material, pushed private
- 2026-09-01 2026 fleet incident documented from the session transcript (#1); repo
  made public; both event repos pointed here (#4); CLAUDE.md corrected from its
  stale venue-specific description
