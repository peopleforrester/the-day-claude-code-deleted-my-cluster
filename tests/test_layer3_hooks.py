# ABOUTME: Tests the Layer 3 template: every hook settings.json runs is a tracked, executable script,
# ABOUTME: prompt-secret-scan.sh blocks Layer 1's secret patterns, and no hook keeps a file in /tmp.

from __future__ import annotations

import json
import os
import re
import subprocess
from pathlib import Path

import pytest

from tests.test_hooks import BASH, run_hook

REPO_ROOT = Path(__file__).resolve().parent.parent
LAYER3 = REPO_ROOT / "guardrails-three-layer" / "layer-3-claude-hooks"
SETTINGS = LAYER3 / ".claude" / "settings.json"
HOOKS_DIR = LAYER3 / ".claude" / "hooks"
PRE_COMMIT = REPO_ROOT / "guardrails-three-layer" / "layer-1-git-ci" / ".githooks" / "pre-commit"

PROJECT_HOOK = re.compile(r'^"\$CLAUDE_PROJECT_DIR"/\.claude/hooks/([^\s"/]+)$')


def _commands() -> list[str]:
    settings = json.loads(SETTINGS.read_text(encoding="utf-8"))
    return [
        hook["command"]
        for groups in settings["hooks"].values()
        for group in groups
        for hook in group["hooks"]
        if hook["type"] == "command"
    ]


COMMANDS = _commands()


def _index_modes() -> dict[str, str]:
    """Mode of every tracked path, as a reader's clone checks it out."""
    result = subprocess.run(
        ["git", "-C", str(REPO_ROOT), "ls-files", "-s", "--", str(HOOKS_DIR)],
        check=True,
        capture_output=True,
        text=True,
    )
    modes = {}
    for line in result.stdout.splitlines():
        meta, path = line.split("\t", 1)
        modes[path] = meta.split()[0]
    return modes


def test_settings_wires_hooks() -> None:
    """Guard against the walk finding nothing and the path check passing vacuously."""
    assert len(COMMANDS) >= 9, f"expected the template's hook wiring, found {COMMANDS}"


@pytest.mark.parametrize("command", COMMANDS)
def test_settings_command_is_a_tracked_executable_hook(command: str) -> None:
    match = PROJECT_HOOK.match(command)
    assert match, f"{command} does not run a script under .claude/hooks/"
    script = HOOKS_DIR / match.group(1)
    rel = str(script.relative_to(REPO_ROOT))
    mode = _index_modes().get(rel)
    assert mode is not None, f"settings.json runs {rel}, which a clone of this repo does not hold"
    assert mode == "100755", f"settings.json runs {rel}, which is tracked as {mode}, not executable"


# ─── prompt-secret-scan.sh (UserPromptSubmit) ──────────────────────────

PROMPT_SCAN = HOOKS_DIR / "prompt-secret-scan.sh"

# Assembled at runtime so this file does not itself trip the scanners it tests.
FAKE_SECRETS = {
    "aws-access-key": "AKIA" + "Q" * 16,
    "aws-session-key": "ASIA" + "Q" * 16,
    "private-key": "-----BEGIN " + "OPENSSH PRIVATE KEY" + "-----",
    "github-classic": "ghp_" + "a1" * 18,
    "github-fine-grained": "github_pat_" + "b2_" * 8,
    "slack": "xox" + "b-" + "1234567890-abc",
    "openai": "sk-" + "c3" * 16,
    "google": "AIza" + "d4_-" * 8 + "xyz",
}


def _secret_patterns(path: Path) -> list[str]:
    body = path.read_text(encoding="utf-8")
    block = re.search(r"^SECRET_PATTERNS=\(\n(.*?)^\)", body, re.MULTILINE | re.DOTALL)
    assert block, f"{path.name} has no SECRET_PATTERNS array"
    return re.findall(r"^\s+'([^']+)'$", block.group(1), re.MULTILINE)


def test_prompt_scan_uses_layer_1_patterns() -> None:
    """The prompt guard and the commit guard agree on what a secret looks like."""
    patterns = _secret_patterns(PROMPT_SCAN)
    assert len(patterns) == 8
    assert patterns == _secret_patterns(PRE_COMMIT)


def test_fake_secrets_cover_every_pattern() -> None:
    for pat in _secret_patterns(PROMPT_SCAN):
        assert any(re.search(pat, s) for s in FAKE_SECRETS.values()), f"no fake secret for /{pat}/"


@pytest.mark.parametrize("name", FAKE_SECRETS)
def test_prompt_scan_blocks_secret(name: str) -> None:
    secret = FAKE_SECRETS[name]
    prompt = f"Deploy with this credential:\n{secret}\nthen tell me how it went."
    result = run_hook(PROMPT_SCAN, {"hook_event_name": "UserPromptSubmit", "prompt": prompt})
    assert result.returncode == 0, result.stderr
    verdict = json.loads(result.stdout)
    assert verdict["decision"] == "block"
    assert "pattern:" in verdict["reason"]
    assert secret not in result.stdout + result.stderr


@pytest.mark.parametrize(
    "prompt",
    [
        "Rotate the AWS key and store it in the secret manager.",
        "Explain what an sk- prefix means on an API key.",
        "Why does ghp_ show up in our push protection alerts?",
        "-----BEGIN CERTIFICATE-----",
    ],
)
def test_prompt_scan_allows_clean_prompt(prompt: str) -> None:
    result = run_hook(PROMPT_SCAN, {"hook_event_name": "UserPromptSubmit", "prompt": prompt})
    assert result.returncode == 0, result.stderr
    assert result.stdout == ""


def test_prompt_scan_allows_empty_prompt() -> None:
    result = run_hook(PROMPT_SCAN, {"hook_event_name": "UserPromptSubmit"})
    assert result.returncode == 0, result.stderr
    assert result.stdout == ""


# ─── the hooks keep their files in the project's tmp/, never /tmp (#48) ──

STOP_TESTS = HOOKS_DIR / "stop-run-tests.sh"
BLOCK_BASH = HOOKS_DIR / "block-destructive-bash.sh"

# A path that starts at a system tempdir, as a word of its own or after `=`, `:` or `>`.
SYSTEM_TMP = re.compile(r"""(?:^|[\s"'=:>(])(?:/tmp|/var/tmp|/dev/shm)(?:/|\b)""", re.MULTILINE)

# Each suite stop-run-tests.sh knows: the file that selects it, the program it runs.
RUNNERS = {
    "package.json": "npm",
    "pyproject.toml": "pytest",
    "Cargo.toml": "cargo",
    "go.mod": "go",
}


def _run_in_project(
    script: Path, payload: dict, project: Path, *, path: str | None = None, named: bool = True
) -> subprocess.CompletedProcess[str]:
    """Run a hook from `project`, with CLAUDE_PROJECT_DIR naming it or unset."""
    env = {k: v for k, v in os.environ.items() if k != "CLAUDE_PROJECT_DIR"}
    if named:
        env["CLAUDE_PROJECT_DIR"] = str(project)
    if path is not None:
        env["PATH"] = path
    return subprocess.run(
        [BASH, str(script)],
        input=json.dumps(payload),
        capture_output=True,
        text=True,
        cwd=project,
        env=env,
        timeout=30,
    )


def _stub_runner(tmp_path: Path, program: str, exit_code: int) -> str:
    """A PATH whose `program` prints a line on each stream and exits `exit_code`."""
    stubs = tmp_path / "stubs"
    stubs.mkdir(exist_ok=True)
    stub = stubs / program
    stub.write_text(
        f'#!/usr/bin/env bash\necho "{program} stub out"\necho "{program} stub err" >&2\n'
        f"exit {exit_code}\n"
    )
    stub.chmod(0o755)
    return f"{stubs}{os.pathsep}{os.environ['PATH']}"


def _project(tmp_path: Path, marker: str | None = None) -> Path:
    project = tmp_path / "project"
    project.mkdir()
    if marker is not None:
        (project / marker).write_text("")
    return project


@pytest.mark.parametrize("script", sorted(HOOKS_DIR.glob("*.sh")), ids=lambda p: p.name)
def test_no_layer3_hook_names_a_system_tempdir(script: Path) -> None:
    hits = SYSTEM_TMP.findall(script.read_text(encoding="utf-8"))
    assert not hits, f"{script.name} names a system tempdir: {hits}"


@pytest.mark.parametrize(
    "line",
    [
        "    npm test --silent >/tmp/claude-tests.log 2>&1",
        "    if ! ls /tmp/netplan-backup-*.yaml >/dev/null 2>&1; then",
        'LOG="/var/tmp/x.log"',
        "cp a /dev/shm/b",
    ],
)
def test_system_tempdir_pattern_catches_the_original_shapes(line: str) -> None:
    """Guard against a pattern that silently matches nothing."""
    assert SYSTEM_TMP.search(line)


@pytest.mark.parametrize(
    "line",
    [
        'LOG_DIR="${CLAUDE_PROJECT_DIR:-${PWD}}/tmp"',
        '    if ! ls "${BACKUP_DIR}"/netplan-backup-*.yaml >/dev/null 2>&1; then',
        "/home/me/project/tmp/claude-tests.log",
    ],
)
def test_system_tempdir_pattern_passes_a_project_tmp(line: str) -> None:
    assert not SYSTEM_TMP.search(line)


@pytest.mark.parametrize(("marker", "program"), RUNNERS.items(), ids=list(RUNNERS.values()))
def test_stop_hook_logs_a_failing_suite_under_the_project_tmp(
    tmp_path: Path, marker: str, program: str
) -> None:
    project = _project(tmp_path, marker)
    result = _run_in_project(
        STOP_TESTS, {"stop_hook_active": False}, project, path=_stub_runner(tmp_path, program, 1)
    )
    log = project / "tmp" / "claude-tests.log"
    assert result.returncode == 2, result.stderr
    assert "Stop blocked" in result.stderr and "failed" in result.stderr
    assert str(log) in result.stderr
    assert log.read_text() == f"{program} stub out\n{program} stub err\n"
    assert not SYSTEM_TMP.search(result.stderr.replace(str(project), "PROJECT")), result.stderr


@pytest.mark.parametrize(("marker", "program"), RUNNERS.items(), ids=list(RUNNERS.values()))
def test_stop_hook_lets_a_passing_suite_stop_and_keeps_its_log(
    tmp_path: Path, marker: str, program: str
) -> None:
    project = _project(tmp_path, marker)
    result = _run_in_project(
        STOP_TESTS, {"stop_hook_active": False}, project, path=_stub_runner(tmp_path, program, 0)
    )
    assert result.returncode == 0, result.stderr
    assert result.stderr == ""
    assert (project / "tmp" / "claude-tests.log").read_text().startswith(f"{program} stub out\n")


def test_stop_hook_uses_the_working_directory_without_a_project_dir(tmp_path: Path) -> None:
    project = _project(tmp_path, "package.json")
    result = _run_in_project(
        STOP_TESTS,
        {"stop_hook_active": False},
        project,
        path=_stub_runner(tmp_path, "npm", 1),
        named=False,
    )
    assert result.returncode == 2, result.stderr
    assert (project / "tmp" / "claude-tests.log").is_file()


def test_stop_hook_tmp_ignores_itself_in_git(tmp_path: Path) -> None:
    """The log must not show up as an untracked file in the reader's repo."""
    project = _project(tmp_path, "package.json")
    subprocess.run(["git", "-C", str(project), "init", "-q"], check=True)
    _run_in_project(
        STOP_TESTS, {"stop_hook_active": False}, project, path=_stub_runner(tmp_path, "npm", 0)
    )
    assert (project / "tmp" / ".gitignore").read_text() == "*\n"
    status = subprocess.run(
        ["git", "-C", str(project), "status", "--porcelain", "--untracked-files=all"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.splitlines()
    assert status == ["?? package.json"], status


def test_stop_hook_leaves_an_existing_tmp_as_it_is(tmp_path: Path) -> None:
    project = _project(tmp_path, "package.json")
    (project / "tmp").mkdir()
    result = _run_in_project(
        STOP_TESTS, {"stop_hook_active": False}, project, path=_stub_runner(tmp_path, "npm", 0)
    )
    assert result.returncode == 0, result.stderr
    assert sorted(p.name for p in (project / "tmp").iterdir()) == ["claude-tests.log"]


@pytest.mark.parametrize(
    ("marker", "payload"),
    [
        ("package.json", {"stop_hook_active": True}),
        (None, {"stop_hook_active": False}),
    ],
    ids=["already-in-a-stop-hook", "no-suite"],
)
def test_stop_hook_writes_nothing_when_it_runs_no_suite(
    tmp_path: Path, marker: str | None, payload: dict
) -> None:
    project = _project(tmp_path, marker)
    result = _run_in_project(STOP_TESTS, payload, project, path=_stub_runner(tmp_path, "npm", 1))
    assert result.returncode == 0, result.stderr
    assert not (project / "tmp").exists()


def _netplan(project: Path, *, named: bool = True) -> subprocess.CompletedProcess[str]:
    payload = {"tool_name": "Bash", "tool_input": {"command": "sudo netplan apply"}}
    return _run_in_project(BLOCK_BASH, payload, project, named=named)


@pytest.mark.parametrize("named", [True, False], ids=["project-dir", "working-directory"])
def test_netplan_apply_is_denied_without_a_backup_in_the_project_tmp(
    tmp_path: Path, named: bool
) -> None:
    project = _project(tmp_path)
    result = _netplan(project, named=named)
    assert result.returncode == 0, result.stderr
    verdict = json.loads(result.stdout)["hookSpecificOutput"]
    assert verdict["permissionDecision"] == "deny"
    reason = verdict["permissionDecisionReason"]
    assert f"{project}/tmp/netplan-backup-*.yaml" in reason
    assert f'cp /etc/netplan/*.yaml "{project}/tmp/netplan-backup-$(date +%s).yaml"' in reason
    assert not SYSTEM_TMP.search(reason.replace(str(project), "PROJECT")), reason
    assert (project / "tmp" / ".gitignore").read_text() == "*\n"


def test_netplan_apply_is_allowed_with_a_backup_in_the_project_tmp(tmp_path: Path) -> None:
    project = _project(tmp_path)
    (project / "tmp").mkdir()
    (project / "tmp" / "netplan-backup-1793462400.yaml").write_text("network: {version: 2}\n")
    result = _netplan(project)
    assert result.returncode == 0, result.stderr
    assert result.stdout == ""


def test_netplan_backup_outside_the_project_tmp_does_not_count(tmp_path: Path) -> None:
    project = _project(tmp_path)
    (project / "netplan-backup-1793462400.yaml").write_text("network: {version: 2}\n")
    (project / "tmp").mkdir()
    (project / "tmp" / "netplan-backup-1793462400.txt").write_text("not the backup\n")
    result = _netplan(project)
    assert json.loads(result.stdout)["hookSpecificOutput"]["permissionDecision"] == "deny"
    assert sorted(p.name for p in (project / "tmp").iterdir()) == ["netplan-backup-1793462400.txt"]


def test_block_bash_creates_no_tmp_for_other_commands(tmp_path: Path) -> None:
    project = _project(tmp_path)
    payload = {"tool_name": "Bash", "tool_input": {"command": "netplan get"}}
    result = _run_in_project(BLOCK_BASH, payload, project)
    assert result.returncode == 0, result.stderr
    assert result.stdout == ""
    assert not (project / "tmp").exists()
