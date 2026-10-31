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

