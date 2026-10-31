# ABOUTME: Guards against ~/repos paths that the 2026-09-20/21 tree restructure retired.
# ABOUTME: The old events tree under ~/repos is gone; its repos moved to talks/, portfolio/ and others.

from __future__ import annotations

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
