# ABOUTME: Runs the live sk-tmp-check from scripts-knowledge over this repo and fails on any system tempdir path finding.
# ABOUTME: Needs gh with read access to the private scripts-knowledge repo; fails, never skips, without it (#57).

from __future__ import annotations

import os
import shutil
import subprocess
import sys
import tempfile
from collections.abc import Iterator
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent
CHECK_REPO = "peopleforrester/scripts-knowledge"
CHECK_REF = "main"
# sk-tmp-check runs tmp_writes.py beside it, which imports shell_text.py beside it.
CHECK_FILES = ("sk-tmp-check", "tmp_writes.py", "shell_text.py")
# The start of tmp_writes.py's LITERAL message: a line naming a path under
# /tmp, /var/tmp or /dev/shm that carries no tmp-ok waiver.
PATH_FINDING = "a system tempdir path"


def fetch(name: str) -> str:
    """One file from scripts-knowledge's bin/, read raw through gh."""
    assert shutil.which("gh"), f"gh is not on PATH; this suite reads {CHECK_REPO} through it."
    result = subprocess.run(
        [
            "gh",
            "api",
            "-H",
            "Accept: application/vnd.github.raw",
            f"repos/{CHECK_REPO}/contents/bin/{name}?ref={CHECK_REF}",
        ],
        capture_output=True,
        text=True,
        timeout=60,
    )
    assert result.returncode == 0 and result.stdout, (
        f"gh could not read bin/{name} at {CHECK_REF} in {CHECK_REPO}: "
        f"{result.stderr.strip() or result.stdout.strip()}. "
        f"This suite needs the network and gh signed in with read access to {CHECK_REPO}, which is private."
    )
    return result.stdout


@pytest.fixture(scope="module")
def check_bin() -> Iterator[Path]:
    """The live checker in a fresh directory under this checkout's git-ignored tmp/, removed afterwards."""
    (REPO_ROOT / "tmp").mkdir(exist_ok=True)
    where = Path(tempfile.mkdtemp(prefix="sk-tmp-check-", dir=REPO_ROOT / "tmp"))
    try:
        for name in CHECK_FILES:
            (where / name).write_text(fetch(name), encoding="utf-8")
        yield where
    finally:
        shutil.rmtree(where)


def run(check_bin: Path, *args: str, cwd: Path) -> subprocess.CompletedProcess[str]:
    # Outside GitHub Actions the findings print as plain path:line: message lines.
    env = {k: v for k, v in os.environ.items() if k != "GITHUB_ACTIONS"}
    return subprocess.run(
        [sys.executable, "-I", *args],
        cwd=cwd,
        env=env,
        capture_output=True,
        text=True,
        timeout=300,
    )


def test_the_live_checker_still_words_a_path_finding_this_way(check_bin: Path) -> None:
    """Guard against a pass that only means the wording moved: a /tmp path must print the phrase."""
    probe = check_bin / "probe" / "probe.sh"
    probe.parent.mkdir()
    probe.write_text("#!/usr/bin/env bash\ntouch /tmp/probe\n", encoding="utf-8")
    result = run(check_bin, str(check_bin / "tmp_writes.py"), str(probe), cwd=probe.parent)
    assert result.returncode == 1, result.stdout + result.stderr
    assert PATH_FINDING in result.stdout, (
        f"tmp_writes.py no longer prints {PATH_FINDING!r} for a /tmp path; "
        f"update PATH_FINDING to its current message. It printed: {result.stdout!r}"
    )


def test_sk_tmp_check_at_the_repo_root_prints_no_system_tempdir_path(check_bin: Path) -> None:
    """Every tracked .sh, .bash and .py file, as the live check reads it (#48)."""
    result = run(check_bin, str(check_bin / "sk-tmp-check"), cwd=REPO_ROOT)
    # 0 is clean and 1 is a finding of any kind; 2 means the check itself did not run.
    assert result.returncode in (0, 1), f"sk-tmp-check did not run: {result.stderr.strip()}"
    assert "sk-tmp-check: " in result.stderr and " files" in result.stderr, result.stderr
    paths = [line for line in result.stdout.splitlines() if PATH_FINDING in line]
    assert not paths, (
        "sk-tmp-check reports a system tempdir path in a tracked file. Write under the repo's "
        "git-ignored tmp/ instead, or, for incident evidence kept as recovered, end the line with "
        "the tmp-ok comment incident/REDACTIONS.md quotes and move its counts:\n" + "\n".join(paths)
    )
