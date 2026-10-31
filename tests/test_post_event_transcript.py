# ABOUTME: Asserts each rescued Portland transcript is still the original file, byte for byte, below its marker.
# ABOUTME: The audio is not in this repo, so the committed text is the only copy and must not be tidied.

from __future__ import annotations

import hashlib
from dataclasses import dataclass
from pathlib import Path

import pytest

MARKER = b"<!-- verbatim: original transcript follows, byte for byte -->\n"


@dataclass(frozen=True)
class Transcript:
    path: Path
    source: str
    size: int
    sha256: str


TRANSCRIPTS = [
    # The delivery as heard in the room, routed on 2026-09-10 to
    # walkthrough-agenticburn and collected here under issue #25.
    Transcript(
        Path("post-event") / "portland-2026-transcript.md",
        "My recording 214.mp3",
        5984,
        "fc29d0766dc24b51ce0fdef18a7eebff5db58cf9a3a17c3a25d6aacc0d752987",
    ),
    # Run two of the same day's run-throughs, routed on 2026-09-10 to
    # Unleash_an_Agent_Watch_It_Burn and collected here under issue #35.
    Transcript(
        Path("post-event") / "portland-2026-run-two-transcript.md",
        "My recording 212.mp3",
        8254,
        "a25d282d1602ca908e57cc1fac3fa4807cb0ba6058b449253756aad188894574",
    ),
    # Run one, the same day's first run-through and the likelier source of
    # issue #8's 20-of-20 figure, routed on 2026-09-10 to
    # Unleash_an_Agent_Watch_It_Burn and collected here under issue #46.
    Transcript(
        Path("post-event") / "portland-2026-run-one-transcript.md",
        "My recording 211.mp3",
        5237,
        "38cb06d1a414efeef17c7dc2bfd20c767a06bed291f1e103e4937280616826c9",
    ),
]

transcripts = pytest.mark.parametrize("t", TRANSCRIPTS, ids=lambda t: t.path.name)


def _parts(repo_root: Path, t: Transcript) -> tuple[bytes, bytes]:
    data = (repo_root / t.path).read_bytes()
    assert data.count(MARKER) == 1, (
        f"{t.path} must carry the verbatim marker exactly once; "
        "annotations go above it, the original below it."
    )
    header, original = data.split(MARKER, 1)
    return header, original


@transcripts
def test_transcript_below_marker_is_the_original(repo_root: Path, t: Transcript) -> None:
    """Everything below the marker is the routed file, unedited."""
    original = _parts(repo_root, t)[1]
    assert len(original) == t.size, (
        f"{t.path} below the marker is {len(original)} bytes, not the "
        f"original {t.size}. Annotate above the marker; never correct "
        "the transcript itself."
    )
    assert hashlib.sha256(original).hexdigest() == t.sha256, (
        f"{t.path} below the marker no longer matches the original file. "
        "Annotate above the marker; never correct the transcript itself."
    )


@transcripts
def test_transcript_names_its_source_and_caveat(repo_root: Path, t: Transcript) -> None:
    """The header says where it came from and that it is raw diarization."""
    header = _parts(repo_root, t)[0].decode("utf-8")
    assert t.source in header
    assert t.sha256 in header
    assert "raw diarization" in header.lower()
    assert "speaker labels are approximate" in header.lower()


@transcripts
def test_recording_record_links_the_transcript(repo_root: Path, t: Transcript) -> None:
    """The post-event record points readers at the transcript."""
    record = (repo_root / "post-event" / "portland-2026-recording.md").read_text(encoding="utf-8")
    assert f"({t.path.name})" in record
