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
| `test_delivery_tags.py` | AGENTS.md's delivery-tag table lists Atlanta and Portland, and SREday Austin on `aedb2e2` as approximate (#30); each tag reads `delivered/<event-id>`, each row names a deck file id, says exact or approximate, and names the `peopleforrester/conference-knowledge` issue that reported it (all three on #205, #32), and each commit is in HEAD's history; every table row parses, and the convention still says to report each tag to conference-knowledge |
| `test_repo_paths.py` | No tracked file points a `~/repos` path at a location the 2026-09-20/21 tree restructure retired (`events/`, `certifications/` and the other moved roots); AGENTS.md's framework-evolution section points at `~/repos/portfolio/agentic-covenants` and its GitHub URL, and the file names no other `~/repos` path for it (#37) |
| `test_license.py` | LICENSE file present at repo root |
| `test_redactions.py` | `incident/REDACTIONS.md`'s counts match the `<REDACTED-...>` markers in `incident/session-artifacts/`, and no kubeconfig client key, kubeadm certificate key or basic-auth login is left in the clear (#26) |
| `test_post_event_transcript.py` | Each rescued Portland transcript, the delivery and the run-one and run-two run-throughs, is the original file byte for byte below its marker, names its source and caveat, and is linked from the post-event record |
| `test_deck_order_annotation.py` | The Portland recording review's real-order annotation follows the delivered v7 file's slide order (JUNIOR DEV nineteenth, #45), names each slide as the cue card does with its 15-second window, and copies each heard time from the beat table |
| `test_shell_lint.py` | Every published shell script under `hooks/`, `scripts/` and `guardrails-three-layer/` parses with `bash -n` and is clean at shellcheck error severity (shellcheck must be on `PATH`) |
| `test_workflow_templates.py` | The guardrails kit's workflow templates pin every action by full commit SHA with a version comment, drop checkout credentials, grant only read permissions at workflow level, and pin trivy-action to the 0.35.0 commit GHSA-69fq-xp46-6x23 names safe (#27) |
| `test_hooks.py` | The enforcement hooks return their documented verdicts: sensitive-file and PRD-issue blocks, the ABOUTME warning, the Layer 1 commit-msg, pre-commit and pre-push gates, the tiered `hooks/git` pre-commit and pre-push against stubbed linters and test runners, and `check-talk-video.sh` against a stubbed `yt-dlp`; the PostCompact re-anchor block on a 20,000-file dirty tree, and the commit-message checks on commands and messages longer than a pipe buffer, the attribution library under pipefail (#34) |
| `test_guardrails_kit.py` | The kit's `install-layer-2.sh` applies the ValidatingAdmissionPolicy when a long `kubectl api-resources` listing names it, or when discovery partly fails, and skips it when absent; `evaluate.sh` passes the Falco, ai-workspace and workflow checks and reaches the cluster-admin audit when each listing matches early and runs on long past it. kubectl, gh and pre-commit are stubbed (#34) |
| `test_e2e_declaration.py` | AGENTS.md declares the E2E command exactly once, its suite in `e2e/` sits outside the Test command's `testpaths`, and the `e2e` group pins `yt-dlp` |
| `test_e2e_template.py` | Each `workflows/` template's pytest step, run under GitHub's default `bash -e` against a stubbed `uv`, fails when the suite exits 1, 2, 4 or 5 (no tests collected) and passes on 0; no step carries `\|\|`, `set +e`, `exit 0` or `continue-on-error`, and `e2e.yml`'s pytest command has no fallback (#42) |

## The E2E suite

`e2e/` holds the checks that need live services, run with
`uv run --group e2e pytest -q e2e` (the `E2E command:` in AGENTS.md). They
need the network, the `e2e` group's pinned `yt-dlp`, and `gh` with read access
to the private `peopleforrester/conference-knowledge`, and fail rather than
skip when any is missing.

| File | What's asserted |
|---|---|
| `e2e/test_recordings_live.py` | Every YouTube link in the README's "Given at" table resolves and is titled as this talk; `scripts/check-talk-video.sh`, unstubbed, reads FOUND for the Portland Ignite alone on the live channel |
| `e2e/test_tag_reports_live.py` | Each tag in AGENTS.md's "Tags so far" table is named, with its event id, in the body or a comment of the conference-knowledge issue its "Reported in" cell cites, read live through `gh` (#32) |

## Adding tests

When a new durable-state claim is added (e.g. a new section in
`MEMORY.md` that references the remote, or a new directory promised
in `README.md`), add a test asserting the claim is consistent with
reality. The point of this suite is to prevent the kind of drift
that creeps in when only humans are checking.
