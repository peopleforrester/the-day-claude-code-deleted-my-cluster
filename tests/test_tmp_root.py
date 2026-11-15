# ABOUTME: Holds tests/conftest.py to rooting tmp_path under this checkout's git-ignored tmp/ (#48):
# ABOUTME: a child pytest run lands there, is fenced from this checkout's git, and leaves nothing behind.

from __future__ import annotations

import os
import re
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
PROBE = f"{Path(__file__).relative_to(REPO_ROOT)}::test_probe_prints_where_its_tmp_path_is"
TMP_PATH = "probe tmp_path: "
GIT_FOUND = "probe git toplevel: "


def test_probe_prints_where_its_tmp_path_is(tmp_path: Path) -> None:
    """Run again by the tests below in a child pytest, which reads these two lines."""
    found = subprocess.run(
        ["git", "-C", str(tmp_path), "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
    )
    print(f"{TMP_PATH}{tmp_path}")
    print(f"{GIT_FOUND}{found.stdout.strip() or 'none'}")
    assert tmp_path.is_dir()


def _child_run(*options: str) -> tuple[Path, str]:
    """Run the probe alone in a fresh pytest; return its tmp_path and what git found there.

    The child gets no PYTEST_ADDOPTS and no GIT_CEILING_DIRECTORIES, so the
    basetemp and the fence it reports are the ones tests/conftest.py set.
    """
    env = {
        k: v
        for k, v in os.environ.items()
        if k not in ("PYTEST_ADDOPTS", "GIT_CEILING_DIRECTORIES")
    }
    result = subprocess.run(
        [sys.executable, "-m", "pytest", "-q", "-s", "-p", "no:cacheprovider", *options, PROBE],
        cwd=REPO_ROOT,
        env=env,
        capture_output=True,
        text=True,
        timeout=120,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    where = re.search(rf"^{TMP_PATH}(.+)$", result.stdout, re.MULTILINE)
    git = re.search(rf"^{GIT_FOUND}(.+)$", result.stdout, re.MULTILINE)
    assert where and git, result.stdout
    return Path(where.group(1)), git.group(1)


def test_tmp_path_sits_under_the_checkouts_tmp_and_is_removed() -> None:
    where, git_found = _child_run()
    under = where.relative_to(REPO_ROOT / "tmp")  # raises when tmp_path is anywhere else
    assert re.fullmatch(r"pytest-\w+", under.parts[0]), where
    assert under.parts[1] == "basetemp", where
    assert git_found == "none", f"git started in tmp_path found the checkout at {git_found}"
    assert not (REPO_ROOT / "tmp" / under.parts[0]).exists(), "the run left its directory behind"


def test_a_given_basetemp_is_left_alone(tmp_path: Path) -> None:
    given = tmp_path / "given"
    where, _ = _child_run(f"--basetemp={given}")
    assert where.is_relative_to(given), where
    assert where.is_dir(), "a run given --basetemp keeps its files"


def test_the_checkout_ignores_its_tmp() -> None:
    """`.gitignore` itself covers tmp/, not only a clone's own .git/info/exclude."""
    for sample in ("tmp/claude-tests.log", "tmp/pytest-abc123/basetemp/test_x0/file"):
        result = subprocess.run(
            ["git", "-C", str(REPO_ROOT), "check-ignore", "--no-index", "-v", sample],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, f".gitignore does not cover {sample}"
        source = result.stdout.split(":", 1)[0]
        assert source == ".gitignore", f"{sample} is ignored by {source}, not by .gitignore"
