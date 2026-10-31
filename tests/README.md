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
| `test_license.py` | LICENSE file present at repo root |
| `test_post_event_transcript.py` | The rescued Portland transcript is the original file byte for byte below its marker, names its source and caveat, and is linked from the post-event record |
| `test_shell_lint.py` | Every published shell script under `hooks/`, `scripts/` and `guardrails-three-layer/` parses with `bash -n` and is clean at shellcheck error severity (shellcheck must be on `PATH`) |
| `test_hooks.py` | The enforcement hooks return their documented verdicts: sensitive-file and PRD-issue blocks, the ABOUTME warning, the Layer 1 commit-msg, pre-commit and pre-push gates, the tiered `hooks/git` pre-commit and pre-push against stubbed linters and test runners, and `check-talk-video.sh` against a stubbed `yt-dlp` |

## Adding tests

When a new durable-state claim is added (e.g. a new section in
`MEMORY.md` that references the remote, or a new directory promised
in `README.md`), add a test asserting the claim is consistent with
reality. The point of this suite is to prevent the kind of drift
that creeps in when only humans are checking.
