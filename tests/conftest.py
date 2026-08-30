# ABOUTME: Shared pytest fixtures for this repo's self-consistency suite.
# ABOUTME: Exposes repo root, file-content readers, and the live git remote URL.

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


@pytest.fixture(scope="session")
def github_owner_repo(git_remote_url: str) -> tuple[str, str]:
    """Parse '(owner, repo)' out of the origin URL.

    Supports both SSH (git@github.com:owner/repo.git) and HTTPS
    (https://github.com/owner/repo.git) forms.
    """
    url = git_remote_url
    if url.startswith("git@"):
        path = url.split(":", 1)[1]
    else:
        path = url.split("github.com/", 1)[1]
    if path.endswith(".git"):
        path = path[: -len(".git")]
    owner, repo = path.split("/", 1)
    return owner, repo
