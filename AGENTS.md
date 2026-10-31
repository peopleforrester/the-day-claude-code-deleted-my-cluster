# AGENTS.md: The Day Claude Code Deleted My Cluster

Repo rules for agent sessions in this repo. `CLAUDE.md` is a symlink to this
file, so there is one copy. Global rules in `~/.claude/CLAUDE.md` still apply;
this file only adds context specific to this talk.

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

Conference information is not kept here. Which events this talk was given at,
their dates, slots, rooms and recordings live in conference-knowledge
(`~/repos/conferences/conference-knowledge`), `events/registry.yaml`, under
`devopsdays-atlanta-2026`, `sreday-austin-2026` and `devopsdays-portland-2026`.
Read them there. To change them, file an `agent-task` issue on
`peopleforrester/conference-knowledge`; never write into that checkout.

The README's "Given at" table is the public rendering of that record, pinned by
`tests/test_event_details.py`. The delivery tags are under "Delivery tags"
below.

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
source for the Ignite line is `devopsdays-portland-ignite-arcade-v6-with-notes`
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
`~/repos/portfolio/agentic-covenants` (<https://github.com/peopleforrester/agentic-covenants>).
It may be gestured at as a direction in a closing beat. It does not replace the
eight guardrails in any talk whose abstract promised them.

## State persistence

Keep `PROJECT_STATE.md` current at every transition. `/continue` reads it.

Record each decision about the repo or the talk in `decisions.md`, newest
last. It is append-only: never edit a prior entry; correct one with a new
entry that names it.

## Tests

Test command: `uv run pytest -q`

## Where things live

- **The talk register, the research index, and the abstract library:**
  talks-knowledge (`peopleforrester/talks-knowledge`,
  `~/repos/talks/talks-knowledge`). This talk is register row 1, idea
  `deleted-my-cluster`, in `talks/register.md`; its research is indexed in
  `talks/research-index.md`; `abstracts/library.md` records every abstract
  sent out for it. Since 2026-10-11 talks-knowledge also holds the abstracts
  and talk scripts handed over from conference-management. Corrections to the
  register go there as an `agent-task` issue on `peopleforrester/talks-knowledge`.
- **Event state** (conferences, dates, CFPs, acceptances, slots, rooms,
  recordings, contacts and travel): conference-knowledge
  (`~/repos/conferences/conference-knowledge`), `events/registry.yaml` and
  `speaking/`. Read it there and keep no copy here; to change it, file an
  `agent-task` issue on `peopleforrester/conference-knowledge`.
- **The talk itself** (content, argument, incident forensics, guardrails, its
  own current abstract in `abstract/abstract.md`): this repo.
- **Decisions** about this repo: `decisions.md`, append-only. **State:**
  `PROJECT_STATE.md`.

## Delivery tags

Every delivery of this talk is recorded as an annotated git tag, not as a fork
or an event repo. One repo per talk; the event is a tag.

**Name:** `delivered/<event-id>`, where `<event-id>` is the event's `id` in
conference-knowledge `events/registry.yaml` (for example
`devopsdays-portland-2026`). The `delivered/` prefix keeps these clear of semver
tags. `conference-management`'s `check_registry.py` looks for exactly this name
in the repos the registry lists for the event.

**When:** on the day, before or right after walking on stage. Tag the commit
`main` points at when the talk starts. An Ignite cannot be adapted on stage, so
the delivered artifact is the talk, and the next organizer will ask which one
was on screen.

**What the annotation carries,** one line each:

- `Event:` the event name and its registry id
- `Date:` the date, slot time with its time zone, room and format
- `Deck:` the deck name and Google Slides file id actually presented, with the
  file's last-modified time. The decks are native Google Slides, not files in
  this repo, so the tag cannot carry the deck itself; the id and timestamp are
  what pin it.
- `Commit:` `exact` or `approximate`, and why
- `Evidence:` where the deck version and the commit come from

```bash
git tag -a delivered/<event-id> <commit> -F <message-file>
git push origin delivered/<event-id>
```

Then add a row below, and open an issue on `peopleforrester/conference-knowledge`
asking for the tag to be recorded as the event's `delivered_tag`, with this repo
in the event's `repos`.

### Tags so far

| Tag | Commit | Deck presented | Commit is |
|---|---|---|---|
| `delivered/devopsdays-atlanta-2026` | `e8d5a60` | `devopsdays-atlanta-ignite-v5-repo-with-notes`, `1F8QaWE3-JETvsnklZAZwsK-0KCMURkHzW1AxYKSmFpw` | approximate |
| `delivered/devopsdays-portland-2026` | `3c3cb28` | `devopsdays-portland-ignite-arcade-v7-with-notes`, `1e8pZupiww6PlAjrMMhU22vCJsN_e9zmmrd5rp-OmA54` | exact |

Both were tagged retroactively on 2026-10-31 (issue #9).

**Atlanta is approximate** because this repo did not hold the Atlanta material
when the talk was given on 2026-04-21. Its only commit then was the SREday Texas
scaffold, `1979c17`; the Ignite lived in
`peopleforrester/DevOpsDaysAtlanta_2026_Cluster_Destruction_Ignite`. `e8d5a60`
is the first commit here that carries what Atlanta delivered: the incident
forensics and the three-layer install. The deck is the file whose link was sent
to the organizers on 2026-04-20 at 16:57 CDT; it was last modified
2026-04-20T21:54:07Z and has not changed since. The PDF export of the same deck
sits at the root of the Atlanta repo. Nothing records which copy the organizers
put on screen.

**Portland is exact.** `3c3cb28` is the last commit before the 13:50 PT slot
(committed 13:48 PT); the next commit is dated 2026-09-17. The deck was renamed
to v7 and re-sent to the organizers at 10:00 PT on the day, with PDF and PPTX
attached, and they confirmed the update at 10:51 PT. The file was last modified
2026-09-10T16:20:58Z, before the email, and has not changed since.
`presentations/portland-v6-plan.md` records what changed from v6.

The deck named `devopsdays-atlanta-ignite-arcade-v5-with-notes`
(`1Q_S2UDz1F_O8Z-sGjkLy-yIXjycb5jGkAjBK7P_y2fk`) is a copy made on 2026-09-02
during the Portland rebuild. It is not the file presented at Atlanta.

SREday Austin Q2 2026 (registry id `sreday-austin-2026`) is a delivery of this
talk too and is not yet tagged.
