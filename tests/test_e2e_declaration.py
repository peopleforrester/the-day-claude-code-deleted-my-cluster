# ABOUTME: Pins the E2E command AGENTS.md declares for the heavy gate, and keeps its suite out of the Test command.
# ABOUTME: Runs offline; the E2E suite itself lives in e2e/ and needs the network.

from __future__ import annotations

import tomllib
from pathlib import Path

E2E_LINE = "E2E command: `uv run --group e2e pytest -q e2e`"


def test_agents_md_declares_the_e2e_command_once(repo_root: Path) -> None:
    lines = (repo_root / "AGENTS.md").read_text(encoding="utf-8").splitlines()
    assert [line for line in lines if line.startswith("E2E command:")] == [E2E_LINE]


def test_e2e_suite_exists_outside_the_test_paths(repo_root: Path) -> None:
    """The light Test command collects tests/ only, so it never needs the network."""
    pyproject = tomllib.loads((repo_root / "pyproject.toml").read_text(encoding="utf-8"))
    assert pyproject["tool"]["pytest"]["ini_options"]["testpaths"] == ["tests"]
    assert list((repo_root / "e2e").glob("test_*.py")), "e2e/ holds no test files"


def test_e2e_group_pins_yt_dlp(repo_root: Path) -> None:
    """The live video check needs yt-dlp, pinned so the heavy gate is reproducible."""
    pyproject = tomllib.loads((repo_root / "pyproject.toml").read_text(encoding="utf-8"))
    group = pyproject["dependency-groups"]["e2e"]
    assert any(dep.startswith("yt-dlp==") for dep in group), group
