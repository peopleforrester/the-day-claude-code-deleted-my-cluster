# ABOUTME: Run by tests/test_tmp_paths.py in a child pytest, never collected by the Test command.
# ABOUTME: Prints where the child run's tmp_path sits and what git finds from inside it.

from __future__ import annotations

import subprocess
from pathlib import Path


def test_report_tmp_path(tmp_path: Path) -> None:
    inside = subprocess.run(
        ["git", "-C", str(tmp_path), "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
    )
    print(f"\nPROBE tmp_path={tmp_path}")
    print(f"PROBE git={inside.returncode}")
