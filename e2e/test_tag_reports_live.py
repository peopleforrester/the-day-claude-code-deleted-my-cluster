# ABOUTME: Checks each delivery tag in AGENTS.md was reported on the live conference-knowledge issue its row names.
# ABOUTME: Needs gh with read access to the private conference-knowledge repo; fails, never skips, without it.

from __future__ import annotations

import json
import re
import shutil
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
ROW = re.compile(
    r"^\| `(?P<tag>delivered/[^`]+)` \|.*\| `(?P<repo>[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)#(?P<number>[0-9]+)` \|$"
)


def reported_tags() -> list[dict[str, str]]:
    """Tag, issue repo and issue number for each row of AGENTS.md's 'Tags so far' table."""
    text = (REPO_ROOT / "AGENTS.md").read_text(encoding="utf-8")
    start = text.index("### Tags so far")
    return [m.groupdict() for line in text[start:].splitlines() if (m := ROW.match(line.strip()))]


def issue_text(repo: str, number: str) -> str:
    """The body and every comment of a GitHub issue, read through gh."""
    result = subprocess.run(
        ["gh", "issue", "view", number, "-R", repo, "--json", "body,comments"],
        capture_output=True,
        text=True,
        timeout=60,
    )
    assert result.returncode == 0, (
        f"gh could not read {repo}#{number}: {result.stderr.strip() or result.stdout.strip()}. "
        f"This suite needs the network and gh signed in with read access to {repo}."
    )
    issue = json.loads(result.stdout)
    return "\n".join([issue["body"], *(c["body"] for c in issue["comments"])])


def test_every_delivery_tag_is_named_on_its_conference_knowledge_issue() -> None:
    """The issue each row cites asks for that tag, under its event id, to be recorded (#9, #32).

    conference-management records delivered_tag from that request, so a row
    citing an issue that never mentions the tag has not been reported.
    """
    assert shutil.which("gh"), "gh is not on PATH; this suite reads conference-knowledge issues through it."
    rows = reported_tags()
    assert len(rows) >= 3, f"AGENTS.md's 'Tags so far' lists {len(rows)} reported tags, expected Atlanta, Portland and SREday Austin"
    texts: dict[tuple[str, str], str] = {}
    for row in rows:
        assert row["repo"] == "peopleforrester/conference-knowledge", row
        key = (row["repo"], row["number"])
        if key not in texts:
            texts[key] = issue_text(*key)
        event_id = row["tag"].removeprefix("delivered/")
        text = texts[key]
        where = f"{row['repo']}#{row['number']}"
        assert row["tag"] in text, f"{where} never names {row['tag']}"
        assert re.search(rf"(?<![\w/-]){re.escape(event_id)}(?![\w-])", text), (
            f"{where} never names the event id {event_id}"
        )
