# ABOUTME: Asserts the rescued Portland transcript is still the original file, byte for byte, below its marker.
# ABOUTME: The audio is not in this repo, so the committed text is the only copy and must not be tidied.

from __future__ import annotations

import hashlib
from pathlib import Path

TRANSCRIPT = Path("post-event") / "portland-2026-transcript.md"
MARKER = b"<!-- verbatim: original transcript follows, byte for byte -->\n"

# The file as it was routed on 2026-09-10 to walkthrough-agenticburn and
# collected here under issue #25.
ORIGINAL_SIZE = 5984
ORIGINAL_SHA256 = "fc29d0766dc24b51ce0fdef18a7eebff5db58cf9a3a17c3a25d6aacc0d752987"


def _verbatim_part(repo_root: Path) -> bytes:
    data = (repo_root / TRANSCRIPT).read_bytes()
    assert data.count(MARKER) == 1, (
        f"{TRANSCRIPT} must carry the verbatim marker exactly once; "
        "annotations go above it, the original below it."
    )
    return data.split(MARKER, 1)[1]


def test_transcript_below_marker_is_the_original(repo_root: Path) -> None:
    """Everything below the marker is the routed file, unedited."""
    original = _verbatim_part(repo_root)
    assert len(original) == ORIGINAL_SIZE, (
        f"{TRANSCRIPT} below the marker is {len(original)} bytes, not the "
        f"original {ORIGINAL_SIZE}. Annotate above the marker; never correct "
        "the transcript itself."
    )
    assert hashlib.sha256(original).hexdigest() == ORIGINAL_SHA256, (
        f"{TRANSCRIPT} below the marker no longer matches the original file. "
        "Annotate above the marker; never correct the transcript itself."
    )


def test_transcript_names_its_source_and_caveat(repo_root: Path) -> None:
    """The header says where it came from and that it is raw diarization."""
    header = (repo_root / TRANSCRIPT).read_bytes().split(MARKER, 1)[0].decode("utf-8")
    assert "My recording 214.mp3" in header
    assert ORIGINAL_SHA256 in header
    assert "raw diarization" in header.lower()
    assert "speaker labels are approximate" in header.lower()


def test_recording_record_links_the_transcript(repo_root: Path) -> None:
    """The post-event record points readers at the transcript."""
    record = (repo_root / "post-event" / "portland-2026-recording.md").read_text(encoding="utf-8")
    assert "(portland-2026-transcript.md)" in record
