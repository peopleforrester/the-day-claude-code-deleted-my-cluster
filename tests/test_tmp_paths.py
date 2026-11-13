# ABOUTME: Holds this repo's temp files to its own git-ignored tmp/: the suite's tmp_path, the kit's
# ABOUTME: Layer 3 hooks, and the tmp-ok waiver on the incident evidence lines that name a node's /tmp (#48).

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from types import SimpleNamespace

import pytest

from tests import conftest
from tests.test_hooks import run_hook

REPO_ROOT = Path(__file__).resolve().parent.parent
REPO_TMP = REPO_ROOT / "tmp"
ARTIFACTS = REPO_ROOT / "incident" / "session-artifacts"
HOOKS_DIR = REPO_ROOT / "guardrails-three-layer" / "layer-3-claude-hooks" / ".claude" / "hooks"
PROBE = REPO_ROOT / "tests" / "probes" / "tmp_path_probe.py"

# A system tempdir where a path starts, not as a later component of another path.
SYSTEM_TMP = re.compile(r"""(?:^|[\s"'=:>(])/(?:tmp|var/tmp|dev/shm)(?![\w.-])""")
WAIVER = "  # tmp-ok: incident evidence kept verbatim, see incident/REDACTIONS.md"
TEMP_VARS = ("TMPDIR", "TMP", "TEMP")


# ─── .gitignore ────────────────────────────────────────────────────────


def test_gitignore_covers_tmp() -> None:
    """The tracked .gitignore ignores tmp/, not a clone's own .git/info/exclude."""
    result = subprocess.run(
        ["git", "-C", str(REPO_ROOT), "check-ignore", "-v", "--no-index", "tmp/claude-tests.log"],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, ".gitignore does not cover tmp/"
    assert result.stdout.startswith(".gitignore:"), result.stdout


# ─── the suite's own tmp_path ──────────────────────────────────────────


class FakeConfig:
    """As much of pytest.Config as conftest.pytest_configure touches."""

    def __init__(self, basetemp: str | None) -> None:
        self.option = SimpleNamespace(basetemp=basetemp)
        self.cleanups: list = []

    def add_cleanup(self, func) -> None:
        self.cleanups.append(func)

    def unconfigure(self) -> None:
        while self.cleanups:
            self.cleanups.pop()()


def test_configure_roots_basetemp_under_tmp_and_removes_it(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("TMPDIR", raising=False)
    monkeypatch.setenv("GIT_CEILING_DIRECTORIES", "/elsewhere")
    config = FakeConfig(None)
    conftest.pytest_configure(config)
    basetemp = Path(config.option.basetemp)
    root = basetemp.parent
    try:
        assert root.parent == REPO_TMP
        assert root.is_dir()
        assert os.environ["GIT_CEILING_DIRECTORIES"] == f"{root}{os.pathsep}/elsewhere"
    finally:
        config.unconfigure()
    assert not root.exists()
    assert os.environ["GIT_CEILING_DIRECTORIES"] == "/elsewhere"


def test_configure_keeps_a_session_dir_inside_tmp(monkeypatch: pytest.MonkeyPatch) -> None:
    REPO_TMP.mkdir(exist_ok=True)
    session = Path(tempfile.mkdtemp(prefix="session-", dir=REPO_TMP))
    monkeypatch.setenv("TMPDIR", str(session))
    config = FakeConfig(None)
    try:
        conftest.pytest_configure(config)
        assert Path(config.option.basetemp).parent.parent == session
    finally:
        config.unconfigure()
        shutil.rmtree(session)


def test_configure_ignores_a_tmpdir_outside_the_checkout(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("TMPDIR", str(REPO_ROOT.parent))
    config = FakeConfig(None)
    conftest.pytest_configure(config)
    try:
        assert Path(config.option.basetemp).parent.parent == REPO_TMP
    finally:
        config.unconfigure()


def test_configure_leaves_an_explicit_basetemp_alone() -> None:
    config = FakeConfig("somewhere/else")
    conftest.pytest_configure(config)
    assert config.option.basetemp == "somewhere/else"
    assert config.cleanups == []


def test_a_run_from_a_plain_shell_keeps_tmp_path_in_tmp_and_cleans_up() -> None:
    """A child pytest with no TMPDIR, as a person at a shell runs it.

    Proves what the unit tests cannot: the hook fires before pytest's tmpdir
    plugin reads the option, and the run's directory is gone when it ends.
    """
    env = {k: v for k, v in os.environ.items() if k not in TEMP_VARS}
    env.pop("GIT_CEILING_DIRECTORIES", None)
    result = subprocess.run(
        [sys.executable, "-m", "pytest", "-q", "-s", "-p", "no:cacheprovider", str(PROBE)],
        cwd=REPO_ROOT,
        env=env,
        capture_output=True,
        text=True,
        timeout=120,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    reported = dict(re.findall(r"^PROBE (\w+)=(.*)$", result.stdout, re.M))
    tmp_path = Path(reported["tmp_path"])
    assert tmp_path.is_relative_to(REPO_TMP), f"tmp_path {tmp_path} is outside {REPO_TMP}"
    run_root = REPO_TMP / tmp_path.relative_to(REPO_TMP).parts[0]
    assert run_root.name.startswith("pytest-"), f"tmp_path {tmp_path} is not in a run's own directory"
    assert reported["git"] != "0", "git run inside tmp_path climbed into this checkout"
    assert not run_root.exists(), f"the run left {run_root} behind"


# ─── Layer 3 kit hooks ─────────────────────────────────────────────────


@pytest.mark.parametrize("hook", ["stop-run-tests.sh", "block-destructive-bash.sh"])
def test_kit_hook_names_no_system_tempdir(hook: str) -> None:
    body = (HOOKS_DIR / hook).read_text(encoding="utf-8")
    hits = [line for line in body.splitlines() if SYSTEM_TMP.search(line)]
    assert not hits, f"{hook} names a system tempdir: {hits}"


def _project(tmp_path: Path, pytest_exit: int) -> tuple[Path, dict[str, str]]:
    """A Python project and a PATH whose pytest prints a line and exits as told."""
    project = tmp_path / "project"
    project.mkdir()
    (project / "pyproject.toml").write_text("[project]\nname = 'x'\n")
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    stub = bin_dir / "pytest"
    stub.write_text(f"#!/usr/bin/env bash\necho 'suite output'\nexit {pytest_exit}\n")
    stub.chmod(0o755)
    env = {"PATH": f"{bin_dir}{os.pathsep}{os.environ['PATH']}", "CLAUDE_PROJECT_DIR": str(project)}
    return project, env


def test_stop_hook_logs_a_failing_suite_under_the_project_tmp(tmp_path: Path) -> None:
    project, env = _project(tmp_path, pytest_exit=1)
    result = run_hook(HOOKS_DIR / "stop-run-tests.sh", {"stop_hook_active": False}, cwd=project, env=env)
    assert result.returncode == 2
    assert "pytest failed" in result.stderr
    assert (project / "tmp" / "claude-tests.log").read_text() == "suite output\n"


def test_stop_hook_lets_a_passing_suite_end_the_turn(tmp_path: Path) -> None:
    project, env = _project(tmp_path, pytest_exit=0)
    result = run_hook(HOOKS_DIR / "stop-run-tests.sh", {"stop_hook_active": False}, cwd=project, env=env)
    assert result.returncode == 0, result.stderr
    assert (project / "tmp" / "claude-tests.log").read_text() == "suite output\n"


def test_stop_hook_creates_no_tmp_when_it_runs_no_suite(tmp_path: Path) -> None:
    result = run_hook(
        HOOKS_DIR / "stop-run-tests.sh",
        {"stop_hook_active": False},
        cwd=tmp_path,
        env={"CLAUDE_PROJECT_DIR": str(tmp_path)},
    )
    assert result.returncode == 0, result.stderr
    assert not (tmp_path / "tmp").exists()


NETPLAN = {"tool_name": "Bash", "tool_input": {"command": "sudo netplan apply"}}


def test_netplan_apply_is_denied_without_a_backup_in_the_project_tmp(tmp_path: Path) -> None:
    project = tmp_path / "my project"
    project.mkdir()
    result = run_hook(
        HOOKS_DIR / "block-destructive-bash.sh",
        NETPLAN,
        cwd=project,
        env={"CLAUDE_PROJECT_DIR": str(project)},
    )
    assert result.returncode == 0, result.stderr
    verdict = json.loads(result.stdout)["hookSpecificOutput"]
    assert verdict["permissionDecision"] == "deny"
    reason = verdict["permissionDecisionReason"]
    assert f"{project}/tmp/netplan-backup-*.yaml" in reason
    assert f"mkdir -p '{project}/tmp' && cp /etc/netplan/*.yaml '{project}/tmp'/netplan-backup-" in reason


def test_netplan_apply_passes_once_the_backup_exists(tmp_path: Path) -> None:
    project = tmp_path / "my project"
    (project / "tmp").mkdir(parents=True)
    (project / "tmp" / "netplan-backup-1793462400.yaml").write_text("network: {}\n")
    result = run_hook(
        HOOKS_DIR / "block-destructive-bash.sh",
        NETPLAN,
        cwd=project,
        env={"CLAUDE_PROJECT_DIR": str(project)},
    )
    assert result.returncode == 0, result.stderr
    assert result.stdout == ""


# ─── the waiver on the incident evidence ───────────────────────────────


def _waived() -> list[tuple[Path, int, str]]:
    found = []
    for path in sorted(p for p in ARTIFACTS.rglob("*") if p.is_file()):
        text = path.read_text(encoding="utf-8", errors="replace")
        for number, line in enumerate(text.split("\n"), start=1):
            if "tmp-ok" in line:
                found.append((path, number, line))
    return found


WAIVED = _waived()


def test_redactions_states_the_waiver_count() -> None:
    text = (REPO_ROOT / "incident" / "REDACTIONS.md").read_text(encoding="utf-8")
    stated = re.search(r"It is on (\d+) lines in (\d+) files", text)
    assert stated, "REDACTIONS.md does not say how many lines carry the tmp-ok comment"
    assert WAIVER.strip() in text, "REDACTIONS.md does not quote the comment as the tree carries it"
    lines, files = int(stated.group(1)), int(stated.group(2))
    assert (len(WAIVED), len({path for path, _, _ in WAIVED})) == (lines, files)


def test_waiver_is_one_fixed_comment_at_the_end_of_a_line_naming_a_tempdir() -> None:
    """Cutting the comment off gives the original line back, so it has one form and one place."""
    assert WAIVED, "no tmp-ok comment found in the session artifacts"
    wrong = []
    for path, number, line in WAIVED:
        original = line.removesuffix(WAIVER)
        fits = (
            line.endswith(WAIVER)
            and "tmp-ok" not in original
            and original == original.rstrip()
            and SYSTEM_TMP.search(original)
        )
        if not fits:
            wrong.append(f"{path.relative_to(REPO_ROOT)}:{number}")
    assert not wrong, f"tmp-ok comment out of form at {wrong}"
