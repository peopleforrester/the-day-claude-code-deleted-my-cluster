Test command: `uv run pytest -q`

## Where things live

- Conferences, dates, slots, rooms, recordings, contacts and travel:
  conference-knowledge (`~/repos/conferences/conference-knowledge`),
  `events/registry.yaml` and `speaking/`. Read it there and keep no copy here;
  to change it, file an `agent-task` issue on `peopleforrester/conference-knowledge`.
- The talk itself (content, argument, abstracts, research): this repo, indexed
  from talks-knowledge (`~/repos/talks/talks-knowledge`).

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
