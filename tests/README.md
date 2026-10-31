# Tests: Consistency Suite

This is a documentation-only repo, so the test suite has a single
purpose: assert that the durable state files (`PROJECT_STATE.md`,
`MEMORY.md`, `README.md`, `.gitignore`) match the actual state of
the repository and its remote.

## Why

The senior review caught a real bug: `PROJECT_STATE.md` claimed the
GitHub owner was `michaelrishiforrester` while `git remote get-url
origin` reported `peopleforrester`. State-drift in durable docs is
the exact failure mode this suite exists to catch.

## Run

```
uv sync
uv run pytest
```

Or, if pytest is on `PATH`:

```
pytest
```

## What's tested

| File | What's asserted |
|---|---|
| `test_state_consistency.py` | PROJECT_STATE.md names the canonical owner/repo, which a GitHub `origin` must also match; "Next step" names both blocking inputs |
| `test_gitignore_coverage.py` | .gitignore covers deck/talk asset patterns; PDF-export policy is documented in README |
| `test_readme_layout.py` | Every directory listed in README "Repository Layout" exists on disk |
| `test_delivery_tags.py` | AGENTS.md's delivery-tag table lists Atlanta and Portland, each tag reads `delivered/<event-id>`, each row names a deck file id and says exact or approximate, and each commit is in HEAD's history |
| `test_repo_paths.py` | No tracked file points a `~/repos` path at a location the 2026-09-20/21 tree restructure retired (`events/`, `certifications/` and the other moved roots) |
| `test_license.py` | LICENSE file present at repo root |
| `test_redactions.py` | `incident/REDACTIONS.md`'s counts match the `<REDACTED-...>` markers in `incident/session-artifacts/`, and no kubeconfig client key, kubeadm certificate key or basic-auth login is left in the clear (#26) |
| `test_post_event_transcript.py` | The rescued Portland transcript is the original file byte for byte below its marker, names its source and caveat, and is linked from the post-event record |
| `test_shell_lint.py` | Every published shell script under `hooks/`, `scripts/` and `guardrails-three-layer/` parses with `bash -n` and is clean at shellcheck error severity (shellcheck must be on `PATH`) |
| `test_workflow_templates.py` | The guardrails kit's workflow templates pin every action by full commit SHA with a version comment, drop checkout credentials, grant only read permissions at workflow level, and pin trivy-action to the 0.35.0 commit GHSA-69fq-xp46-6x23 names safe (#27) |
| `test_hooks.py` | The enforcement hooks return their documented verdicts: sensitive-file and PRD-issue blocks, the ABOUTME warning, the Layer 1 commit-msg, pre-commit and pre-push gates, the tiered `hooks/git` pre-commit and pre-push against stubbed linters and test runners, and `check-talk-video.sh` against a stubbed `yt-dlp` |
| `test_e2e_declaration.py` | AGENTS.md declares the E2E command exactly once, its suite in `e2e/` sits outside the Test command's `testpaths`, and the `e2e` group pins `yt-dlp` |

## The E2E suite

`e2e/` holds the checks that need live services, run with
`uv run --group e2e pytest -q e2e` (the `E2E command:` in AGENTS.md). They
need the network and the `e2e` group's pinned `yt-dlp`, and fail rather than
skip when either is missing.

| File | What's asserted |
|---|---|
| `e2e/test_recordings_live.py` | Every YouTube link in the README's "Given at" table resolves and is titled as this talk; `scripts/check-talk-video.sh`, unstubbed, reads FOUND for the Portland Ignite alone on the live channel |

## Adding tests

When a new durable-state claim is added (e.g. a new section in
`MEMORY.md` that references the remote, or a new directory promised
in `README.md`), add a test asserting the claim is consistent with
reality. The point of this suite is to prevent the kind of drift
that creeps in when only humans are checking.
