# ABOUTME: The E2E command in AGENTS.md: checks the README's recording links and the video check against live YouTube.
# ABOUTME: Needs the network and the e2e group's yt-dlp; fails, never skips, when either is missing.

from __future__ import annotations

import json
import re
import shutil
import subprocess
import urllib.parse
import urllib.request
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent
SCRIPT = REPO_ROOT / "scripts" / "check-talk-video.sh"
OEMBED = "https://www.youtube.com/oembed?format=json&url="
WATCH_URL = re.compile(r"https://www\.youtube\.com/watch\?v=([A-Za-z0-9_-]{11})")
PORTLAND_ID = "rUJ07SnFsXA"


def given_at_rows() -> list[str]:
    """The delivery rows of README.md's '## Given at' table, the public delivery record."""
    text = (REPO_ROOT / "README.md").read_text(encoding="utf-8")
    start = text.index("## Given at")
    end = text.find("\n## ", start + 1)
    section = text[start : end if end != -1 else len(text)]
    return [line for line in section.splitlines() if line.startswith("| ") and WATCH_URL.search(line)]


def test_every_delivery_links_a_live_recording_of_this_talk() -> None:
    """Each row of the README's delivery table links a recording that resolves on YouTube as this talk."""
    rows = given_at_rows()
    assert len(rows) >= 3, f"README's 'Given at' table links {len(rows)} recordings, expected Atlanta, SREday and Portland"
    for row in rows:
        url = WATCH_URL.search(row).group(0)
        try:
            with urllib.request.urlopen(OEMBED + urllib.parse.quote(url, safe=""), timeout=30) as resp:
                meta = json.load(resp)
        except OSError as exc:
            raise AssertionError(
                f"could not read {url} from YouTube ({exc}). This suite needs the network."
            ) from exc
        assert "deleted my cluster" in meta["title"].lower(), f"{url} is {meta['title']!r}"


def test_video_check_finds_the_portland_recording_on_the_live_channel() -> None:
    """scripts/check-talk-video.sh, unstubbed, reads FOUND for the Portland Ignite only."""
    assert shutil.which("yt-dlp"), (
        "yt-dlp is not on PATH. Run this suite with `uv run --group e2e pytest -q e2e`, "
        "which installs the pinned yt-dlp from the e2e dependency group."
    )
    result = subprocess.run(
        ["bash", str(SCRIPT)], capture_output=True, text=True, timeout=300
    )
    assert result.returncode == 0, result.stdout + result.stderr
    found = result.stdout.split("FOUND:", 1)[1]
    hits = [line for line in found.splitlines() if line.strip()]
    assert len(hits) == 1 and PORTLAND_ID in hits[0], result.stdout
