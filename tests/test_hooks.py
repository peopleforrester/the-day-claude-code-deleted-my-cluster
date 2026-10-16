# ABOUTME: Behavioral tests for the published hooks: feed each one the input its event sends
# ABOUTME: and assert the verdict (exit code, message) it is documented to return.

from __future__ import annotations

import json
import os
import shutil
import subprocess
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent
CLAUDE_HOOKS = REPO_ROOT / "hooks" / "claude-code"
GITHOOKS = REPO_ROOT / "guardrails-three-layer" / "layer-1-git-ci" / ".githooks"
# Resolved once, so tests that narrow PATH can still launch the interpreter.
BASH = shutil.which("bash")
assert BASH is not None, "bash is required on PATH to run the hook tests"


def run_hook(
    script: Path,
    payload: dict | None = None,
    *,
    stdin: str | None = None,
    args: tuple[str, ...] = (),
    cwd: Path | None = None,
    env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[str]:
    if payload is not None:
        stdin = json.dumps(payload)
    return subprocess.run(
        [BASH, str(script), *args],
        input=stdin or "",
        capture_output=True,
        text=True,
        cwd=cwd,
        env={**os.environ, **(env or {})},
        timeout=30,
    )


def git(repo: Path, *args: str) -> str:
    return subprocess.run(
        ["git", "-C", str(repo), *args], check=True, capture_output=True, text=True
    ).stdout.strip()


@pytest.fixture()
def git_repo(tmp_path: Path) -> Path:
    repo = tmp_path / "repo"
    repo.mkdir()
    git(repo, "init", "-q", "-b", "main")
    git(repo, "config", "user.email", "test@example.com")
    git(repo, "config", "user.name", "Test")
    git(repo, "config", "commit.gpgsign", "false")
    return repo


def commit_file(repo: Path, name: str, content: str) -> str:
    (repo / name).write_text(content)
    git(repo, "add", name)
    git(repo, "commit", "-q", "--no-verify", "-m", f"chore: {name}")
    return git(repo, "rev-parse", "HEAD")


# ─── block-sensitive-files.sh (PreToolUse Edit|Write) ──────────────────

BLOCK_SENSITIVE = CLAUDE_HOOKS / "block-sensitive-files.sh"


@pytest.mark.parametrize(
    "path",
    [
        "/w/.env",
        "/w/.env.production",
        "/w/certs/server.pem",
        "/w/tls.KEY",
        "/w/store.p12",
        "/w/aws-credentials.json",
        "/w/db_password.txt",
        "/w/.ssh/id_ed25519",
        "/w/.ssh/authorized_keys",
    ],
)
def test_block_sensitive_files_blocks(path: str) -> None:
    result = run_hook(BLOCK_SENSITIVE, {"tool_input": {"file_path": path}})
    assert result.returncode == 2, result.stderr
    assert "BLOCKED" in result.stderr


@pytest.mark.parametrize(
    "path",
    [
        "/w/README.md",
        "/w/src/tokens.py",
        "/w/docs/password-reset.md",
        "/w/config.yaml",
        "/w/.environment-notes",
    ],
)
def test_block_sensitive_files_allows(path: str) -> None:
    result = run_hook(BLOCK_SENSITIVE, {"tool_input": {"file_path": path}})
    assert result.returncode == 0, result.stderr


def test_block_sensitive_files_ignores_calls_without_a_path() -> None:
    result = run_hook(BLOCK_SENSITIVE, {"tool_input": {"command": "ls"}})
    assert result.returncode == 0


# ─── check-commit-message.sh (PreToolUse Bash) ─────────────────────────

CHECK_COMMIT = CLAUDE_HOOKS / "check-commit-message.sh"


def test_check_commit_message_ignores_other_tools() -> None:
    result = run_hook(CHECK_COMMIT, {"tool_name": "Edit", "tool_input": {"file_path": "x"}})
    assert result.returncode == 0


def test_check_commit_message_ignores_non_commit_commands() -> None:
    payload = {"tool_name": "Bash", "tool_input": {"command": "git status && ls claude-config/"}}
    result = run_hook(CHECK_COMMIT, payload)
    assert result.returncode == 0


# ─── enforce-prd-issue-first.sh (PreToolUse Edit|Write) ────────────────

ENFORCE_PRD = CLAUDE_HOOKS / "enforce-prd-issue-first.sh"


def test_prd_without_issue_is_blocked(tmp_path: Path) -> None:
    target = tmp_path / "prds" / "12-new-thing.md"
    result = run_hook(
        ENFORCE_PRD,
        {"tool_input": {"file_path": str(target)}},
        env={"PRD_HOOK_ASSUME_EXISTS": "0"},
    )
    assert result.returncode == 2
    assert "issue #12 does not exist" in result.stderr


def test_prd_with_issue_is_allowed(tmp_path: Path) -> None:
    target = tmp_path / "prds" / "12-new-thing.md"
    result = run_hook(
        ENFORCE_PRD,
        {"tool_input": {"file_path": str(target)}},
        env={"PRD_HOOK_ASSUME_EXISTS": "1"},
    )
    assert result.returncode == 0


def test_grandfathered_prd_is_allowed(tmp_path: Path) -> None:
    target = tmp_path / "prds" / "7-old-thing.md"
    result = run_hook(
        ENFORCE_PRD,
        {"tool_input": {"file_path": str(target)}},
        env={"PRD_HOOK_ASSUME_EXISTS": "0", "PRD_GRANDFATHERED": "6 7 8"},
    )
    assert result.returncode == 0


def test_editing_an_existing_prd_is_allowed(tmp_path: Path) -> None:
    target = tmp_path / "prds" / "12-new-thing.md"
    target.parent.mkdir()
    target.write_text("# PRD 12\n")
    result = run_hook(
        ENFORCE_PRD,
        {"tool_input": {"file_path": str(target)}},
        env={"PRD_HOOK_ASSUME_EXISTS": "0"},
    )
    assert result.returncode == 0


@pytest.mark.parametrize(
    "rel", ["prds/README.md", "prds/done/12-old.md", "src/12-thing.md", "prds/template.md"]
)
def test_non_prd_paths_are_ignored(tmp_path: Path, rel: str) -> None:
    result = run_hook(
        ENFORCE_PRD,
        {"tool_input": {"file_path": str(tmp_path / rel)}},
        env={"PRD_HOOK_ASSUME_EXISTS": "0"},
    )
    assert result.returncode == 0


# ─── check-aboutme.sh (PostToolUse Edit|Write, warn only) ──────────────

CHECK_ABOUTME = CLAUDE_HOOKS / "check-aboutme.sh"


def test_aboutme_warns_on_missing_header(tmp_path: Path) -> None:
    target = tmp_path / "module.py"
    target.write_text("import os\n")
    result = run_hook(CHECK_ABOUTME, {"tool_name": "Write", "tool_input": {"file_path": str(target)}})
    assert result.returncode == 0
    assert "missing ABOUTME" in result.stdout


def test_aboutme_quiet_when_header_present(tmp_path: Path) -> None:
    target = tmp_path / "module.py"
    target.write_text("#!/usr/bin/env python3\n# ABOUTME: does a thing\nimport os\n")
    result = run_hook(CHECK_ABOUTME, {"tool_name": "Edit", "tool_input": {"file_path": str(target)}})
    assert result.returncode == 0
    assert result.stdout == ""


@pytest.mark.parametrize("name", ["__init__.py", "notes.md"])
def test_aboutme_skips_exempt_files(tmp_path: Path, name: str) -> None:
    target = tmp_path / name
    target.write_text("x = 1\n")
    result = run_hook(CHECK_ABOUTME, {"tool_name": "Write", "tool_input": {"file_path": str(target)}})
    assert result.returncode == 0
    assert result.stdout == ""


# ─── Layer 1 commit-msg ────────────────────────────────────────────────

COMMIT_MSG = GITHOOKS / "commit-msg"


@pytest.mark.parametrize(
    "message, expected",
    [
        ("feat(api): add the thing\n", 0),
        ("fix: handle empty input\n", 0),
        ("Merge branch 'staging'\n", 0),
        ("added some stuff\n", 1),
        ("feat: add x\n\nCo-authored-by: Claude <noreply@anthropic.com>\n", 1),
        (
            "feat: add x\n\nCo-authored-by: Claude <noreply@anthropic.com>\n"
            "Reviewed-by: Human Person <human@example.com>\n",
            0,
        ),
    ],
)
def test_commit_msg(tmp_path: Path, message: str, expected: int) -> None:
    msg_file = tmp_path / "COMMIT_EDITMSG"
    msg_file.write_text(message)
    result = run_hook(COMMIT_MSG, args=(str(msg_file),))
    assert result.returncode == expected, result.stderr


# ─── Layer 1 pre-commit ────────────────────────────────────────────────

PRE_COMMIT = GITHOOKS / "pre-commit"

# Assembled at runtime so this file does not itself trip the scanners it tests.
DESTRUCTIVE_LINE = " ".join(["kubectl", "delete", "namespace", "prod"])
FAKE_AWS_KEY = "AKIA" + "Q" * 16


def stage(repo: Path, name: str, content: str) -> None:
    (repo / name).write_text(content)
    git(repo, "add", name)


def test_pre_commit_allows_clean_change(git_repo: Path) -> None:
    stage(git_repo, "notes.md", "nothing to see here\n")
    result = run_hook(PRE_COMMIT, cwd=git_repo)
    assert result.returncode == 0, result.stderr


def test_pre_commit_blocks_destructive_command(git_repo: Path) -> None:
    stage(git_repo, "run.sh", f"{DESTRUCTIVE_LINE}\n")
    result = run_hook(PRE_COMMIT, cwd=git_repo)
    assert result.returncode == 1
    assert "Destructive pattern" in result.stderr


def test_pre_commit_honours_allow_marker(git_repo: Path) -> None:
    stage(git_repo, "slide.md", f"{DESTRUCTIVE_LINE}  # guardrails:allow-destructive\n")
    result = run_hook(PRE_COMMIT, cwd=git_repo)
    assert result.returncode == 0, result.stderr


def test_pre_commit_blocks_secret(git_repo: Path) -> None:
    stage(git_repo, "config.txt", f"aws_access_key_id = {FAKE_AWS_KEY}\n")
    result = run_hook(PRE_COMMIT, cwd=git_repo)
    assert result.returncode == 1
    assert "Possible secret" in result.stderr


def test_pre_commit_with_nothing_staged(git_repo: Path) -> None:
    result = run_hook(PRE_COMMIT, cwd=git_repo)
    assert result.returncode == 0


# ─── Layer 1 pre-push ──────────────────────────────────────────────────

PRE_PUSH = GITHOOKS / "pre-push"


@pytest.fixture()
def diverged(git_repo: Path) -> tuple[Path, str, str, str]:
    """A repo with base, a fast-forward child, and a rewritten sibling of that child."""
    base = commit_file(git_repo, "a.txt", "a\n")
    child = commit_file(git_repo, "b.txt", "b\n")
    git(git_repo, "checkout", "-q", "-b", "rewrite", base)
    sibling = commit_file(git_repo, "c.txt", "c\n")
    return git_repo, base, child, sibling


def push_line(local_sha: str, remote_ref: str, remote_sha: str) -> str:
    return f"refs/heads/x {local_sha} {remote_ref} {remote_sha}\n"


def test_pre_push_allows_fast_forward_to_protected(diverged) -> None:
    repo, base, child, _ = diverged
    result = run_hook(PRE_PUSH, stdin=push_line(child, "refs/heads/main", base), cwd=repo)
    assert result.returncode == 0, result.stderr


def test_pre_push_blocks_force_push_to_protected(diverged) -> None:
    repo, _, child, sibling = diverged
    result = run_hook(PRE_PUSH, stdin=push_line(sibling, "refs/heads/main", child), cwd=repo)
    assert result.returncode == 1
    assert "Force-push to protected" in result.stderr


def test_pre_push_allows_force_push_to_feature_branch(diverged) -> None:
    repo, _, child, sibling = diverged
    result = run_hook(
        PRE_PUSH, stdin=push_line(sibling, "refs/heads/feature/x", child), cwd=repo
    )
    assert result.returncode == 0, result.stderr


# ─── scripts/check-talk-video.sh ───────────────────────────────────────

CHECK_VIDEO = REPO_ROOT / "scripts" / "check-talk-video.sh"


def fake_ytdlp(tmp_path: Path, listing: str) -> dict[str, str]:
    """A stand-in yt-dlp on PATH that prints `listing`, so no network is touched."""
    bindir = tmp_path / "bin"
    bindir.mkdir()
    (bindir / "listing.txt").write_text(listing)
    stub = bindir / "yt-dlp"
    stub.write_text(f'#!/usr/bin/env bash\ncat "{bindir / "listing.txt"}"\n')
    stub.chmod(0o755)
    return {"PATH": f"{bindir}{os.pathsep}{os.environ['PATH']}"}


def test_video_found(tmp_path: Path) -> None:
    listing = (
        "NA|DevOpsDays Portland 2026 - Ignite: The Day Claude Code Deleted My Cluster|https://y/1\n"
        "NA|DevOpsDays Portland 2026 - Keynote|https://y/2\n"
    )
    result = run_hook(CHECK_VIDEO, env=fake_ytdlp(tmp_path, listing))
    assert result.returncode == 0, result.stderr
    assert "FOUND:" in result.stdout
    assert "Deleted My Cluster" in result.stdout


def test_video_not_yet(tmp_path: Path) -> None:
    listing = "".join(f"NA|DevOpsDays Portland 2021 - Talk {i}|https://y/{i}\n" for i in range(5))
    result = run_hook(CHECK_VIDEO, env=fake_ytdlp(tmp_path, listing))
    assert result.returncode == 1, result.stderr
    assert "NOT YET" in result.stdout
    assert "Talk 2" in result.stdout and "Talk 3" not in result.stdout


def test_video_old_year_match_is_not_a_hit(tmp_path: Path) -> None:
    listing = "NA|DevOpsDays Portland 2019 - Ignite: Cluster stories|https://y/1\n"
    result = run_hook(CHECK_VIDEO, env=fake_ytdlp(tmp_path, listing))
    assert result.returncode == 1


def test_video_empty_listing_is_inconclusive(tmp_path: Path) -> None:
    result = run_hook(CHECK_VIDEO, env=fake_ytdlp(tmp_path, ""))
    assert result.returncode == 2
    assert "INCONCLUSIVE" in result.stdout


def test_video_missing_ytdlp_is_inconclusive(tmp_path: Path) -> None:
    empty = tmp_path / "empty"
    empty.mkdir()
    result = run_hook(CHECK_VIDEO, env={"PATH": str(empty)})
    assert result.returncode == 2
    assert "yt-dlp is not on PATH" in result.stderr


def test_video_rejects_unknown_argument(tmp_path: Path) -> None:
    result = run_hook(CHECK_VIDEO, args=("--bogus",), env=fake_ytdlp(tmp_path, "x\n"))
    assert result.returncode == 2
    assert "unknown argument" in result.stderr


def test_video_help() -> None:
    result = run_hook(CHECK_VIDEO, args=("--help",))
    assert result.returncode == 0
    assert "Usage:" in result.stdout
