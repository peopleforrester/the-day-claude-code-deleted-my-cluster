# ABOUTME: Holds the post-talk article to the constraints of issue #5: quotes match the record,
# ABOUTME: the 250 are never said to be deleted outside the quoted abstract, no dashes, US spelling.

from __future__ import annotations

import re
from pathlib import Path

import pytest

ARTICLE_DIR = Path("post-event") / "the-guardrails-did-not-cover-it"
ARTICLE_FILES = ("blog.md", "social.md", "quotes.md")

# Quotes that do not come from the 2026 session record, each with its source.
# Anything quoted in the article and not listed here must appear verbatim in
# incident/2026-FLEET-INCIDENT.md.
EXTERNAL_QUOTES = frozenset({
    # The submitted DevOpsDays Portland text, recorded verbatim in
    # peopleforrester/2026-portland-devopsdays, abstracts/ignite-deleted-my-cluster.md,
    # and live on talks.devopsdays.org as of 2026-10-31.
    "Then came the 2026 edition, when it deleted 250 clusters.",
    "This time it wasn't one cluster, it was 250, gone.",
    "250, gone",
    # peopleforrester/agentic-covenants README, "Scope: what this framework
    # covers, and what it does not".
    "output that is confidently wrong rather than unauthorized",
})

# Quoted lines from the article itself, used verbatim in quotes.md.
SELF_QUOTES_FILE = "quotes.md"

BRITISH_SPELLINGS = re.compile(
    r"\b(programme|organis\w*|prioritis\w*|recognis\w*|behaviour\w*|centre|licence"
    r"|whilst|amongst|utilis\w*|customis\w*|analys(e|ed|es|ing)|defence|favour\w*"
    r"|colour\w*|labour\w*|modelling|travelling|cancelled|catalogue|initialis\w*"
    r"|parallelis\w*|grey)\b",
    re.IGNORECASE,
)
DELETED = re.compile(r"\b(delet|destroy|wip(e|ed|ing) out)\w*", re.IGNORECASE)
QUOTED = re.compile(r'"([^"\n]+)"')


def _normalize(text: str) -> str:
    """Drop bold markers and blockquote prefixes, then collapse whitespace."""
    unquoted = re.sub(r"(?m)^\s*>\s?", "", text)
    return " ".join(unquoted.replace("**", "").split())


def _quotes(text: str) -> list[str]:
    return [q.strip().rstrip(".,") for q in QUOTED.findall(text)]


@pytest.fixture(scope="module")
def incident(repo_root: Path) -> str:
    return _normalize(
        (repo_root / "incident" / "2026-FLEET-INCIDENT.md").read_text(encoding="utf-8")
    )


@pytest.mark.parametrize("name", ARTICLE_FILES)
def test_article_file_exists(repo_root: Path, name: str) -> None:
    assert (repo_root / ARTICLE_DIR / name).is_file(), f"{ARTICLE_DIR / name} missing."


@pytest.mark.parametrize("name", ARTICLE_FILES)
def test_no_em_or_en_dashes(repo_root: Path, name: str) -> None:
    text = (repo_root / ARTICLE_DIR / name).read_text(encoding="utf-8")
    assert "—" not in text and "–" not in text, (
        f"{name} contains an em-dash or en-dash; the prose gate forbids both."
    )


@pytest.mark.parametrize("name", ARTICLE_FILES)
def test_250_never_said_deleted_outside_the_quoted_abstract(
    repo_root: Path, name: str
) -> None:
    """The 250 were never created. Only the quoted abstract may say otherwise."""
    lines = (repo_root / ARTICLE_DIR / name).read_text(encoding="utf-8").splitlines()
    offending = [
        sentence
        for line in lines
        if not line.lstrip().startswith(">")
        for sentence in re.split(r"(?<=[.!?])\s+", line)
        if "250" in sentence and DELETED.search(sentence)
    ]
    assert not offending, (
        f"{name} says the 250 were deleted or destroyed outside a blockquote of the "
        f"abstract being corrected: {offending}"
    )


@pytest.mark.parametrize("name", ARTICLE_FILES)
def test_american_spelling(repo_root: Path, name: str) -> None:
    text = (repo_root / ARTICLE_DIR / name).read_text(encoding="utf-8")
    found = sorted({m.group(0) for m in BRITISH_SPELLINGS.finditer(text)})
    assert not found, f"{name} uses British spellings: {found}"


@pytest.mark.parametrize("name", ARTICLE_FILES)
def test_every_quote_traces_to_its_source(
    repo_root: Path, incident: str, name: str
) -> None:
    """Every quoted string matches the session record, or a listed external source."""
    text = (repo_root / ARTICLE_DIR / name).read_text(encoding="utf-8")
    blog = _normalize((repo_root / ARTICLE_DIR / "blog.md").read_text(encoding="utf-8"))
    untraced = []
    for quote in _quotes(text):
        normalized = _normalize(quote)
        if normalized in incident or quote in {q.rstrip(".,") for q in EXTERNAL_QUOTES}:
            continue
        if name == SELF_QUOTES_FILE and normalized in blog:
            continue
        untraced.append(quote)
    assert not untraced, (
        f"{name} quotes text found in neither incident/2026-FLEET-INCIDENT.md nor "
        f"EXTERNAL_QUOTES: {untraced}"
    )


def test_deleted_check_reads_sentences_not_lines() -> None:
    """A sentence that says the 250 were deleted is caught even mid-paragraph."""
    line = "It was a long night. The agent deleted 250 clusters."
    sentences = re.split(r"(?<=[.!?])\s+", line)
    assert any("250" in s and DELETED.search(s) for s in sentences)


def test_quote_extraction_catches_a_paraphrase(incident: str) -> None:
    """A paraphrased agent quote must not pass as a match for the record."""
    paraphrase = "Confirmed clean: current run has 0 failures. The fix works"
    assert _normalize(paraphrase) not in incident


# Issue #36: the article links both Ignite recordings. The IDs are the ones
# the README's "Given at" table pins in tests/test_event_details.py.
PORTLAND_RECORDING = "https://www.youtube.com/watch?v=rUJ07SnFsXA"
ATLANTA_RECORDING = "https://www.youtube.com/watch?v=ts0ZnPDrBRI"
ABSTRACT_QUOTES = ("deleted 250 clusters", "250, gone")


def _paragraphs(text: str) -> list[str]:
    """Published paragraphs: the ABOUTME header comment is not article text."""
    prose = re.sub(r"<!--.*?-->", "", text, flags=re.DOTALL)
    return [p for p in re.split(r"\n\s*\n", prose) if p.strip()]


def test_blog_links_both_recordings(repo_root: Path) -> None:
    text = (repo_root / ARTICLE_DIR / "blog.md").read_text(encoding="utf-8")
    assert PORTLAND_RECORDING in text, "blog.md does not link the Portland Ignite recording."
    assert ATLANTA_RECORDING in text, "blog.md does not link the Atlanta Ignite recording."


def test_social_variant_naming_the_talk_links_the_portland_recording(
    repo_root: Path,
) -> None:
    """The longest variant, the one about the Portland talk, links its recording.

    The abstract-correction variant does not: it quotes the wording the video's
    description repeats, and test_recording_description_is_not_quoted keeps the
    two apart.
    """
    text = (repo_root / ARTICLE_DIR / "social.md").read_text(encoding="utf-8")
    body = text.split("# Social variants", 1)[1]
    variants = [v.strip() for v in body.split("\n---\n")]
    longest = max(variants, key=lambda v: len(v.replace(PORTLAND_RECORDING, "")))
    assert "DevOpsDays Portland" in longest and PORTLAND_RECORDING in longest, (
        f"social.md's longest variant does not link the Portland recording: {longest[:60]}"
    )


@pytest.mark.parametrize("name", ARTICLE_FILES)
def test_recording_description_is_not_quoted(repo_root: Path, name: str) -> None:
    """The video's description is the uncorrected abstract: link it, never quote it.

    A paragraph that links a recording or mentions its description quotes none of
    the abstract's wording, and one that mentions the description says the 250
    were never created.
    """
    text = (repo_root / ARTICLE_DIR / name).read_text(encoding="utf-8")
    for paragraph in _paragraphs(text):
        flat = " ".join(paragraph.split())
        mentions_description = re.search(r"\bdescription\b", flat, re.IGNORECASE)
        links_recording = PORTLAND_RECORDING in flat or ATLANTA_RECORDING in flat
        if not (mentions_description or links_recording):
            continue
        quoted = [q for q in _quotes(flat) if any(a in q for a in ABSTRACT_QUOTES)]
        assert not quoted, f"{name} quotes the recording's description: {quoted}"
        if mentions_description:
            assert "never created" in flat, (
                f"{name} mentions the recording's description without saying the "
                f"250 were never created: {flat[:80]}"
            )
