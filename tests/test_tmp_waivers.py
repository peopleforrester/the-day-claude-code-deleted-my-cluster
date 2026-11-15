# ABOUTME: Holds the tmp-ok waivers on the incident artifacts (#48): 133 lines, each the recovered
# ABOUTME: command with one fixed trailing comment, counted in incident/REDACTIONS.md and pinned by digest.

from __future__ import annotations

import hashlib
import re
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent
ARTIFACTS = REPO_ROOT / "incident" / "session-artifacts"
REDACTIONS = REPO_ROOT / "incident" / "REDACTIONS.md"

WAIVER = "tmp-ok"
SUFFIX = "  # tmp-ok: incident evidence, command kept as recovered"
LINES = 133
FILES = 37
# sha256 over "path:line:text" for every waived line, sorted and newline-joined,
# where text is the line as recovered, before the comment was added.
RECOVERED_SHA256 = "9ad201856a74d36cf95a62bb996d868637dfbf94c07ea1652ee7502883b29245"

SYSTEM_TMP = re.compile(r"(?:/tmp|/var/tmp|/dev/shm)(?:/|\b)")
# What a comment may hold wherever it lands: nothing a shell expands, and no quote
# that would close a string the line sits in.
INERT = re.compile(r"[A-Za-z0-9 ,:#-]+")


def _waived() -> list[tuple[str, int, str]]:
    """Every artifact line carrying the waiver, as (repo-relative path, line number, line)."""
    found = []
    for path in sorted(p for p in ARTIFACTS.rglob("*") if p.is_file()):
        text = path.read_text(encoding="utf-8", errors="replace")
        for number, line in enumerate(text.split("\n"), start=1):
            if WAIVER in line:
                found.append((str(path.relative_to(REPO_ROOT)), number, line))
    return found


WAIVED = _waived()


def test_waiver_count() -> None:
    assert len(WAIVED) == LINES
    assert len({path for path, _, _ in WAIVED}) == FILES


def test_every_waiver_is_the_one_trailing_comment() -> None:
    wrong = [f"{path}:{number}" for path, number, line in WAIVED if not line.endswith(SUFFIX)]
    assert not wrong, f"waiver is not the trailing {SUFFIX.strip()!r} at {wrong}"
    twice = [f"{path}:{number}" for path, number, line in WAIVED if line.count(WAIVER) != 1]
    assert not twice, f"more than one waiver on a line at {twice}"


def test_waiver_comment_is_inert_in_any_shell_context() -> None:
    """Some lines sit inside a quoted string handed to ssh; the comment must stay a comment there."""
    assert INERT.fullmatch(SUFFIX), SUFFIX
    assert SUFFIX.startswith("  # "), "a comment needs whitespace before its #"


def test_waived_lines_are_shell_scripts_naming_a_system_tempdir() -> None:
    """A waiver sits only where the check needs one."""
    for path, number, line in WAIVED:
        assert path.endswith(".sh"), f"{path}:{number} is not in a shell script"
        command = line[: -len(SUFFIX)]
        assert SYSTEM_TMP.search(command), f"{path}:{number} names no system tempdir"
        assert command == command.rstrip() and command.strip(), f"{path}:{number} lost its command"


def test_recovered_text_is_unchanged() -> None:
    """The command on each waived line is byte for byte what was recovered from git history."""
    entries = sorted(f"{path}:{number}:{line[: -len(SUFFIX)]}" for path, number, line in WAIVED)
    digest = hashlib.sha256("\n".join(entries).encode()).hexdigest()
    assert digest == RECOVERED_SHA256, (
        "a waived incident line moved or its command changed; the artifacts are evidence, "
        "so restore the line rather than updating the digest"
    )


def test_redactions_md_records_the_annotation() -> None:
    text = REDACTIONS.read_text(encoding="utf-8")
    stated = re.search(r"\*\*(\d+) lines in (\d+) files\*\*", text)
    assert stated, "REDACTIONS.md does not state how many lines carry the tmp-ok comment"
    assert (int(stated.group(1)), int(stated.group(2))) == (LINES, FILES)
    assert f"`{SUFFIX.strip()}`" in text, "REDACTIONS.md does not quote the comment"
    assert "tests/test_tmp_waivers.py" in text


@pytest.mark.parametrize(
    "line",
    [
        "touch /tmp/needs-reboot  # tmp-ok: fine",
        "touch /tmp/needs-reboot # tmp-ok: incident evidence, command kept as recovered",
        "touch /tmp/needs-reboot  # tmp-ok: incident evidence, command kept as recovered ",
    ],
)
def test_form_check_rejects_other_comments(line: str) -> None:
    """Guard against a form check that accepts anything."""
    assert not line.endswith(SUFFIX)
