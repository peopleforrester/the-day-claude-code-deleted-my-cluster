# ABOUTME: Asserts the delivery-tag table in AGENTS.md is well formed and points at real history.
# ABOUTME: A typo'd commit in that table would send the next organizer to the wrong talk.

from __future__ import annotations

import re
import subprocess
from pathlib import Path

import pytest

TAG_NAME = re.compile(r"delivered/[a-z0-9][a-z0-9.-]*")
ROW = re.compile(
    r"^\| `(?P<tag>[^`]+)` \| `(?P<commit>[0-9a-f]+)` \| (?P<deck>[^|]+) \| (?P<kind>[^|]+) \|$"
)


def delivery_rows(agents_md: str) -> list[dict[str, str]]:
    """The rows of the 'Tags so far' table in AGENTS.md."""
    start = agents_md.index("### Tags so far")
    rows = []
    for line in agents_md[start:].splitlines():
        match = ROW.match(line.strip())
        if match:
            rows.append({k: v.strip() for k, v in match.groupdict().items()})
    return rows


@pytest.fixture(scope="session")
def agents_md(repo_root: Path) -> str:
    return (repo_root / "AGENTS.md").read_text(encoding="utf-8")


@pytest.fixture(scope="session")
def rows(agents_md: str) -> list[dict[str, str]]:
    return delivery_rows(agents_md)


def test_both_retroactive_deliveries_are_listed(rows: list[dict[str, str]]) -> None:
    """Atlanta and Portland, the two Ignite deliveries, each have a row (#9)."""
    tags = {r["tag"] for r in rows}
    assert {"delivered/devopsdays-atlanta-2026", "delivered/devopsdays-portland-2026"} <= tags


def test_sreday_austin_is_listed_on_the_commit_main_held_at_the_slot(
    rows: list[dict[str, str]],
) -> None:
    """SREday Austin, the 30-minute delivery #9 missed, is tagged on aedb2e2 (#30).

    aedb2e2 (17:23 UTC) is the last commit before the 17:30 UTC slot. The deck it
    carries predates corrections visible in the recording, so it is approximate.
    """
    by_tag = {r["tag"]: r for r in rows}
    row = by_tag["delivered/sreday-austin-2026"]
    assert row["commit"] == "aedb2e2"
    assert row["kind"] == "approximate"


def test_tag_names_follow_the_convention(rows: list[dict[str, str]]) -> None:
    """Each tag reads delivered/<event-id>, the pattern check_registry.py accepts."""
    for row in rows:
        assert TAG_NAME.fullmatch(row["tag"]), row["tag"]


def test_each_row_says_exact_or_approximate(rows: list[dict[str, str]]) -> None:
    for row in rows:
        assert row["kind"] in {"exact", "approximate"}, row


def test_each_row_names_a_deck_file_id(rows: list[dict[str, str]]) -> None:
    """The decks are Google Slides, so the file id is what pins the version."""
    for row in rows:
        assert re.search(r"`[A-Za-z0-9_-]{30,}`", row["deck"]), row["deck"]


def test_each_commit_is_in_main_history(rows: list[dict[str, str]], repo_root: Path) -> None:
    """Every listed commit resolves and is an ancestor of HEAD."""
    for row in rows:
        result = subprocess.run(
            ["git", "-C", str(repo_root), "merge-base", "--is-ancestor", row["commit"], "HEAD"],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, f"{row['tag']}: {row['commit']} is not in HEAD's history"
