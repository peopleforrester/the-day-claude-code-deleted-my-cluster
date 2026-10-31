<!-- ABOUTME: Append-only decision log for this talk and its repo. -->
<!-- ABOUTME: Never edit a prior entry; correct one with a new entry that names it. -->

# Decisions

The entries dated before 2026-10-31 were recorded at the time in
`PROJECT_STATE.md` and the issues named, and are carried here when this log
was started (#16). Their wording follows those records.

## 2026-08-30 · One repo for the talk, named for the talk

The material is consolidated into this repo, named for the talk rather than
any conference, because the talk has been given more than once and will be
again. It is seeded from the `peopleforrester/SREday-Texas-2026` history, with
the incident forensics and the three-layer install brought over from
`peopleforrester/DevOpsDaysAtlanta_2026_Cluster_Destruction_Ignite`. Both event
repos stay as records of their own deliveries and point here. Carried out under
an explicit instruction rather than a written plan.

## 2026-09-01 · The repo is public

The repo is made public and both event repos point here (#2, #4). Nothing that
is not safe to publish lands here; session transcripts with credentials,
attendee emails, AWS account identifiers and unredacted customer data are cited
by path instead.

## 2026-09-05 · Portland runs with the submitted abstract

The abstract correction is dropped for DevOpsDays Portland 2026. The corrected
text is kept in `abstract/portland-2026-revision.md` for the next submission.

## 2026-10-31 · A delivery is a `delivered/<event-id>` tag

Each delivery is recorded as an annotated tag named for the event's id in the
conference-knowledge registry, not as a fork or an event repo (#9). The
convention and the tags so far are in `AGENTS.md`.

## 2026-10-31 · conference-knowledge owns the delivery record

Event information (dates, slots, rooms, recordings) is kept in
conference-knowledge `events/registry.yaml`, not here (#13). The README's
"Given at" table is its public rendering; where the two disagree, the registry
wins.

## 2026-10-31 · `AGENTS.md` is the one rules file; talks-knowledge is named

`CLAUDE.md` held the repo rules and `AGENTS.md` held the test command, the
delivery tags and a "Where things live" section. To meet the talk-repo fleet
standard that talks-knowledge set on 2026-10-14 (#16), the rules are merged
into `AGENTS.md` and `CLAUDE.md` becomes a symlink to it, so there is one copy
for every agent. "Where things live" names talks-knowledge for the register,
the research index and the abstract library, and conference-knowledge for event
state. The README gains an "About this talk" table naming the speaker, the
argument, the status and the repos the talk is built from.
`tests/test_identity.py` pins the symlink, this log and both pointers.

## 2026-10-31 · The attribution library is published beside the hook

`hooks/claude-code/check-commit-message.sh` sourced its pattern check from
`../../scripts/git-hooks/lib/check-ai-attribution.sh`, a path that exists only
in the working set it was synced from (#18). Of the three options in the issue,
the library is published as `hooks/claude-code/lib/check-ai-attribution.sh`,
synced from that working set on 2026-10-31, and the hook reads it from `lib/`
beside itself. Inlining it would break the one-pattern-list design the hook
documents, and documenting the dependency alone would leave the published hook
unusable as published. The rest of the hook is left as synced on 2026-09-10:
the live copy has since replaced its heredoc parsing, and the heredoc defect is
published on purpose as a teaching artifact (`hooks/README.md`).

## 2026-10-31 · Every certificate key is redacted; public material stays

Issue #26 named the first file for each credential the first redaction pass
missed. The tree held more: kubeadm certificate keys sat in seven lines beyond
the five it listed, one of them a fifth distinct key in
`k8s-cluster-build_vAug24th/steps/07-join-masters/join-control-plane.sh`, and the
HAProxy stats password also appeared in `stats auth` and an `echo` in
`install-ha-infrastructure.sh`. Every occurrence is redacted, since the point is
that the tree matches what `incident/REDACTIONS.md` says. Each credential type
gets its own marker and its own row in that file's table. Left in place, as
public material: the `--discovery-token-ca-cert-hash` values, the
`certificate-authority-data` and `client-certificate-data` certificates, and
image digests. `tests/test_redactions.py` holds the table to the marker counts
and fails on the three missed shapes, so the next miss is caught by a check
rather than by care. History is not rewritten: the values remain in `e8d5a60`
and in the archived Atlanta repo, which `REDACTIONS.md` already points to.

## 2026-10-31 · The kit's workflow templates are pinned by SHA, trivy-action moves to 0.35.0

The monthly security scan (infrastructure-security-scanning#129) found 31
zizmor findings in `guardrails-three-layer/layer-1-git-ci/.github/workflows/`
(#27). Every action is now pinned by the full commit SHA its tag pointed at on
2026-10-31, read with `git ls-remote`, with the release in a comment. A major
tag is pinned to the release it pointed at (`actions/checkout@v4` is v4.4.0),
except `amannn/action-semantic-pull-request@v5`, which pointed at an untagged
commit three behind v5.5.3, so v5.5.3 is pinned. The major lines are kept,
including `github/codeql-action` v3; upgrades are not part of this fix.

trivy-action is the exception. Its `0.28.0` tag no longer exists, so the
template no longer resolved at all, and GHSA-69fq-xp46-6x23 names 0.35.0 the
only tag the March 2026 compromise did not rewrite and a SHA pin before
2025-04-09 still unsafe, since it pulls `setup-trivy` by tag. It moves to
0.35.0 (`57a97c7`), which pins `setup-trivy` by SHA and defaults to Trivy
v0.69.3; the template's inputs are unchanged in that release.

Workflow-level permissions are `contents: read` in all four files. Write is
granted per job: `security-events: write` on the three jobs that upload SARIF,
`pull-requests: write` on the gitleaks job, which comments on the PR, and on
`ai-content-detection`, which labels it; the title check gets
`pull-requests: read`. `policy-check.yml` needs no write at all. Beyond the 31,
`merge-queue.yml` drops a `security-events: write` its one echo step never
used, and the PR SHAs reach the shell through `env` rather than template
expansion. zizmor 1.30.1 offline now reports no findings at its default
persona; at `auditor` only two low `concurrency-limits` remain, left alone
because adding concurrency groups changes how the PR checks cancel.
`tests/test_workflow_templates.py` holds the templates to this.

## 2026-10-31 · The E2E command checks the recordings against live YouTube (#24)

AGENTS.md declared only the light `Test command:`, so `main` was gated on
offline checks alone. The claims here that only a live service can confirm are
the recording links in the README's "Given at" table, the public rendering of
the delivery record, and the video check's verdict, so the E2E suite in `e2e/`
checks those: each linked recording resolves through YouTube's oEmbed endpoint
and is titled as this talk, and `scripts/check-talk-video.sh`, unstubbed, reads
FOUND for the Portland Ignite alone. AGENTS.md declares `E2E command: uv run
--group e2e pytest -q e2e`.

`yt-dlp` is added as the only member of a new `e2e` dependency group, pinned to
`2026.10.26`, the current PyPI release (uploaded 2026-10-26), so the heavy gate
does not depend on a system install. It is not in `dev`, so the Test command
does not install it.

The `delivered/*` tags of #9 are not checked against GitHub: on 2026-10-31 they
exist only in a run's clone and are not on the remote, so a check would fail
the gate on a push no run can make. It is a follow-up once #9's tags are
pushed.

## 2026-10-31 · The Portland recording's description is not corrected

The DevOpsDays Portland recording (`rUJ07SnFsXA`) carries the abstract as
submitted, "when it deleted 250 clusters" and "it was 250, gone" (#28). No
request goes to the organizers. This decision applies the 2026-09-05 entry
above to the recording: that decision dropped the correction, and
`abstract/portland-2026-revision.md` records it with "Do not re-raise it for
Portland". The recording is the Portland delivery's own artifact, so that
instruction covers it. Asking him again would re-raise what he closed.

Three things support leaving it. The submitted text is the contract, and this
repo annotates errors rather than rewriting them. The spoken close at 5:02
cannot be edited, so a corrected description would still leave the recording
saying it. And the correction already has a public home of its own: the
newsletter issue `enforced-by-infrastructure-3-the-abstract-said-250` in
`mrf-engagement-orchestrator`'s `content_calendar.yaml`, set for 2026-11-10,
is about this exact text, and the post-talk article (#5, #36) links the video
without quoting its description.

The text is the same on the pretalx program page,
<https://talks.devopsdays.org/devopsdays-portland-2026/talk/97ACTV/>, read from
the schedule export on 2026-10-31. Should Michael ever reopen this, the text to
send is the two fields in `abstract/portland-2026-revision.md`, whole, for both
the YouTube description and that page. It goes to `portland-or@devopsdays.org`
or Shobhna Shastri directly, not `talks@devopsdays.org`. Her reply of
2026-09-10 says she does not know where that address goes.

## 2026-10-31 · SREday Austin is tagged on `aedb2e2`, approximate (#30)

`delivered/sreday-austin-2026` goes on `aedb2e2`, the last commit before the
17:30 UTC slot, as the 2026-10-31 tag convention above says: tag what `main`
held when the talk started. It is marked approximate, not exact, because the
deck copy in that commit is not what was on screen. The recording shows slide
16 with "(ALONE)", which only the next commit, `9c7291e`, has; that commit is
the Drive file's last save, three minutes after the slot ended.

Tagging `9c7291e` instead was considered and rejected. It would hold the deck
as shown, but it postdates the talk and may carry edits made after it, and the
convention is what conference-management's `check_registry.py` and the next
organizer rely on. The AGENTS.md row sends a reader to `9c7291e` for the deck.

## 2026-10-31 · Each delivery tag records the issue that reported it (#32)

#9 asked for its tags to be reported back so `conference-management` can record
them against each event. The report is an issue on
`peopleforrester/conference-knowledge`, which owns `events/registry.yaml`, and
until now nothing in this repo named it, so no test could tell a reported tag
from an unreported one. AGENTS.md's "Tags so far" table gains a "Reported in"
column holding that issue, and the steps after tagging say to fill it in.
Atlanta and Portland are in conference-knowledge#205's body and SREday Austin in
a comment on it, so all three rows cite #205.

The offline suite checks that every row cites a conference-knowledge issue and
that every row parses, so a row added without the column fails instead of
dropping out of the table's tests. Whether the cited issue really names the tag
can only be read live, so the E2E suite reads it through `gh issue view`, and
that suite now also needs `gh` with read access to the private
conference-knowledge repo. The check asks for the tag and its event id in the
issue's body or a comment, not for `delivered_tag` in the registry: recording it
there is conference-knowledge's step, and it waits on the tags reaching GitHub.

## 2026-10-31 · Published scripts search captured output, never a pipe into an early reader (#34)

#23 found the pre-push secret scan passing files because grep, piped into
`head -5` under pipefail, died of SIGPIPE when head exited. The same shape sat
in five more published scripts: `auto-reanchor.sh` (`git status | head -10`,
which aborted the hook), the kit's `install-layer-2.sh` and `evaluate.sh`
(`kubectl ... | grep -q`, which read a present API or component as missing),
the Layer 1 `commit-msg` and the shared attribution library
(`echo "$msg" | grep -q`, which read an attribution above a long body as
absent), and `check-commit-message.sh` (`grep -o | head -1`, harmless there
only because that hook sets no pipefail).

The rule for every published script is now the one a20a8fd and #23 used:
capture the command's output with `out=$(cmd || true)`, then search it with
`grep -q ... <<< "$out"` or cut it from the captured text (`head <<< "$out"`,
`${out%%$'\n'*}`). A here-string has no writer for the reader to kill. Readers
that consume all their input (`wc`, `tail`, `tr`, `sed` without `q`) are left
piped, and so are the one-line producers piped into `grep -q` in the
`pre-commit` and `pre-push` hooks (`file`, and `echo` of a ref name): their
single short write lands before grep can match, so there is nothing for
SIGPIPE to interrupt. Each fixed script has a behavioural test whose output
runs far past a pipe buffer after the first match.

The heredoc defect `hooks/README.md` keeps on purpose in
`check-commit-message.sh`, taking the first delimiter in the command, is
unchanged: the capture keeps the first match just as `head -1` did.

## 2026-10-31 · `check-commit-message.sh` is resynced to the live heredoc-aware hook (#38)

This corrects two entries above: "The attribution library is published beside
the hook", which left the hook's heredoc parsing as synced on 2026-09-10, and
the last paragraph of "Published scripts search captured output", which kept
the first-delimiter defect unchanged. Of the two options in #38, the published
copy is resynced to the live one, and `hooks/README.md` now tells the defect as
history and the fix as the lesson. It is not kept frozen.

Four things decide it. `hooks/README.md` publishes these scripts for readers to
install, and a hook kept with a known fail-open bypass is one they would
install. This repo already fixes published defects ahead of the live set rather
than keep them (#23, #34). The old copy is not lost: it is in history at
`3c3cb28`, the commit the `delivered/devopsdays-portland-2026` tag marks.
Nothing in the deck, the outlines or the abstract cites the defect; only
`hooks/README.md` and the bypass column of `docs/the-framework.md` did, and
both are rewritten. The lesson those two drew, that a control parsing a command
string is guessing, holds for the fix as well, so the section keeps it.

Like the attribution library, the helper is published beside the hook, as
`hooks/claude-code/lib/extract_commit_message.py`, and the hook reads it from
`lib/`. The resync turned up more parsing bypasses, and they are fixed here
first, as #23 and #34 were: the live helper read `-m` from the start of the
commit's line, a regression the old copy did not have; it read only the first
`-m`; it did not read `-am`, `-m"..."`, `--message "..."` or a bare value; it
did not see `git -C <path> commit` as a commit; and it took a heredoc opened
before the commit on the same line as the message. A heredoc after the commit
on its line is scanned too, which reads too much rather than too little. The
issue-link check keeps this repo's here-strings from #34. Porting these fixes to
the live helper is a follow-up in llm-coding-workflow.

The sample in the old `hooks/README.md` section was wrong as well: with both
heredocs delimited by `EOF`, the old hook read both bodies and caught the
message. The bypass needs the commit's heredoc under a different delimiter, so
the sample and its test now use `MSG`.
## 2026-10-31 · The run-two transcript is collected from the full copy (#35)

`My recording 212.mp3`, a run-through on the day of the Portland Ignite,
was routed by the transcription pipeline to four repos, each getting only the
sections it matched, and a fifth holds a copy of one. None is known to be
committed. `Unleash_an_Agent_Watch_It_Burn`, public, has the whole run and no
trace of it on any branch or in any history on GitHub; `conference-management`
and the archived KubeCon BurritoBot repo ignore `transcripts/`; the archived
`walkthrough-agenticburn` (first section only) and the private Neo4j edition
(a byte copy of the Watch It Burn file) cannot have their history read from
here. The header lists all five. So it is collected as `post-event/portland-2026-run-two-transcript.md`, the
way #25 collected the delivery: header above a marker, original below, size
and sha256 pinned by the suite.

The copy collected is the `Unleash_an_Agent_Watch_It_Burn` one, because it is
the whole run, in a public repo, and every other copy's body is it or a part
of it. Their sizes and hashes are recorded in the header, not their text,
since they add nothing.

The header does not claim this is the run-through issue #8 cited as 20 of 20
beats at about 5:48. Its restart is about 940 words, about 6:17 at that rate,
and a second run-through the same day, `My recording 211.mp3`, about 900 words
and also uncommitted, is the closer match. That one is left for its own issue
rather than collected here, since #35 asked about 212 only.

## 2026-10-31 · The kit's clone instructions point at this repo, and Layer 3's template is restored (#40)

`guardrails-three-layer/START_HERE.md` and the kit's `README.md` told readers
to clone the archived Atlanta Ignite repo, which still holds the workflow
templates with mutable tags and broad permissions that #27 fixed here only.
Both now clone this repo into `/tmp/three-layers`, and every path under it
goes through `guardrails-three-layer/`. The README's own start block now runs
`evaluate.sh` from the reader's repo, as START_HERE does, since the script
scores the git repo of the current directory. Its old form, `cd` into the clone
and run `./bin/evaluate.sh`, scored the kit. Its tree is now rooted at the kit
directory, with `three-layers.md` beside the README, where it is, and not under
`docs/`. The Atlanta repo is left as it is; nothing here needs it unarchived.

Pointing readers here exposed a gap from the consolidation: the root
`.gitignore` ignores every `.claude/` directory, so
`layer-3-claude-hooks/.claude/` (`settings.json` and eight hooks) never came
across from the Atlanta repo. START_HERE's Layer 3 step and
`bin/install-layer-3.sh` both copy from it. It is restored from the Atlanta
checkout, byte-identical to the copy on that repo's GitHub `main`, and the
`.gitignore` has a negation for that one directory. The template's
`settings.json` runs a `prompt-secret-scan.sh` that the Atlanta copy never had
either. That is carried over unchanged and left for its own issue.

`tests/test_kit_clone_paths.py` pins both docs to this repo's URL. It also
holds every `/tmp/three-layers/...` path they name to a path `git ls-files`
lists, so an ignored directory that exists only on disk fails.

## 2026-10-31 · The root workflows/ get the kit templates' pins, and pins are checked live (#41)

`workflows/ci.yml` and `workflows/e2e.yml` sit outside `.github/`, so they do
not run here and the #27 scan never saw them, but `workflows/README.md` tells
readers to copy them into their own `.github/workflows/`. They referenced
`actions/checkout@v7` and `astral-sh/setup-uv@v10` by mutable tag. setup-uv
publishes no major tags past `v7`; `git ls-remote` on 2026-10-31 lists full
tags up to `v10.3.3` and no `v10`, so either workflow failed to start as
written.

#27's rule is kept: a major line stays, pinned to the release it points at.
`actions/checkout@v7` is v7.0.1 (`3d3c42e`). setup-uv has no `v10` to read, so
the newest v10 release, v10.3.3 (`68559e9`, 2026-10-28), is pinned. Both SHAs
were fetched and are commits. Both files gain workflow-level `permissions:
contents: read` and `persist-credentials: false` on checkout; neither job
pushes or needs the token after checkout. zizmor 1.30.1 offline, run on a copy
placed under `.github/workflows/`, reports no findings at its default persona.

`tests/test_workflow_templates.py` runs its pin, credential and permission
cases over both sets. A version comment offline only shows a tag was named, not
that it exists, which is how `v10` got through, so
`e2e/test_action_pins_live.py` reads each pin's tag with `git ls-remote`,
peels annotated tags, and fails when the tag is missing or names another
commit. It is in the E2E command because it needs the network.

`e2e.yml`'s placeholder step, which runs `pytest -m e2e` over `tests/` and
echoes on failure, is unchanged; it is a template's stand-in, outside this fix.
## 2026-10-31 · The e2e.yml template has no fallback, so an empty suite fails too (#42)

`workflows/e2e.yml` ran `uv run pytest tests/ -m "e2e" -q --no-header || echo
...`, so a reader who copied it got a gate that could never go red. #42 offered
two fixes: let pytest's exit 5 ("no tests collected") be the only pass, or drop
the fallback and have readers put their own suite in its place. This takes the
second. A gate that passes with nothing behind it is the failure the talk is
about, a status report with nothing behind it, and exit 5 as a pass keeps that
for any reader whose suite moves or whose marker stops matching. So the step
runs `uv run pytest tests/e2e/ -q` as a stand-in and goes red on any non-zero
exit, an empty or missing suite included, until it is replaced. The template's
header and `workflows/README.md` say so.

`tests/test_e2e_template.py` holds it there by behaviour, not only by text: it
runs each `workflows/` template's pytest step under GitHub's default `bash -e`
with `uv` stubbed to exit 1, 2, 4 and 5, and requires the step to fail each
time and pass on 0. `ci.yml` is held to the same tests, since a reader copies
both. Six of its cases fail against the old template.
