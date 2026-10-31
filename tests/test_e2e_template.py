# ABOUTME: Holds the workflows/ templates' test steps to failing when their suite fails, e2e.yml first.
# ABOUTME: Runs each test step's script under GitHub's default `bash -e` against a stubbed uv (#42).

from __future__ import annotations

import os
import re
import subprocess
import textwrap
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent
WORKFLOW_DIR = REPO_ROOT / "workflows"
WORKFLOWS = sorted(WORKFLOW_DIR.glob("*.yml"))

RUN = re.compile(r"^(?P<indent>\s*)(?:-\s+)?run:\s*(?P<value>.*)$")

# GitHub runs a step with no `shell:` key on Linux as `bash -e {0}`.
GITHUB_DEFAULT_SHELL = ["bash", "-e"]


def _ids(path: Path) -> str:
    return path.name


def _run_scripts(path: Path) -> list[str]:
    """Every `run:` step's script, with block scalars collected by indentation."""
    lines = path.read_text(encoding="utf-8").splitlines()
    scripts = []
    for index, line in enumerate(lines):
        match = RUN.match(line)
        if not match:
            continue
        value = match.group("value").strip()
        if value not in ("|", ">"):
            scripts.append(value)
            continue
        key_indent = len(match.group("indent"))
        block = []
        for following in lines[index + 1 :]:
            if following.strip() and len(following) - len(following.lstrip()) <= key_indent:
                break
            block.append(following)
        scripts.append(textwrap.dedent("\n".join(block)).strip() + "\n")
    return scripts


def _test_step(path: Path) -> str:
    steps = [script for script in _run_scripts(path) if "pytest" in script]
    assert len(steps) == 1, f"{path.name} has {len(steps)} pytest steps, expected one"
    return steps[0]


def _run_with_stub_uv(script: str, exit_code: int, tmp_path: Path) -> tuple[int, str]:
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    calls = tmp_path / "uv-calls"
    stub = bin_dir / "uv"
    stub.write_text(f'#!/bin/sh\necho "$@" >> "{calls}"\nexit {exit_code}\n', encoding="utf-8")
    stub.chmod(0o755)
    script_file = tmp_path / "step.sh"
    script_file.write_text(script, encoding="utf-8")
    env = {**os.environ, "PATH": f"{bin_dir}{os.pathsep}{os.environ['PATH']}"}
    result = subprocess.run(
        [*GITHUB_DEFAULT_SHELL, str(script_file)],
        cwd=tmp_path,
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )
    return result.returncode, calls.read_text(encoding="utf-8")


def test_workflows_found() -> None:
    """Guard against the glob finding nothing and every check passing vacuously."""
    assert {"ci.yml", "e2e.yml"} <= {path.name for path in WORKFLOWS}


def test_e2e_step_runs_pytest_with_no_fallback() -> None:
    """The issue's shape: `uv run pytest ... || echo ...` turned every failure into a pass."""
    commands = [line for line in _test_step(WORKFLOW_DIR / "e2e.yml").splitlines() if not line.lstrip().startswith("#")]
    assert any(re.match(r"^uv run pytest\b", line) for line in commands), commands
    assert not [line for line in commands if line.rstrip().endswith("\\")], "the pytest command continues onto a fallback"


@pytest.mark.parametrize("workflow", WORKFLOWS, ids=_ids)
def test_test_step_has_no_failure_swallowing(workflow: Path) -> None:
    script = _test_step(workflow)
    commands = "\n".join(line for line in script.splitlines() if not line.lstrip().startswith("#"))
    for shape in ("||", "set +e", "exit 0", "; true"):
        assert shape not in commands, f"{workflow.name}'s test step contains {shape!r}, which can hide a failure"
    assert "continue-on-error" not in workflow.read_text(encoding="utf-8"), f"{workflow.name} sets continue-on-error"


@pytest.mark.parametrize("exit_code", [1, 2, 4, 5])
@pytest.mark.parametrize("workflow", WORKFLOWS, ids=_ids)
def test_test_step_fails_when_its_suite_fails(workflow: Path, exit_code: int, tmp_path: Path) -> None:
    """Exit 5 is pytest's "no tests collected": an empty suite fails the gate too."""
    returncode, calls = _run_with_stub_uv(_test_step(workflow), exit_code, tmp_path)
    assert "pytest" in calls, f"{workflow.name}'s test step never ran pytest through uv: {calls!r}"
    assert returncode != 0, f"{workflow.name}'s test step passed when its suite exited {exit_code}"


@pytest.mark.parametrize("workflow", WORKFLOWS, ids=_ids)
def test_test_step_passes_when_its_suite_passes(workflow: Path, tmp_path: Path) -> None:
    returncode, calls = _run_with_stub_uv(_test_step(workflow), 0, tmp_path)
    assert "pytest" in calls
    assert returncode == 0, f"{workflow.name}'s test step failed with its suite passing"
