# ABOUTME: Asserts .gitignore covers the asset types this repo will inevitably hold.
# ABOUTME: Also verifies the PDF-export policy is documented in README.

from __future__ import annotations

import subprocess
from pathlib import Path

import pytest

# Patterns that must be ignored by `.gitignore`. Each entry pairs a sample
# path that would be created in normal operation with the rationale.
DECK_ASSET_SAMPLES: list[tuple[str, str]] = [
    ("_site/index.html", "static-site builds (e.g. reveal-md, marp)"),
    ("dist/index.html", "generic frontend build output"),
    ("build/foo.html", "generic build output"),
    (".reveal-md/cache.json", "reveal-md cache directory"),
    ("presentations/~$slides.pptx", "PowerPoint lock file"),
    ("presentations/~$slides.key", "Keynote lock file"),
    ("presentations/slides.pptx~", "PowerPoint autosave"),
    ("presentations/main.aux", "LaTeX auxiliary"),
    ("presentations/main.log", "LaTeX log"),
    ("presentations/main.toc", "LaTeX table of contents"),
    ("presentations/main.nav", "Beamer nav"),
    ("presentations/main.snm", "Beamer snm"),
    ("presentations/main.out", "LaTeX hyperref out"),
    ("presentations/main.synctex.gz", "LaTeX synctex"),
    ("rehearsal/dryrun.wav", "rehearsal recording"),
    ("rehearsal/dryrun.m4a", "rehearsal recording"),
    ("rehearsal/dryrun.aif", "rehearsal recording"),
    ("rehearsal/dryrun.aiff", "rehearsal recording"),
    ("presentations/slides.pdf", "PDF export of the deck (derived artifact)"),
]


def _git_check_ignore(repo_root: Path, sample_path: str) -> bool:
    """Return True if `sample_path` is ignored by .gitignore.

    Uses `git check-ignore` against a *hypothetical* path — the file does
    not need to exist. Exit code 0 means ignored, 1 means not ignored.
    """
    result = subprocess.run(
        ["git", "-C", str(repo_root), "check-ignore", "--no-index", sample_path],
        capture_output=True,
        text=True,
    )
    return result.returncode == 0


@pytest.mark.parametrize(
    "sample,reason",
    DECK_ASSET_SAMPLES,
    ids=[s for s, _ in DECK_ASSET_SAMPLES],
)
def test_deck_asset_patterns_covered(repo_root: Path, sample: str, reason: str) -> None:
    """Each predictable presentations/talk asset path must be ignored."""
    assert _git_check_ignore(repo_root, sample), (
        f".gitignore does not cover '{sample}' ({reason}). "
        "Add a pattern that catches it."
    )


def test_pdf_export_policy_documented(repo_root: Path) -> None:
    """The PDF-export policy must be documented somewhere durable.

    The senior review flagged that the prior `.gitignore` was ambiguous
    about PDFs. The README used to carry the policy directly but that
    is repo-plumbing; the visitor-facing README is now policy-free and
    the asset policy lives in AGENTS.md (which CLAUDE.md links to)
    alongside other contributor / session instructions. The test follows the policy to its new home.
    """
    claude_md = (repo_root / "AGENTS.md").read_text(encoding="utf-8").lower()
    assert "asset policy" in claude_md or "pdf" in claude_md, (
        "AGENTS.md does not mention PDFs or an 'Asset policy' section. "
        "Document the PDF-export decision so it does not drift."
    )
    assert "derived" in claude_md or "ignored" in claude_md or "not committed" in claude_md, (
        "AGENTS.md mentions PDF but does not state the policy "
        "(derived / ignored / not committed)."
    )
