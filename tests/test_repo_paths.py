# ABOUTME: Guards against ~/repos paths that the 2026-09-20/21 tree restructure retired.
# ABOUTME: The old events tree under ~/repos is gone; its repos moved to talks/, portfolio/ and others.

from __future__ import annotations

import subprocess
from pathlib import Path

# Built from parts so this file does not match its own search.
RETIRED_PARENT = "repos/" + "events/"


def test_no_tracked_file_names_the_retired_events_tree(repo_root: Path) -> None:
    """`git grep` for the retired parent finds nothing (issues #10 and #11).

    `~/repos/_archive/events/` is a live path and does not match, because the
    search is for the parent directly under `repos/`.
    """
    result = subprocess.run(
        ["git", "-C", str(repo_root), "grep", "-n", "-F", RETIRED_PARENT],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 1, (
        f"tracked files still name ~/{RETIRED_PARENT}, which no longer exists. "
        f"See issue #11 for where each repo moved:\n{result.stdout}{result.stderr}"
    )
