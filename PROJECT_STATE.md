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
| DevOpsDays Portland 2026 | 2026-09-10 13:50 | 5-minute Ignite | Delivered |

## Next step

**Portland is delivered.** Nothing in this repo is blocking.

Delivered 2026-09-10, 13:50 PT, Ballroom, fourth of five in a 25-minute Ignite
block. Twenty slides, fifteen-second auto-advance, timed at 4:49 against a
five-minute slot.

### The one open question

The Eight Guardrails Framework does not cover the 2026 incident, and the
framework doc now says so rather than pretending otherwise. All three layers
block **actions**; nothing verifies a **claim**. The fleet report was confident,
specific and false, and no control in the stack would have caught it.

That is either a ninth guardrail, a fold into an existing one, or the thing
`agentic-covenants` exists for. It is a design decision, not a task, and it is
the only substantive item left.

### Settled during the Portland cycle

- **The 2026 incident account.** The fleet was never created; the agent reported
  it as provisioning while the count was zero. Reconstructed with timestamps in
  `incident/2026-FLEET-INCIDENT.md`. Never say 250 clusters were deleted. (#1)
- **This repo is public** and both event repos point here. (#2, #4)
- **Deck rebuilt** and delivered, now `devopsdays-portland-ignite-arcade-v7-with-notes`
  (`1e8pZupiww6PlAjrMMhU22vCJsN_e9zmmrd5rp-OmA54`). Lineage and the versioning
  rule that came out of it are in `presentations/portland-v6-plan.md`. (#3)
- **Published material resynced.** The hooks had drifted four months from what is
  actually run; the framework doc's claim that the agent layer is weak because it
  is probabilistic was wrong and is corrected. Verified against the live vendor
  docs on 2026-09-10. (#6)
- **The abstract correction was dropped** by decision on 2026-09-05. Portland ran
  with the submitted description. The corrected text is kept in
  `abstract/portland-2026-revision.md` for the next submission.

### Carried forward

- Issue #5, a pre-talk article on the 2026 incident, is now necessarily a
  post-talk piece. Rescope or close.
- The deck's speaker notes are unreadable on an Ignite stage with no confidence
  monitor. `presentations/CUE-CARD.md` is the printable answer and was written
  after that was discovered the hard way.

## Branch & Tests
- Branch: main. `staging` is kept fast-forwarded to main and carries no
  independent work.
- Working tree: reconcile with `git status`.
- Tests: `uv run pytest -q`. The suite checks the repo's claims against its own
  contents, not application behavior.
- CI: none configured.

## Phase history
- 2026-08-30 repo established from the SREday and Atlanta material, pushed private
- 2026-09-01 2026 fleet incident documented from the session transcript (#1); repo
  made public; both event repos pointed here (#4); CLAUDE.md corrected from its
  stale venue-specific description
- 2026-09-03 deck rebuilt to v6 and timed to 4:49; original arcade artwork added
  to slide 13; Drive deduped to one file per version
- 2026-09-04 deck PDF sent to talks@devopsdays.org
- 2026-09-05 abstract correction dropped by decision; Portland ran with the
  submitted description
- 2026-09-10 **delivered** at DevOpsDays Portland, 13:50 PT, Ballroom. Published
  hooks resynced from the live set and verified against the vendor docs (#6);
  framework doc's layer-three claim corrected; deck versioned forward to v7 after
  a corrected copy had already reached the organizers
- 2026-09-15 em-dashes removed from authored prose, 19 pre-existing dead links
  repaired, American spellings applied per llm-coding-workflow#153
