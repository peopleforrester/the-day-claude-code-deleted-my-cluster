# Workflows: GitHub Actions backstop

Two workflows mirroring slide 11 of the deck, defense-in-depth for
anyone who pushes without the local `pre-commit` / `pre-push` hooks
from `../hooks/git/` installed.

| Workflow | Trigger | Purpose | Bypass |
|---|---|---|---|
| `ci.yml` | push to staging/main, PR to either | Run the unit suite on every push and pull request | Admin merge override; UI-skipped checks |
| `e2e.yml` | PR to main only | Gate end-to-end tests before they reach main | Same as `ci.yml`; also flaky tests passing on retry |

`ci.yml` right now runs the consistency suite for this talk repo
(uv + pytest). The deck slide describes a fuller form ("ruff/mypy/u")
for production repos: when you adapt this to your own project, add
those steps before the test run.

`e2e.yml` is a structural placeholder: it has the right shape and
trigger (PR to main, separate gate) but the talk repo has no
e2e-marked tests yet, so the run exits cleanly noting the gate is
present-but-empty. In your repo, replace the test command with your
real e2e suite.

### Install

```bash
mkdir -p /path/to/your-repo/.github/workflows
cp workflows/ci.yml workflows/e2e.yml /path/to/your-repo/.github/workflows/
```

Commit and push. `ci.yml` fires on the next push or PR; `e2e.yml`
fires the next time someone opens a PR to `main`.

### What this does not cover

These workflows are **client-side-equivalent** checks moved to the
remote. They do not replace branch protection, CODEOWNERS, admission
policies, or any other server-side enforcement on the target.
See [`../docs/the-framework.md`](../docs/the-framework.md) section 2
("Server side, Git, CI, systemd") for what a complete remote-side
posture looks like.
