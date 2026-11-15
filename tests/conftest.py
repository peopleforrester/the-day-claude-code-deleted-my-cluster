# ABOUTME: Shared pytest fixtures for this repo's self-consistency suite: repo root, file readers, the remote.
# ABOUTME: Also roots every tmp_path in the checkout's git-ignored tmp/, removed when the run ends (#48).

from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parent.parent
TMP = ROOT / "tmp"
CEILING = "GIT_CEILING_DIRECTORIES"


@pytest.hookimpl(tryfirst=True)
def pytest_configure(config: pytest.Config) -> None:
    """Give the run its own basetemp under tmp/ unless --basetemp names one.

    Left alone, pytest roots tmp_path at /tmp/pytest-of-<user>. Pass --basetemp
    to keep a failing test's files.

    tmp/ sits inside this checkout, so git started in a tmp_path that is not
    itself a repository would walk up and find this one. Naming tmp/ in
    GIT_CEILING_DIRECTORIES stops that walk, for the tests and the hooks they run.
    """
    if config.option.basetemp is not None:
        return
    TMP.mkdir(exist_ok=True)
    run = tempfile.mkdtemp(prefix="pytest-", dir=TMP)
    config.option.basetemp = str(Path(run) / "basetemp")
    config.add_cleanup(lambda: shutil.rmtree(run, ignore_errors=True))

    before = os.environ.get(CEILING)
    os.environ[CEILING] = os.pathsep.join(filter(None, [before, str(TMP)]))

    def restore() -> None:
        if before is None:
            os.environ.pop(CEILING, None)
        else:
            os.environ[CEILING] = before

    config.add_cleanup(restore)


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
