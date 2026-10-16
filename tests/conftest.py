# ABOUTME: Shared pytest fixtures for this repo's self-consistency suite.
# ABOUTME: Exposes repo root, file-content readers, the git remote URL and canonical owner/repo.

from __future__ import annotations

import subprocess
from pathlib import Path

import pytest


@pytest.fixture(scope="session")
def repo_root() -> Path:
    """Absolute path to the repository root."""
    return Path(__file__).resolve().parent.parent


@pytest.fixture(scope="session")
def project_state(repo_root: Path) -> str:
    return (repo_root / "PROJECT_STATE.md").read_text(encoding="utf-8")


@pytest.fixture(scope="session")
def readme(repo_root: Path) -> str:
    return (repo_root / "README.md").read_text(encoding="utf-8")


@pytest.fixture(scope="session")
def gitignore(repo_root: Path) -> str:
    return (repo_root / ".gitignore").read_text(encoding="utf-8")


@pytest.fixture(scope="session")
def git_remote_url(repo_root: Path) -> str:
    """The live origin remote URL — the source of truth for the GitHub owner."""
    result = subprocess.run(
        ["git", "-C", str(repo_root), "remote", "get-url", "origin"],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


# The canonical GitHub home of this repo. Pinned rather than read from
# `origin`, because clones made from a local mirror carry no owner in their
# remote URL and the owner check must still run there.
CANONICAL_OWNER_REPO = ("peopleforrester", "the-day-claude-code-deleted-my-cluster")


def parse_github_owner_repo(url: str) -> tuple[str, str] | None:
    """Parse '(owner, repo)' out of a GitHub remote URL, or None if it is not one.

    Supports both SSH (git@github.com:owner/repo.git) and HTTPS
    (https://github.com/owner/repo.git) forms.
    """
    if url.startswith("git@github.com:"):
        path = url.split(":", 1)[1]
    elif "github.com/" in url:
        path = url.split("github.com/", 1)[1]
    else:
        return None
    if path.endswith(".git"):
        path = path[: -len(".git")]
    owner, repo = path.rstrip("/").split("/", 1)
    return owner, repo


@pytest.fixture(scope="session")
def github_owner_repo(git_remote_url: str) -> tuple[str, str]:
    """The canonical '(owner, repo)', cross-checked against a GitHub origin.

    Always returns CANONICAL_OWNER_REPO. When origin is a GitHub URL it must
    name the same owner/repo, and a mismatch fails loudly: either the repo
    moved and the constant needs updating, or this is a clone of the wrong
    repo.
    """
    from_remote = parse_github_owner_repo(git_remote_url)
    if from_remote is not None:
        assert from_remote == CANONICAL_OWNER_REPO, (
            f"origin {git_remote_url!r} names {'/'.join(from_remote)}, but "
            f"tests/conftest.py pins {'/'.join(CANONICAL_OWNER_REPO)}. Update "
            f"CANONICAL_OWNER_REPO if the repo has moved."
        )
    return CANONICAL_OWNER_REPO
