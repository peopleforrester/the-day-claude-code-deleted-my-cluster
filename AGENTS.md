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
E2E command: `uv run --group e2e pytest -q e2e`

The Test command collects `tests/` only and runs offline. The E2E command runs
`e2e/`, which checks the repo's claims against live services: every recording
the README's "Given at" table links resolves on YouTube as this talk;
`scripts/check-talk-video.sh`, unstubbed, reads FOUND for the Portland Ignite
on the live channel; every tag in "Tags so far" is named, with its event
id, on the conference-knowledge issue its row says reported it; and every
action the kit templates and root `workflows/` pin by SHA is the commit its
version comment's tag names on GitHub. It needs the network, `git`, the `e2e`
dependency group's pinned `yt-dlp`, and `gh` with read access to
`peopleforrester/conference-knowledge`, which is private, and fails when any
is missing.

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

Write the annotation to `delivery-tags/<event-id>.txt` and commit it, so the tag
can be rebuilt from this repo if the clone that made it is lost before the
push. Tag with a fixed tagger date and `--cleanup=verbatim`, so the tag object
is the file byte for byte:

```bash
GIT_COMMITTER_DATE='<epoch> +0000' git tag -a --cleanup=verbatim \
  delivered/<event-id> <commit> -F delivery-tags/<event-id>.txt
git push origin delivered/<event-id>
```

Without a clone that can push, the same object is made on GitHub with
`gh api repos/peopleforrester/the-day-claude-code-deleted-my-cluster/git/tags`
(fields `tag`, `object` as the full commit SHA, `type=commit`, `message` read
with `-F message=@delivery-tags/<event-id>.txt`, and `tagger[name]`,
`tagger[email]`, `tagger[date]` as the local tag has them), then `.../git/refs`
with `ref=refs/tags/delivered/<event-id>` and `sha` as the tag object's SHA.
GitHub refuses the ref if the object it made differs from the local one.

Then open an issue on `peopleforrester/conference-knowledge` asking for the
tag to be recorded as the event's `delivered_tag`, with this repo in the event's
`repos`, and add a row below whose "Reported in" cell names that issue. That
issue is how `conference-management` learns of the tag; a tag no issue names is
not reported. Adding to an open issue already asking for other tags counts, as
long as its body or a comment names the tag and the event id.

### Tags so far

| Tag | Commit | Deck presented | Commit is | Reported in |
|---|---|---|---|---|
| `delivered/devopsdays-atlanta-2026` | `e8d5a60` | `devopsdays-atlanta-ignite-v5-repo-with-notes`, `1F8QaWE3-JETvsnklZAZwsK-0KCMURkHzW1AxYKSmFpw` | approximate | `peopleforrester/conference-knowledge#205` |
| `delivered/devopsdays-portland-2026` | `3c3cb28` | `devopsdays-portland-ignite-arcade-v7-with-notes`, `1e8pZupiww6PlAjrMMhU22vCJsN_e9zmmrd5rp-OmA54` | exact | `peopleforrester/conference-knowledge#205` |
| `delivered/sreday-austin-2026` | `aedb2e2` | `sreday-austin-2026-deck-arcade.pptx`, `1l0Ql3MW3DsrK32x8RrZKa6MVi7A9wxc2` | approximate | `peopleforrester/conference-knowledge#205` |

Atlanta and Portland were tagged retroactively on 2026-10-31 (issue #9), and
SREday Austin the same day (issue #30). Each tag was made in a run's clone; none
is on the GitHub remote yet, and the push is escalated from each issue. #9's
clone was lost before its push ran, so Atlanta and Portland were recreated
under issue #44 from `delivery-tags/`, tagger `hecaton <hecaton@localhost>`
at `2026-10-31T16:00:00Z` (`1793462400 +0000`). Their push is escalated from
issue #44 as `gh api` calls, and the tag objects it must produce are:

- `delivered/devopsdays-atlanta-2026`: tag object `578f7ab1e0f360501b72018fd7c1e0f093421253`
- `delivered/devopsdays-portland-2026`: tag object `1ba778c6824f62cee8b5ef9fdf8fff3894c35401`

SREday Austin's annotation is in #30's escalation, not in `delivery-tags/`. All
three are reported on conference-knowledge#205: Atlanta and Portland in its
body, SREday Austin in a comment added from #30, because no separate issue was
filed for it. That issue waits on the push, since `check_registry.py` reports a
`delivered_tag` missing until the tag is on GitHub.

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

**SREday Austin is approximate.** The 30-minute talk ran 12:30 to 13:00 CDT on
2026-05-11 (17:30 to 18:00 UTC), per the registry, Michael's calendar and the
SREday repo's README. `aedb2e2` (17:23 UTC, the pre-show cleanup) is the last
commit before the slot, so it is what `main` held when the talk started; the
next, `9c7291e`, is a web upload at 18:03 UTC. Unlike the Ignites, this deck is
in the repo: `presentations/sreday-austin-2026-deck-arcade.pptx`, edited in
Google Slides as Drive file `1l0Ql3MW3DsrK32x8RrZKa6MVi7A9wxc2`, a PPTX rather
than a native Slides file. That file was last modified 2026-05-11T18:03:17Z,
three minutes after the slot ended, and has not changed since. `9c7291e`
commits it 31 seconds later, same size, and its `docProps/core.xml` carries the
same modified time.

The copy committed at `aedb2e2` (uploaded in `ebd478a` at 15:24 UTC) is not
what was on screen. The recording (`EoQ-knQKMek`, 26:34) shows slide 16 three
quarters of the way through reading "DON'T USE PROBABILISTIC AI (ALONE)", a
wording only `9c7291e` has. `9c7291e` changes slides 3, 10, 16, 17, 19 and 20
and drops the reading-list slide; only the slide 16 change is confirmed on
screen, and nothing records which edits came after the slot. The backup the
organizers were mailed at 15:18 UTC is the first upload, `3976399`, older
still. The tag stays on `aedb2e2` because the convention tags `main` at the
start; check out `9c7291e` for the deck as shown.
