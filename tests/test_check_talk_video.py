# ABOUTME: Behavioral tests for scripts/check-talk-video.sh against fake yt-dlp and gog binaries.
# ABOUTME: Pins the three verdicts and the 2026-10-05 false positive on other speakers' Ignites.

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent
SCRIPT = REPO_ROOT / "scripts" / "check-talk-video.sh"
BASH = shutil.which("bash")
assert BASH is not None, "bash is required on PATH to run the script tests"

OURS = (
    "NA|DevOpsDays Portland, 2026: Michael Forrester - Ignite - The Day Claude Code "
    "Deleted My Cluster|https://www.youtube.com/watch?v=rUJ07SnFsXA"
)
# The four entries the old pattern reported as FOUND on 2026-10-05, verbatim from
# the notification mail, before this talk's recording existed.
OTHER_IGNITES = [
    "NA|DevOpsDays Portland, 2026: Bea Hughes - Ignite - Just a jump to the left: "
    "the Time Warp of DevSecOps|https://www.youtube.com/watch?v=_9unCzfnRzg",
    "NA|DevOpsDays Portland, 2026: Daniel Sauble - Ignite - Reproducibility & DX"
    "|https://www.youtube.com/watch?v=swRysz-mkK4",
    "NA|DevOpsDays Portland, 2026: Guinevere Saenger - Ignite - DevOps Is Women’s "
    "Work|https://www.youtube.com/watch?v=HyHW0u2UodU",
    "NA|DevOpsDays Portland, 2026: Brad Winckler - Ignite - Are you ready for "
    "short-lived certificates?|https://www.youtube.com/watch?v=jEzypAwQ3NU",
]
OLD_YEAR = (
    "NA|DevOpsDays Portland, 2021: Noaa Barki,  Shimon Tolts - Ignite - Reading 100+ "
    "Kubernetes Post-Mortems|https://www.youtube.com/watch?v=IPkvK24fraU"
)


@pytest.fixture()
def fake_bin(tmp_path: Path) -> Path:
    """A bin dir with a yt-dlp that prints $FAKE_LISTING and a gog that records calls."""
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    (bin_dir / "yt-dlp").write_text('#!/bin/sh\ncat "$FAKE_LISTING"\n')
    (bin_dir / "gog").write_text('#!/bin/sh\necho "$@" >> "$FAKE_GOG_LOG"\ncat >> "$FAKE_GOG_LOG"\n')
    for tool in ("yt-dlp", "gog"):
        (bin_dir / tool).chmod(0o755)
    return bin_dir


def run_check(
    fake_bin: Path, entries: list[str], *args: str
) -> tuple[subprocess.CompletedProcess[str], Path]:
    listing = fake_bin.parent / "listing.txt"
    listing.write_text("".join(f"{line}\n" for line in entries), encoding="utf-8")
    gog_log = fake_bin.parent / "gog.log"
    result = subprocess.run(
        [BASH, str(SCRIPT), *args],
        capture_output=True,
        text=True,
        env={
            "PATH": f"{fake_bin}:/usr/bin:/bin",
            "FAKE_LISTING": str(listing),
            "FAKE_GOG_LOG": str(gog_log),
        },
        timeout=30,
    )
    return result, gog_log


def test_other_speakers_ignites_are_not_a_hit(fake_bin: Path) -> None:
    """The 2026-10-05 listing must read NOT YET and send no mail."""
    result, gog_log = run_check(fake_bin, [*OTHER_IGNITES, OLD_YEAR], "--notify")
    assert result.returncode == 1, result.stdout + result.stderr
    assert "NOT YET" in result.stdout
    assert not gog_log.exists(), "a mail went out for someone else's Ignite"


def test_this_talk_is_found_and_only_it_is_reported(fake_bin: Path) -> None:
    result, gog_log = run_check(fake_bin, [*OTHER_IGNITES, OURS, OLD_YEAR], "--notify")
    assert result.returncode == 0, result.stdout + result.stderr
    assert "FOUND" in result.stdout
    assert "rUJ07SnFsXA" in result.stdout
    for other in OTHER_IGNITES:
        assert other.rsplit("=", 1)[1] not in result.stdout
    mail = gog_log.read_text(encoding="utf-8")
    assert "rUJ07SnFsXA" in mail
    assert "_9unCzfnRzg" not in mail


def test_found_without_notify_sends_nothing(fake_bin: Path) -> None:
    result, gog_log = run_check(fake_bin, [OURS])
    assert result.returncode == 0, result.stdout + result.stderr
    assert not gog_log.exists()


def test_title_from_another_year_is_not_a_hit(fake_bin: Path) -> None:
    older = OURS.replace("Portland, 2026", "Portland, 2021")
    result, _ = run_check(fake_bin, [older])
    assert result.returncode == 1, result.stdout + result.stderr


def test_empty_listing_is_inconclusive_not_absent(fake_bin: Path) -> None:
    result, gog_log = run_check(fake_bin, [], "--notify")
    assert result.returncode == 2, result.stdout + result.stderr
    assert "INCONCLUSIVE" in result.stdout
    assert not gog_log.exists()
