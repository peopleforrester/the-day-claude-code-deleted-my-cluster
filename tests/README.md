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
| `test_state_consistency.py` | PROJECT_STATE.md GitHub owner matches `git remote`; "Next step" names both blocking inputs |
| `test_gitignore_coverage.py` | .gitignore covers deck/talk asset patterns; PDF-export policy is documented in README |
| `test_readme_layout.py` | Every directory listed in README "Repository Layout" exists on disk |
| `test_license.py` | LICENSE file present at repo root |

## Adding tests

When a new durable-state claim is added (e.g. a new section in
`MEMORY.md` that references the remote, or a new directory promised
in `README.md`), add a test asserting the claim is consistent with
reality. The point of this suite is to prevent the kind of drift
that creeps in when only humans are checking.
