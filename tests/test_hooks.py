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


def commit_payload(message: str) -> dict:
    return {"tool_name": "Bash", "tool_input": {"command": f'git commit -m "{message}"'}}


@pytest.fixture()
def installed_hooks(tmp_path: Path) -> Path:
    """The hooks copied the way hooks/README.md says to, away from this repo's tree (#18)."""
    dest = tmp_path / ".claude" / "hooks"
    dest.mkdir(parents=True)
    subprocess.run(["cp", "-R", f"{CLAUDE_HOOKS}/.", str(dest)], check=True)
    return dest


@pytest.mark.parametrize("hooks_dir", ["repo", "installed"])
def test_check_commit_message_allows_clean_message(
    hooks_dir: str, installed_hooks: Path
) -> None:
    script = CHECK_COMMIT if hooks_dir == "repo" else installed_hooks / CHECK_COMMIT.name
    result = run_hook(script, commit_payload("Fix the retry loop\n\nIssue #18"))
    assert result.returncode == 0, result.stderr
    assert result.stderr == ""


@pytest.mark.parametrize("hooks_dir", ["repo", "installed"])
def test_check_commit_message_blocks_attribution(hooks_dir: str, installed_hooks: Path) -> None:
    script = CHECK_COMMIT if hooks_dir == "repo" else installed_hooks / CHECK_COMMIT.name
    result = run_hook(script, commit_payload("Fix the retry loop\n\nGenerated with Claude Code"))
    assert result.returncode == 2
    assert 'AI/Claude reference: "Claude Code"' in result.stderr


@pytest.mark.parametrize(
    "message",
    [
        "Make CLAUDE.md a symlink to AGENTS.md\n\nIssue #16",
        "Scan with llm-guard before release\n\nIssue #3",
    ],
)
def test_check_commit_message_allows_product_names(message: str) -> None:
    result = run_hook(CHECK_COMMIT, commit_payload(message))
    assert result.returncode == 0, result.stderr


def test_check_commit_message_warns_without_issue_link() -> None:
    result = run_hook(CHECK_COMMIT, commit_payload("Fix the retry loop"))
    assert result.returncode == 0, result.stderr
    assert "No issue link" in result.stderr


# Far more lines after the first match than a pipe buffer holds, so a writer
# piped into grep -q or head is still writing when the reader exits (#34).
FILLER = "".join(f"filler line {i}\n" for i in range(200_000))


def test_check_commit_message_reads_the_commit_heredoc_of_a_long_command() -> None:
    # Every later `<<` is another delimiter match; the commit's comes first.
    command = (
        "git commit -F - <<'MSG'\nFix the retry loop\n\nGenerated with Claude Code\nMSG\n"
        + "".join(f"cat <<D{i}\n" for i in range(100_000))
    )
    result = run_hook(CHECK_COMMIT, {"tool_name": "Bash", "tool_input": {"command": command}})
    assert result.returncode == 2, result.stderr[-500:]
    assert 'AI/Claude reference: "Claude Code"' in result.stderr


def test_check_commit_message_reads_a_long_option_of_a_long_command() -> None:
    command = 'git commit --message="Generated with Claude Code"' + " --message=x" * 100_000
    result = run_hook(CHECK_COMMIT, {"tool_name": "Bash", "tool_input": {"command": command}})
    assert result.returncode == 2, result.stderr[-500:]
    assert 'AI/Claude reference: "Claude Code"' in result.stderr


@pytest.mark.parametrize(
    "message",
    [
        "Fix the retry loop\n\nGenerated with Claude Code\n" + FILLER,
        "Fix the retry loop\n\nIssue #34\n" + FILLER + "Co-Authored-By: Claude\n",
    ],
    ids=["early-match", "late-match"],
)
def test_attribution_library_blocks_long_message_under_pipefail(
    tmp_path: Path, message: str
) -> None:
    # The library is sourced by enforcement points that set pipefail, so it
    # must not read a match as clean when the message outruns the pipe buffer.
    msg_file = tmp_path / "msg"
    msg_file.write_text(message)
    script = (
        "set -euo pipefail\n"
        'source "$1"\n'
        'if out=$(check_ai_attribution "$(cat "$2")"); then echo CLEAN; else echo "$out"; fi\n'
    )
    result = subprocess.run(
        [BASH, "-c", script, "bash", str(CLAUDE_HOOKS / "lib" / "check-ai-attribution.sh"), str(msg_file)],
        capture_output=True,
        text=True,
        timeout=60,
    )
    assert result.returncode == 0, result.stderr
    assert "BLOCKED: Commit message contains AI/Claude reference" in result.stdout


@pytest.mark.parametrize("present", ["extract_commit_message.py", "check-ai-attribution.sh"])
def test_check_commit_message_refuses_without_its_lib(tmp_path: Path, present: str) -> None:
    # Each of the two lib files on its own, so a missing one is named, not skipped.
    (tmp_path / "lib").mkdir()
    shutil.copy(CHECK_COMMIT, tmp_path / CHECK_COMMIT.name)
    shutil.copy(CLAUDE_HOOKS / "lib" / present, tmp_path / "lib" / present)
    result = run_hook(tmp_path / CHECK_COMMIT.name, commit_payload("Fix the retry loop\n\nIssue #18"))
    assert result.returncode == 2
    assert "refusing to skip the AI-attribution check silently" in result.stderr
    missing = ({"extract_commit_message.py", "check-ai-attribution.sh"} - {present}).pop()
    assert missing in result.stderr


def bash_payload(command: str) -> dict:
    return {"tool_name": "Bash", "tool_input": {"command": command}}


# The shape hooks/README.md walks through: a file written by one heredoc, then
# a commit whose message is another under a different delimiter. As synced on
# 2026-09-10 the hook took the first delimiter, scanned only the file and passed
# the commit (#38). Under one shared delimiter it read both bodies, by accident.
DECOY_HEREDOC = (
    "cat > notes.md <<'EOF'\nfile content\nEOF\n"
    "git commit -F - <<'MSG'\nFix the retry loop\n\nGenerated with Claude Code\nMSG"
)


@pytest.mark.parametrize("hooks_dir", ["repo", "installed"])
def test_check_commit_message_reads_past_a_decoy_heredoc(
    hooks_dir: str, installed_hooks: Path
) -> None:
    script = CHECK_COMMIT if hooks_dir == "repo" else installed_hooks / CHECK_COMMIT.name
    result = run_hook(script, bash_payload(DECOY_HEREDOC))
    assert result.returncode == 2, result.stderr
    assert 'AI/Claude reference: "Claude Code"' in result.stderr


def test_check_commit_message_ignores_a_commit_written_inside_a_heredoc() -> None:
    # Documentation that shows a commit is not a commit; this once blocked a cat.
    command = "cat > HOWTO.md <<'EOF'\nThen run git commit -m 'Generated with Claude Code'\nEOF"
    result = run_hook(CHECK_COMMIT, bash_payload(command))
    assert result.returncode == 0, result.stderr
    assert result.stderr == ""


def test_check_commit_message_allows_a_commit_left_to_the_editor() -> None:
    result = run_hook(CHECK_COMMIT, bash_payload("git add -A && git commit"))
    assert result.returncode == 0, result.stderr
    assert result.stderr == ""


# Commands whose message the 2026-09-10 copy here or the live copy of
# 2026-10-31 did not read, or read wrongly, and so passed; this copy reads
# each (#38). The apostrophe was the old copy's alone.
@pytest.mark.parametrize(
    "command",
    [
        'git stash push -m "wip" && git commit -m "Generated with Claude Code"',
        'git commit -m "Fix the retry loop" -m "Generated with Claude Code"',
        'git add -A && git commit -am "Generated with Claude Code"',
        'git commit -m"Generated with Claude Code"',
        'git commit --message "Generated with Claude Code"',
        'git -C /srv/repo commit -m "Generated with Claude Code"',
        'git -c user.name=x commit -m "Generated with Claude Code"',
        "cat > f <<'EOF' && git commit -m \"Generated with Claude Code\"\nfile body\nEOF",
        'git commit -m "Don\'t retry; Generated with Claude Code"',
    ],
    ids=[
        "earlier-m",
        "second-m",
        "combined-am",
        "attached-m",
        "message-space",
        "global-C",
        "global-c",
        "file-heredoc-on-commit-line",
        "apostrophe",
    ],
)
def test_check_commit_message_blocks_attribution_in_every_message_form(command: str) -> None:
    result = run_hook(CHECK_COMMIT, bash_payload(command))
    assert result.returncode == 2, result.stderr
    assert 'AI/Claude reference: "Claude Code"' in result.stderr


# ─── auto-reanchor.sh (PostCompact) ────────────────────────────────────

AUTO_REANCHOR = CLAUDE_HOOKS / "auto-reanchor.sh"


def test_auto_reanchor_prints_block_on_clean_tree(git_repo: Path) -> None:
    commit_file(git_repo, "a.txt", "a\n")
    result = run_hook(AUTO_REANCHOR, cwd=git_repo)
    assert result.returncode == 0, result.stderr
    assert "--- POST-COMPACTION RE-ANCHOR ---" in result.stderr
    assert "Working tree clean" in result.stderr


def test_auto_reanchor_prints_block_on_very_dirty_tree(git_repo: Path) -> None:
    # Enough untracked files that git status is still writing when the listing
    # is cut to ten lines; the hook must still print its block.
    commit_file(git_repo, "a.txt", "a\n")
    for i in range(20_000):
        (git_repo / f"untracked-{i:05d}.txt").touch()
    result = run_hook(AUTO_REANCHOR, cwd=git_repo)
    assert result.returncode == 0, result.stderr[-500:]
    assert "--- POST-COMPACTION RE-ANCHOR ---" in result.stderr
    assert "Dirty files: ?? untracked-00000.txt" in result.stderr
    assert result.stderr.count("?? untracked-") == 10
    assert "ACTION: Re-read CLAUDE.md" in result.stderr


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


@pytest.mark.parametrize(
    "message, expected",
    [
        ("feat: add x\n\nGenerated with Claude Code\n" + FILLER, 1),
        ("feat: add x\n\nGenerated with Claude Code\nReviewed-by: Human <h@example.com>\n" + FILLER, 0),
    ],
    ids=["unreviewed", "reviewed"],
)
def test_commit_msg_long_body(tmp_path: Path, message: str, expected: int) -> None:
    # The match sits above a body longer than a pipe buffer, so grep -q has
    # its answer while the message is still being written to it.
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


# ─── hooks/git (tiered local enforcement) ──────────────────────────────

TIERED_PRE_COMMIT = REPO_ROOT / "hooks" / "git" / "pre-commit"
TIERED_PRE_PUSH = REPO_ROOT / "hooks" / "git" / "pre-push"
ZERO_SHA = "0" * 40


def stub_tools(tmp_path: Path, tools: dict[str, str]) -> dict[str, str]:
    """Stand-in linters and test runners on PATH, each running the given bash body."""
    bindir = tmp_path / "stubs"
    bindir.mkdir(exist_ok=True)
    for name, body in tools.items():
        stub = bindir / name
        stub.write_text(f"#!/usr/bin/env bash\n{body}\n")
        stub.chmod(0o755)
    return {"PATH": f"{bindir}{os.pathsep}{os.environ['PATH']}"}


def test_tiered_pre_commit_with_nothing_staged(git_repo: Path) -> None:
    result = run_hook(TIERED_PRE_COMMIT, cwd=git_repo)
    assert result.returncode == 0
    assert result.stdout == ""


def test_tiered_pre_commit_skips_docs_only(git_repo: Path, tmp_path: Path) -> None:
    (git_repo / "pyproject.toml").write_text("[project]\nname = 'x'\n")
    stage(git_repo, "notes.md", "prose\n")
    result = run_hook(TIERED_PRE_COMMIT, cwd=git_repo, env=stub_tools(tmp_path, {"ruff": "exit 1"}))
    assert result.returncode == 0, result.stdout
    assert "Docs-only commit" in result.stdout


@pytest.mark.parametrize("ruff_exit, expected", [(0, 0), (1, 1)])
def test_tiered_pre_commit_python_lint(
    git_repo: Path, tmp_path: Path, ruff_exit: int, expected: int
) -> None:
    (git_repo / "pyproject.toml").write_text("[project]\nname = 'x'\n")
    stage(git_repo, "mod.py", "x = 1\n")
    env = stub_tools(tmp_path, {"ruff": f"exit {ruff_exit}", "mypy": "exit 0"})
    result = run_hook(TIERED_PRE_COMMIT, cwd=git_repo, env=env)
    assert result.returncode == expected, result.stdout
    assert ("BLOCKED" in result.stdout) == bool(expected)


def test_tiered_pre_commit_honours_skip_lint(git_repo: Path, tmp_path: Path) -> None:
    (git_repo / "pyproject.toml").write_text("[project]\nname = 'x'\n")
    (git_repo / ".skip-lint").touch()
    stage(git_repo, "mod.py", "x = 1\n")
    env = stub_tools(tmp_path, {"ruff": "exit 1", "mypy": "exit 0"})
    result = run_hook(TIERED_PRE_COMMIT, cwd=git_repo, env=env)
    assert result.returncode == 0, result.stdout
    assert "[skip] Python lint (.skip-lint)" in result.stdout


def python_project(repo: Path) -> None:
    commit_file(repo, "pyproject.toml", "[project]\nname = 'x'\n")


def test_tiered_pre_push_without_a_test_runner(git_repo: Path) -> None:
    commit_file(git_repo, "notes.txt", "prose\n")
    result = run_hook(TIERED_PRE_PUSH, cwd=git_repo)
    assert result.returncode == 0, result.stdout
    assert "No test runner detected" in result.stdout


@pytest.mark.parametrize("uv_exit, expected", [(0, 0), (1, 1)])
def test_tiered_pre_push_unit_tests(
    git_repo: Path, tmp_path: Path, uv_exit: int, expected: int
) -> None:
    python_project(git_repo)
    env = stub_tools(tmp_path, {"uv": f"exit {uv_exit}"})
    result = run_hook(TIERED_PRE_PUSH, cwd=git_repo, env=env)
    assert result.returncode == expected, result.stdout
    assert ("unit tests failed" in result.stdout) == bool(expected)


@pytest.mark.parametrize("marker", [".direct-push-allowed", ".skip-unit-tests"])
def test_tiered_pre_push_opt_outs(git_repo: Path, tmp_path: Path, marker: str) -> None:
    python_project(git_repo)
    (git_repo / marker).touch()
    env = stub_tools(tmp_path, {"uv": "exit 1"})
    result = run_hook(TIERED_PRE_PUSH, cwd=git_repo, env=env)
    assert result.returncode == 0, result.stdout


def test_tiered_pre_push_to_main_without_e2e_warns(git_repo: Path, tmp_path: Path) -> None:
    python_project(git_repo)
    head = git(git_repo, "rev-parse", "HEAD")
    env = stub_tools(tmp_path, {"uv": "exit 0"})
    stdin = f"refs/heads/main {head} refs/heads/main {ZERO_SHA}\n"
    result = run_hook(TIERED_PRE_PUSH, stdin=stdin, cwd=git_repo, env=env)
    assert result.returncode == 0, result.stdout
    assert "Tier 3" in result.stdout
    assert "No e2e tests found" in result.stdout


@pytest.mark.parametrize("remote_ref, expected", [("refs/heads/main", 1), ("refs/heads/feature", 0)])
def test_tiered_pre_push_e2e_gate_only_on_main(
    git_repo: Path, tmp_path: Path, remote_ref: str, expected: int
) -> None:
    python_project(git_repo)
    (git_repo / "tests" / "e2e").mkdir(parents=True)
    head = git(git_repo, "rev-parse", "HEAD")
    # Unit tests pass; only the e2e invocation fails.
    env = stub_tools(tmp_path, {"uv": 'case "$*" in *tests/e2e/*) exit 1 ;; esac\nexit 0'})
    stdin = f"refs/heads/x {head} {remote_ref} {ZERO_SHA}\n"
    result = run_hook(TIERED_PRE_PUSH, stdin=stdin, cwd=git_repo, env=env)
    assert result.returncode == expected, result.stdout
    assert ("e2e tests failed" in result.stdout) == bool(expected)


def test_tiered_pre_push_blocks_tracked_env_file(git_repo: Path) -> None:
    commit_file(git_repo, ".env", "DEBUG=1\n")
    result = run_hook(TIERED_PRE_PUSH, cwd=git_repo)
    assert result.returncode == 1
    assert ".env files are tracked" in result.stdout


def test_tiered_pre_push_blocks_committed_secret(git_repo: Path) -> None:
    commit_file(git_repo, "config.txt", f"aws_access_key_id = {FAKE_AWS_KEY}\n")
    result = run_hook(TIERED_PRE_PUSH, cwd=git_repo)
    assert result.returncode == 1
    assert "potential secret in: config.txt" in result.stdout


def test_tiered_pre_push_blocks_file_with_many_secrets(git_repo: Path) -> None:
    # Far more matches than the five the hook prints, so grep is still writing
    # when the listing is cut; the scan must not read that as a clean file.
    lines = "".join(f"key{i} = {FAKE_AWS_KEY}\n" for i in range(200_000))
    commit_file(git_repo, "keys.txt", lines)
    result = run_hook(TIERED_PRE_PUSH, cwd=git_repo)
    assert result.returncode == 1, result.stdout[-500:]
    assert "potential secret in: keys.txt" in result.stdout
    assert result.stdout.count(FAKE_AWS_KEY) == 5


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
