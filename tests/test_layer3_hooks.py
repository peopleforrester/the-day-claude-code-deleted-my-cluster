# ABOUTME: Tests the Layer 3 template: every hook settings.json runs is a tracked, executable script,
# ABOUTME: and prompt-secret-scan.sh blocks each of Layer 1's secret patterns without echoing the value.

from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path

import pytest

from tests.test_hooks import run_hook

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
