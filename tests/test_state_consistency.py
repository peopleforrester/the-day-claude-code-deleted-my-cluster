# ABOUTME: Asserts PROJECT_STATE.md reflects actual repository and remote state.
# ABOUTME: Catches the class of state-drift bug the senior review surfaced.

from __future__ import annotations

import pytest

from tests.conftest import CANONICAL_OWNER_REPO, parse_github_owner_repo


@pytest.mark.parametrize(
    "url",
    [
        "git@github.com:peopleforrester/the-day-claude-code-deleted-my-cluster.git",
        "https://github.com/peopleforrester/the-day-claude-code-deleted-my-cluster.git",
        "https://github.com/peopleforrester/the-day-claude-code-deleted-my-cluster",
    ],
)
def test_github_remote_urls_parse_to_canonical(url: str) -> None:
    """Every GitHub URL form the fixture cross-checks yields the pinned owner/repo."""
    assert parse_github_owner_repo(url) == CANONICAL_OWNER_REPO


def test_non_github_remote_is_not_parsed() -> None:
    """A local mirror path names no owner, so the fixture relies on the pinned value."""
    assert parse_github_owner_repo("/var/lib/mirrors/1351782208.git") is None


def test_project_state_owner_matches_remote(
    project_state: str, github_owner_repo: tuple[str, str]
) -> None:
    """PROJECT_STATE.md must name the canonical owner/repo.

    The fixture pins it and cross-checks it against `origin` whenever
    origin is a GitHub URL.

    The senior review caught the owner drifted from `michaelrishiforrester`
    (a stale guess) to the real `peopleforrester`. This test prevents the
    same class of bug from recurring on any future state file edit.
    """
    owner, repo = github_owner_repo
    canonical = f"{owner}/{repo}"
    assert canonical in project_state, (
        f"PROJECT_STATE.md does not mention the canonical "
        f"owner/repo '{canonical}' pinned in tests/conftest.py."
    )

    # No incorrect owner should remain anywhere in the file.
    wrong_owner = "michaelrishiforrester"
    assert wrong_owner not in project_state, (
        f"PROJECT_STATE.md still references the wrong owner "
        f"'{wrong_owner}'. The real owner is '{owner}'."
    )


def test_next_step_section_has_content(project_state: str) -> None:
    """The 'Next step' section must exist and carry non-trivial content.

    Originally this test asserted that 'Next step' named both blocking
    inputs (abstract/bio and event date/timebox). Both inputs landed
    before the talk, so the specific-keyword assertion no longer
    applies. The general consistency guarantee remains: PROJECT_STATE.md
    must always answer 'what's next?' for a future /continue session,
    so the section must be present and substantive.
    """
    lower = project_state.lower()
    marker = "## next step"
    start = lower.find(marker)
    assert start != -1, "PROJECT_STATE.md is missing a '## Next step' section."

    # Section runs to the next H2 (or EOF).
    rest = project_state[start + len(marker) :]
    next_h2 = rest.find("\n## ")
    section = rest[:next_h2] if next_h2 != -1 else rest
    assert len(section.strip()) >= 40, (
        "Next step section is empty or near-empty. /continue cannot "
        "resume from a placeholder."
    )
