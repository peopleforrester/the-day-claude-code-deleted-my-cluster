# ABOUTME: Checks the published commit-message extractor is the live llm-coding-workflow helper apart from its header comment.
# ABOUTME: Needs gh with read access to the private llm-coding-workflow repo; fails, never skips, without it (#51).

from __future__ import annotations

import re
import shutil
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
PUBLISHED = REPO_ROOT / "hooks" / "claude-code" / "lib" / "extract_commit_message.py"
WORKFLOW_REPO = "peopleforrester/llm-coding-workflow"
LIVE_PATH = "scripts/git-hooks/lib/extract_commit_message.py"
# The workflow repo's leading branch: its gate fast-forwards main to staging,
# so a helper change is on staging first. On 2026-11-13 staging held the
# helper at e400946 and main was still on the line-based one (#50).
LIVE_REF = "staging"
SYNC_LINE = re.compile(rf"^# Synced from llm-coding-workflow {re.escape(LIVE_PATH)}$")
SYNC_COMMIT = re.compile(r"^# at ([0-9a-f]{7,40}) ")


def split_header(text: str) -> tuple[list[str], str]:
    """The comment lines above the module docstring, and the file from the docstring on."""
    lines = text.splitlines(keepends=True)
    for index, line in enumerate(lines):
        if line.startswith('"""'):
            return lines[:index], "".join(lines[index:])
    raise AssertionError("no module docstring opens a line; the header cannot be told from the body")


def live_file(ref: str) -> str:
    """The workflow repo's helper at a ref, read raw through gh."""
    assert shutil.which("gh"), f"gh is not on PATH; this suite reads {WORKFLOW_REPO} through it."
    result = subprocess.run(
        [
            "gh",
            "api",
            "-H",
            "Accept: application/vnd.github.raw",
            f"repos/{WORKFLOW_REPO}/contents/{LIVE_PATH}?ref={ref}",
        ],
        capture_output=True,
        text=True,
        timeout=60,
    )
    assert result.returncode == 0, (
        f"gh could not read {LIVE_PATH} at {ref} in {WORKFLOW_REPO}: "
        f"{result.stderr.strip() or result.stdout.strip()}. "
        f"This suite needs the network and gh signed in with read access to {WORKFLOW_REPO}, which is private."
    )
    return result.stdout


def published() -> tuple[list[str], str]:
    return split_header(PUBLISHED.read_text(encoding="utf-8"))


def assert_matches(live: str, where: str) -> None:
    header, body = published()
    live_header, live_body = split_header(live)
    assert body == live_body, (
        f"{PUBLISHED.relative_to(REPO_ROOT)} differs from {where} below its header comment; "
        "resync it and move the header's sync commit"
    )
    assert header[: len(live_header)] == live_header, (
        f"the published header does not start with {where}'s header lines"
    )
    added = header[len(live_header) :]
    assert added and all(line.startswith("#") for line in added), (
        f"the lines the published header adds to {where}'s are not all comments: {added!r}"
    )


def sync_commit() -> str:
    """The workflow commit the published header says the file was synced at."""
    header, _ = published()
    stripped = [line.rstrip("\n") for line in header]
    starts = [i for i, line in enumerate(stripped) if SYNC_LINE.match(line)]
    assert len(starts) == 1, f"the header names its source path {len(starts)} times, expected once"
    match = SYNC_COMMIT.match(stripped[starts[0] + 1])
    assert match, f"the line after the sync line does not name a commit: {stripped[starts[0] + 1]!r}"
    return match.group(1)


def test_split_header_finds_the_docstring() -> None:
    header, body = published()
    assert header[0] == "#!/usr/bin/env python3\n"
    assert body.startswith('"""Pull the commit message out of a shell command string.')


def test_published_helper_is_the_live_one_apart_from_its_header() -> None:
    """Fails as soon as the live helper moves on and this copy is not resynced (#50, #51)."""
    assert_matches(live_file(LIVE_REF), f"{WORKFLOW_REPO} {LIVE_PATH} on {LIVE_REF}")


def test_published_helper_is_the_file_at_the_commit_its_header_names() -> None:
    """The header's sync commit is the one the body came from, so the header cannot go stale alone."""
    commit = sync_commit()
    assert_matches(live_file(commit), f"{WORKFLOW_REPO} {LIVE_PATH} at {commit}")
