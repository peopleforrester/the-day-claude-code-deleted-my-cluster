# ABOUTME: Lints every published shell script: bash syntax always, shellcheck errors when present.
# ABOUTME: The forensic copies under incident/ are evidence and are deliberately excluded.

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

import pytest

# Directories holding scripts readers are told to copy and run.
PUBLISHED_DIRS = ("hooks", "scripts", "guardrails-three-layer")


def _shell_scripts(repo_root: Path) -> list[Path]:
    scripts = []
    for top in PUBLISHED_DIRS:
        for path in sorted((repo_root / top).rglob("*")):
            if not path.is_file():
                continue
            with path.open("rb") as handle:
                first = handle.readline()
            if first.startswith(b"#!") and (b"bash" in first or first.rstrip().endswith(b"/sh")):
                scripts.append(path)
    return scripts


REPO_ROOT = Path(__file__).resolve().parent.parent
SCRIPTS = _shell_scripts(REPO_ROOT)


def test_published_scripts_found() -> None:
    """Guard against the walk silently finding nothing and every lint passing vacuously."""
    assert len(SCRIPTS) >= 20, f"expected the published hooks and scripts, found {len(SCRIPTS)}"


@pytest.mark.parametrize("script", SCRIPTS, ids=lambda p: str(p.relative_to(REPO_ROOT)))
def test_bash_syntax(script: Path) -> None:
    result = subprocess.run(["bash", "-n", str(script)], capture_output=True, text=True)
    assert result.returncode == 0, result.stderr


@pytest.mark.parametrize("script", SCRIPTS, ids=lambda p: str(p.relative_to(REPO_ROOT)))
def test_shellcheck_errors(script: Path) -> None:
    if shutil.which("shellcheck") is None:
        pytest.skip("shellcheck not installed")
    result = subprocess.run(
        ["shellcheck", "--severity=error", str(script)], capture_output=True, text=True
    )
    assert result.returncode == 0, result.stdout
