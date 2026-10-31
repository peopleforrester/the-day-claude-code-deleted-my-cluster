# ABOUTME: Asserts the talk-repo fleet standard: one rules file, a decision log, and pointers out.
# ABOUTME: talks-knowledge holds the register and abstracts; conference-knowledge holds event state (#16).

from __future__ import annotations

import os
from pathlib import Path


def _section(text: str, heading: str) -> str:
    assert heading in text, f"missing the {heading!r} section"
    return text.split(heading, 1)[1].split("\n## ", 1)[0]


def test_claude_md_is_a_symlink_to_agents_md(repo_root: Path) -> None:
    """One rules file for every agent, so the two cannot drift apart."""
    claude_md = repo_root / "CLAUDE.md"
    assert claude_md.is_symlink(), "CLAUDE.md must be a symlink to AGENTS.md, not a copy"
    assert os.readlink(claude_md) == "AGENTS.md"


def test_decisions_log_exists(repo_root: Path) -> None:
    decisions = (repo_root / "decisions.md").read_text(encoding="utf-8")
    assert "append-only" in decisions.lower().replace("\n", " ")


def test_agents_md_says_where_things_live(repo_root: Path) -> None:
    section = _section(
        (repo_root / "AGENTS.md").read_text(encoding="utf-8"), "## Where things live"
    )
    missing = [
        needle
        for needle in (
            "talks-knowledge",
            "talks/register.md",
            "abstracts",
            "conference-knowledge",
            "events/registry.yaml",
            "decisions.md",
            "PROJECT_STATE.md",
        )
        if needle not in section
    ]
    assert not missing, "AGENTS.md 'Where things live' is missing: " + ", ".join(missing)


def test_readme_states_who_this_repo_is(readme: str) -> None:
    section = _section(readme, "## About this talk")
    missing = [
        label
        for label in (
            "| Speaker |",
            "| Argues |",
            "| Status |",
            "| Built from |",
            "talks-knowledge",
            "conference-knowledge",
        )
        if label not in section
    ]
    assert not missing, "README 'About this talk' is missing: " + ", ".join(missing)
