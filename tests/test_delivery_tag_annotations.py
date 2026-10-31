# ABOUTME: Asserts each committed delivery-tag annotation rebuilds the tag object AGENTS.md says the push must make.
# ABOUTME: #9's tags were lost with the clone that made them; these files let the same tags be made again from the repo.

from __future__ import annotations

import re
import subprocess
from pathlib import Path

import pytest

from tests.test_delivery_tags import delivery_rows

FIELDS = ("Event", "Date", "Deck", "Commit", "Evidence")
# The tagger every tag rebuilt from delivery-tags/ carries (#44), so the object
# made on GitHub by gh api is the one made locally with git tag.
TAGGER = "hecaton <hecaton@localhost> 1793462400 +0000"
TAG_OBJECT = re.compile(r"^- `(?P<tag>delivered/[^`]+)`: tag object `(?P<sha>[0-9a-f]{40})`$")


@pytest.fixture(scope="session")
def agents_md(repo_root: Path) -> str:
    return (repo_root / "AGENTS.md").read_text(encoding="utf-8")


@pytest.fixture(scope="session")
def rows(agents_md: str) -> dict[str, dict[str, str]]:
    return {r["tag"]: r for r in delivery_rows(agents_md)}


@pytest.fixture(scope="session")
def annotations(repo_root: Path) -> dict[str, str]:
    """Each file in delivery-tags/, keyed by the tag it annotates."""
    return {
        f"delivered/{path.stem}": path.read_text(encoding="utf-8")
        for path in sorted((repo_root / "delivery-tags").glob("*.txt"))
    }


@pytest.fixture(scope="session")
def tag_objects(agents_md: str) -> dict[str, str]:
    """The tag object SHA AGENTS.md records for each tag rebuilt from delivery-tags/."""
    start = agents_md.index("### Tags so far")
    return {
        m["tag"]: m["sha"]
        for line in agents_md[start:].splitlines()
        if (m := TAG_OBJECT.match(line.strip()))
    }


def fields(annotation: str) -> dict[str, str]:
    """The Event, Date, Deck, Commit and Evidence lines of an annotation, each exactly once."""
    found: dict[str, list[str]] = {}
    for line in annotation.splitlines():
        name, sep, value = line.partition(": ")
        if sep and name in FIELDS:
            found.setdefault(name, []).append(value)
    for name in FIELDS:
        assert len(found.get(name, [])) == 1, f"{name}: appears {len(found.get(name, []))} times"
    return {name: values[0] for name, values in found.items()}


def full_sha(repo_root: Path, commit: str) -> str:
    return subprocess.run(
        ["git", "-C", str(repo_root), "rev-parse", "--verify", f"{commit}^{{commit}}"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()


def test_the_recreated_tags_have_annotations(annotations: dict[str, str]) -> None:
    """Atlanta and Portland, lost unpushed from #9's clone, are rebuilt from files here (#44)."""
    assert {"delivered/devopsdays-atlanta-2026", "delivered/devopsdays-portland-2026"} <= set(
        annotations
    )


def test_each_annotation_has_a_row_and_a_tag_object(
    annotations: dict[str, str],
    rows: dict[str, dict[str, str]],
    tag_objects: dict[str, str],
) -> None:
    assert set(tag_objects) == set(annotations), "AGENTS.md's tag objects and delivery-tags/ differ"
    for tag in annotations:
        assert tag in rows, f"{tag} has an annotation but no 'Tags so far' row"


def test_each_annotation_agrees_with_its_row(
    annotations: dict[str, str], rows: dict[str, dict[str, str]]
) -> None:
    """The annotation names the row's event id, deck file id, commit and exact or approximate."""
    for tag, annotation in annotations.items():
        row = rows[tag]
        found = fields(annotation)
        event_id = tag.removeprefix("delivered/")
        assert found["Event"].endswith(f"registry id {event_id}"), (tag, found["Event"])
        deck_name, deck_id = re.findall(r"`([^`]+)`", row["deck"])
        assert found["Deck"].startswith(f"{deck_name}, Google Slides {deck_id}, last modified "), (
            tag,
            found["Deck"],
        )
        assert found["Commit"].startswith(f"{row['kind']}. "), (tag, found["Commit"])
        assert row["commit"] in found["Commit"], (tag, found["Commit"])


def test_each_annotation_rebuilds_the_recorded_tag_object(
    annotations: dict[str, str],
    rows: dict[str, dict[str, str]],
    tag_objects: dict[str, str],
    repo_root: Path,
) -> None:
    """The file, the row's commit and the fixed tagger hash to the SHA the push must make.

    The gh api ref call names that SHA, so an annotation edited after the tag
    was made, or a tagger that drifted, fails here and not on GitHub.
    """
    for tag, annotation in annotations.items():
        assert annotation.endswith("\n") and not annotation.endswith("\n\n"), tag
        body = (
            f"object {full_sha(repo_root, rows[tag]['commit'])}\n"
            "type commit\n"
            f"tag {tag}\n"
            f"tagger {TAGGER}\n"
            "\n"
            f"{annotation}"
        )
        sha = subprocess.run(
            ["git", "hash-object", "-t", "tag", "--stdin"],
            input=body,
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        assert sha == tag_objects[tag], f"{tag}: annotation hashes to {sha}, AGENTS.md records {tag_objects[tag]}"
