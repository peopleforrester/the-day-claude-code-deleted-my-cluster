# ABOUTME: Guards against ~/repos paths that the 2026-09-20/21 tree restructure retired.
# ABOUTME: Also pins AGENTS.md's agentic-covenants pointer to its new home under portfolio/.

from __future__ import annotations

import re
import subprocess
from pathlib import Path

# Locations the restructure retired or moved, each directly under ~/repos.
# Built from parts so this file does not match its own search.
RETIRED = tuple(
    "repos/" + rest
    for rest in (
        "events/",
        "mrf/second-brain",
        "workflow/MRF_Obsidian_Repo",
        "games/Lancer-game-ttrpg-mech",
        "certifications/",
    )
)


def test_no_tracked_file_names_a_retired_repos_location(repo_root: Path) -> None:
    """`git grep` for each retired location finds nothing (issues #10, #11 and #12).

    `~/repos/_archive/events/` is a live path and does not match, because the
    search is for the retired parent directly under `repos/`.
    """
    patterns = [arg for path in RETIRED for arg in ("-e", path)]
    result = subprocess.run(
        ["git", "-C", str(repo_root), "grep", "-n", "-F", *patterns],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 1, (
        "tracked files still name ~/repos locations the restructure retired. "
        "Resolve each with `repo-management whereis <term>`:\n"
        f"{result.stdout}{result.stderr}"
    )


# Where agentic-covenants lives since the restructure (`repo-management
# whereis agentic-covenants`), and its GitHub home.
COVENANTS_PATH = "~/repos/portfolio/agentic-covenants"
COVENANTS_URL = "https://github.com/peopleforrester/agentic-covenants"


def _section(text: str, heading: str) -> str:
    """The body of the `## ` section titled `heading`, up to the next `## `."""
    lines = text.splitlines()
    start = lines.index(heading) + 1
    end = next(
        (i for i in range(start, len(lines)) if lines[i].startswith("## ")),
        len(lines),
    )
    return "\n".join(lines[start:end])


def test_agents_md_points_at_agentic_covenants_under_portfolio(
    repo_root: Path,
) -> None:
    """AGENTS.md's framework-evolution section names `~/repos/portfolio/agentic-covenants` (#11, #37).

    Checking only that the retired path is gone would pass any other wrong
    path, so the section must name this one, and no `~/repos` path to
    agentic-covenants anywhere in the file may differ from it.
    """
    text = (repo_root / "AGENTS.md").read_text(encoding="utf-8")
    section = _section(text, "## Framework evolution: `agentic-covenants`")
    assert f"`{COVENANTS_PATH}`" in section, (
        f"AGENTS.md's framework-evolution section does not name {COVENANTS_PATH}:\n"
        f"{section}"
    )
    assert f"<{COVENANTS_URL}>" in section
    named = set(re.findall(r"~/repos/\S*?agentic-covenants", text))
    assert named == {COVENANTS_PATH}, (
        f"AGENTS.md names agentic-covenants at {sorted(named)}, "
        f"not only {COVENANTS_PATH}"
    )
