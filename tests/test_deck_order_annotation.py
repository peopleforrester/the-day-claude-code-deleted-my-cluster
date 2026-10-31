# ABOUTME: Asserts the Portland recording review's real-order annotation agrees with the cue card and the beat table.
# ABOUTME: The v7 file plays JUNIOR DEV nineteenth (#45); the annotation must not drift from what the room heard.
from __future__ import annotations

import re
from pathlib import Path

RECORD = Path("post-event") / "portland-2026-recording.md"
CUE_CARD = Path("presentations") / "CUE-CARD.md"
ANNOTATION = "### Annotation, 2026-10-31: the deck's real slide order"

# The delivered v7 file's slide order, as cue card numbers by position. Read
# from a Drive PPTX export of 1e8pZupiww6PlAjrMMhU22vCJsN_e9zmmrd5rp-OmA54
# (last modified 2026-09-10T16:20:58Z) on 2026-10-31: counter 09/20 is the
# nineteenth slide.
V7_ORDER = [1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 9, 20]


def _rows(text: str) -> list[list[str]]:
    """Body rows of the first markdown table in text, cells stripped."""
    rows: list[list[str]] = []
    started = False
    for line in text.splitlines():
        if line.startswith("|"):
            started = True
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            if not all(set(c) <= set("-: ") for c in cells):
                rows.append(cells)
        elif started:
            break
    return rows[1:]


def _seconds(stamp: str) -> int:
    minutes, seconds = stamp.split(":")
    return int(minutes) * 60 + int(seconds)


def _sections(repo_root: Path) -> tuple[str, str]:
    record = (repo_root / RECORD).read_text(encoding="utf-8")
    assert record.count(ANNOTATION) == 1, f"{RECORD} must carry the real-order annotation once"
    before, after = record.split(ANNOTATION, 1)
    return before.split("### Beats against the cue card", 1)[1], after


def test_annotation_follows_the_v7_order(repo_root: Path) -> None:
    """Each position names the cue card slide the v7 file shows there, in its 15-second window."""
    cue = {int(r[0]): r[1] for r in _rows((repo_root / CUE_CARD).read_text(encoding="utf-8"))}
    rows = _rows(_sections(repo_root)[1])
    assert [int(r[0]) for r in rows] == list(range(1, 21))
    for row, number in zip(rows, V7_ORDER):
        position, window, slide, cue_number = int(row[0]), row[1], row[2], int(row[3])
        assert cue_number == number, f"position {position} is cue card {number} in v7"
        assert slide.replace("*", "") == cue[number].replace("*", ""), (
            f"position {position} names {slide!r}; cue card {number} is {cue[number]!r}"
        )
        start, end = (_seconds(s) for s in window.split(" to "))
        assert (start, end) == ((position - 1) * 15, position * 15)


def test_annotation_quotes_the_beat_table(repo_root: Path) -> None:
    """Heard times are copied from the beat table, and from slide 4 on fall in the real window."""
    beats, annotation = _sections(repo_root)
    heard = {int(r[0]): r[3] for r in _rows(beats)}
    for row in _rows(annotation):
        position, cue_number, at = int(row[0]), int(row[3]), row[4]
        if heard[cue_number]:
            assert at == heard[cue_number], f"cue card {cue_number} was heard at {heard[cue_number]}"
            if position >= 4:
                assert (position - 1) * 15 <= _seconds(at) < position * 15
        else:
            assert not re.match(r"\d+:\d\d$", at), f"cue card {cue_number} has no heard time"
