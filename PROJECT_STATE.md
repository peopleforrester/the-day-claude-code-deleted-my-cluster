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

Kept in conference-knowledge, `events/registry.yaml`, under
`devopsdays-atlanta-2026`, `sreday-austin-2026` and `devopsdays-portland-2026`:
dates, slots, rooms and recordings. The README's "Given at" table is the public
rendering. This repo keeps no other copy (#13).

## Next step

**Portland is delivered.** Nothing in this repo is blocking.

The Ignite ran twenty slides on a fifteen-second auto-advance, timed at 4:49
against a five-minute slot. Its slot and room are in the registry.

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

### The recordings are up

Both Ignites are published: Portland at
<https://www.youtube.com/watch?v=rUJ07SnFsXA> (uploaded 2026-10-09, 29 days
after the talk) and Atlanta at <https://www.youtube.com/watch?v=ts0ZnPDrBRI>
(2026-05-15, 24 days). `post-event/portland-2026-recording.md` sets the
Portland delivery against the cue card: no silence longer than 1.8 seconds,
slide 9 and the slide 20 close not heard, and a close that can be heard as the
250 being deleted. The video's description repeats the uncorrected abstract's
"deleted 250 clusters". (#8) It stays as published: the 2026-09-05 decision
covers the recording, and no correction is requested (#28, `decisions.md`).

The weekly watch on netcup has done its job and should be removed; it now
mails on every Monday's run.

### Carried forward

- Issue #5 is now a post-talk article: the guardrails presented in the talk do
  not cover the failure that actually happened. It is the same open question as
  above, written for publication rather than resolved. Publication is owned by
  `mrf-engagement-orchestrator`.
- The deck's speaker notes are unreadable on an Ignite stage with no confidence
  monitor. `presentations/CUE-CARD.md` is the printable answer and was written
  after that was discovered the hard way.

## Branch & Tests
- Branch: main. `staging` is kept fast-forwarded to main and carries no
  independent work.
- Working tree: reconcile with `git status`.
- Tests: `uv run pytest -q`. The suite checks the repo's claims against its own
  contents, not application behavior.
- E2E: `uv run --group e2e pytest -q e2e`. Checks the linked recordings and the
  video check against live YouTube, and each delivery tag's report on its
  conference-knowledge issue; needs the network, the pinned `yt-dlp`, and `gh`
  with read access to conference-knowledge.
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
- 2026-10-31 Portland and Atlanta recordings found and linked from the delivery
  record; delivery reviewed against the cue card; the video check's pattern
  narrowed after it mailed a false hit on other speakers' Ignites (#8)
- 2026-10-31 `delivered/<event-id>` tag convention written into AGENTS.md; Atlanta
  and Portland tagged retroactively (#9). The tags are pushed separately from
  the branch
- 2026-10-31 SREday Austin tagged `delivered/sreday-austin-2026` on `aedb2e2`,
  approximate (#30): the last commit before the 17:30 UTC slot, but the
  recording shows a deck correction that only `9c7291e` (18:03 UTC) carries.
  The tag is in the run's clone; its push is escalated
- 2026-10-31 video-check cron confirmed running after the events/ to talks/
  move: the tracked line resolves the repo through `sk-repo`, and it mailed at
  09:17 on 10-05, 10-12, 10-19 and 10-26. The script's install comment, the last
  copy of the old path, now matches it (#10). Removing the job is
  llm-coding-workflow#470
- 2026-10-31 `~/repos` paths rechecked after the tree restructure (#12): the
  the one dead path, CLAUDE.md's `events/agentic-covenants`, was already
  corrected to `portfolio/agentic-covenants` under #11; the other five resolve,
  and `courses/` is Accenture-only. `tests/test_repo_paths.py`, which #11 added
  for `events/`, now covers every root the issue lists as retired
- 2026-10-31 `tests/test_repo_paths.py` now also requires AGENTS.md's
  framework-evolution section to name `~/repos/portfolio/agentic-covenants`, so a
  different wrong path fails, not only the retired one (#37)
- 2026-10-31 abstract corrected against the incident artifacts (#15): six
  minutes, not forty; `kubeadm reset -f`, not a force override; iptables and CNI
  on all nine nodes, not netplan on the control plane; logs, not transcripts.
  The SREday text is kept unedited as `abstract/sreday-austin-2026-as-submitted.md`.
  README, framework doc and guardrail docs fixed to match; the delivered decks
  are left as records, with their mismatches listed in `presentations/README.md`
- 2026-10-31 the room transcript of the Portland delivery (`My recording 214.mp3`),
  stranded uncommitted in the archived `walkthrough-agenticburn`, collected as
  `post-event/portland-2026-transcript.md` with its provenance and hash; the
  suite pins the original bytes (#25)
- 2026-10-31 conference-knowledge made the source of truth for conference
  information (#13). The delivery tables in CLAUDE.md and here replaced with
  pointers to its `events/registry.yaml`; the README's "Given at" table kept as
  the public rendering, with the SREday recording the registry already had
  (`EoQ-knQKMek`, checked against YouTube's oEmbed) replacing "none linked".
  What the registry lacks (both Ignite recordings, this repo in SREday's
  `repos`) handed off to conference-knowledge in an `agent-task` issue
- 2026-10-31 identity check for the talk-repo fleet standard (#16): the rules
  in CLAUDE.md merged into AGENTS.md and CLAUDE.md made a symlink to it;
  "Where things live" names talks-knowledge for the register, research index
  and abstracts, and conference-knowledge for event state; `decisions.md`
  started, append-only, with the earlier decisions carried from this file;
  the README gains "About this talk" (speaker, argument, status, built from).
  `tests/test_identity.py` pins all four
- 2026-10-31 `check-commit-message.sh` sourced its attribution library from
  `../../scripts/git-hooks/lib/`, a path in the working set it was synced from
  that was never published, so an installed copy refused every commit whose
  message it could read (#18). The library is published beside it as
  `hooks/claude-code/lib/check-ai-attribution.sh`, the hook reads it from
  `lib/`, and the install step copies `lib/` too. The suite now runs the hook
  on clean and attributed messages, both in place and as installed
- 2026-10-31 the monthly security scan (infrastructure-security-scanning#129)
  found credentials the first redaction pass missed in
  `incident/session-artifacts/` (#26): the one kubeconfig client key, 12
  kubeadm certificate keys and 6 HAProxy stats passwords. All are redacted,
  `incident/REDACTIONS.md` counts them, and `tests/test_redactions.py` holds
  the table to the markers and fails on those shapes in the clear. The values
  stay in `e8d5a60`'s history and the archived Atlanta repo
- 2026-10-31 the guardrails kit's workflow templates, which `install-layer-1.sh`
  and `START_HERE.md` copy into readers' repos, cleared of the 31 zizmor
  findings infrastructure-security-scanning#129 reported (#27): every action
  pinned by commit SHA with its release in a comment, write permissions moved
  to the jobs that use them, checkout credentials dropped. trivy-action moves
  from `0.28.0`, a tag that no longer exists, to 0.35.0, the release the March
  2026 advisory names safe. `tests/test_workflow_templates.py` holds them to it.
  `START_HERE.md` still clones the archived Atlanta repo, whose copies are unfixed
- 2026-10-31 E2E command declared in AGENTS.md: `e2e/` checks the README's
  recording links and the unstubbed video check against live YouTube (#24)
- 2026-10-31 the Portland recording's description ("deleted 250 clusters") is
  left as published: the 2026-09-05 "do not re-raise it for Portland" covers it
- 2026-10-31 the delivered v7 Ignite read from its Drive export for the deck fix
  (#33). Slide 7 is `$ etcd --force-new-cluster ...` as the cue card says;
  slide 6's "Applying force override..." and slide 10's "HOUR 1 / etcd
  force-overwritten" change with it, and the JUNIOR DEV slide sits nineteenth
  instead of ninth. All listed in `presentations/README.md`. The fix itself
  waits for the next delivery to be booked, as #33 asks; none is booked yet
  (#28). The pretalx page carries the same text. If it is ever reopened, the
  organizers' address is `portland-or@devopsdays.org`, not `talks@`
- 2026-10-31 each delivery tag's report is pinned (#32): AGENTS.md's "Tags so
  far" gains a "Reported in" column naming the conference-knowledge issue, #205
  for all three. `tests/test_delivery_tags.py` requires it on every row, and
  `e2e/test_tag_reports_live.py` reads the issue through `gh` to check it names
  each tag and event id
- 2026-10-31 the live source of `hooks/git/pre-push` is
  `llm-coding-workflow/scripts/git-hooks/pre-push`, and it still has both
  secret-scan bugs fixed here: `grep -EnP` (edf8046) and grep piped into `head`
  under pipefail. The fix there is a follow-up filed in llm-coding-workflow,
  outside this repo. `hooks/README.md` now says the mirror is ahead on that
  scan and keeps the 2026-09-10 sync date until the resync, which must also
  take in the live hook's later changes (change scoping, PRD issue check,
  `-m 'not e2e'`) (#22)
- 2026-10-31 the SIGPIPE class #23 fixed in pre-push removed from the other
  published scripts (#34): `auto-reanchor.sh`, the kit's `install-layer-2.sh`
  and `evaluate.sh`, the Layer 1 `commit-msg`, `check-commit-message.sh` and
  the attribution library now capture output before searching or cutting it.
  `tests/test_guardrails_kit.py` and new cases in `tests/test_hooks.py` drive
  each with output far past a pipe buffer; nine of them failed before the fix.
  The live working-set copies still pipe; the resync is a follow-up in
  llm-coding-workflow
- 2026-10-31 #22 waits on llm-coding-workflow#481, the live pre-push fix, filed
  with the replacement code and still open; read again the same day, the live
  line 102 is still `grep -EnP ... | head -5`. When #481 lands, resync
  `hooks/git/pre-push` from the live copy and move the `hooks/README.md` sync
  date. The other scripts' resync is llm-coding-workflow#482
- 2026-10-31 three over-redactions from the first pass undone (#39): the
  markers had replaced YAML keys and a JavaScript call, not credentials, in
  `calico.yaml` line 400 (`description:`), `dashboard-demo.html` line 152
  (`document.getElementById(`) and `nginx-ingress-config.yaml` line 511
  (`secretName:`). All three files now match the archived Atlanta repo byte
  for byte, and `incident/REDACTIONS.md` counts 27 password, token and secret
  assignments instead of 30
- 2026-10-31 `check-commit-message.sh` resynced to the live heredoc-aware hook
  (#38), not kept frozen with the first-delimiter defect: the helper is
  published as `hooks/claude-code/lib/extract_commit_message.py`, with fixes
  made here first for `-am`, every `-m`, `git -C`, and a heredoc before the
  commit on its line. `hooks/README.md` tells the defect as history and keeps
  the "parsing is guessing" lesson; the 2026-09-10 copy stays at `3c3cb28`.
  The live helper's port is a follow-up in llm-coding-workflow
