# ABOUTME: Holds the guardrails kit's clone instructions to this repo, where the fixed templates live.
# ABOUTME: Every /tmp/three-layers/... path the docs name must be a path a clone of this repo holds (#40).

from __future__ import annotations

import re
import subprocess
from fnmatch import fnmatch
from pathlib import Path

import pytest

from tests.conftest import CANONICAL_OWNER_REPO

REPO_ROOT = Path(__file__).resolve().parent.parent
KIT = REPO_ROOT / "guardrails-three-layer"
DOCS = [KIT / "README.md", KIT / "START_HERE.md"]

CLONE_DIR = "/tmp/three-layers"
CLONE_URL = "https://github.com/{}/{}".format(*CANONICAL_OWNER_REPO)
CLONE = re.compile(r"git clone\b[^\n]*")
CLONE_PATH = re.compile(re.escape(CLONE_DIR) + r"(/[^\s`'\")]*)?")

# The archived event repo still holds the templates with mutable tags and
# broad permissions, which #27 fixed here only.
ARCHIVED_REPO = "DevOpsDaysAtlanta_2026_Cluster_Destruction_Ignite"


def _ids(path: Path) -> str:
    return path.name


def _tracked() -> list[str]:
    """Every path git tracks here: what a reader's clone holds, unlike the working tree."""
    result = subprocess.run(
        ["git", "-C", str(REPO_ROOT), "ls-files"],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.splitlines()


TRACKED = _tracked()


@pytest.mark.parametrize("doc", DOCS, ids=_ids)
def test_doc_clones_this_repo_into_the_shared_directory(doc: Path) -> None:
    clones = CLONE.findall(doc.read_text(encoding="utf-8"))
    assert clones, f"{doc.name} has no git clone line"
    for line in clones:
        assert ARCHIVED_REPO not in line, f"{doc.name} clones the archived Atlanta repo: {line}"
        assert CLONE_URL in line.split(), f"{doc.name} does not clone {CLONE_URL}: {line}"
        assert line.split()[-1] == CLONE_DIR, f"{doc.name} does not clone into {CLONE_DIR}: {line}"


@pytest.mark.parametrize("doc", DOCS, ids=_ids)
def test_every_clone_path_resolves_in_this_repo(doc: Path) -> None:
    """A path under the clone names a tracked file or directory, through the kit directory.

    Checked against `git ls-files` rather than the disk, because an ignored
    path exists here and not in a reader's clone: the root `.gitignore` once
    kept `layer-3-claude-hooks/.claude/` out of the repo entirely.
    """
    paths = [m.group(1) or "" for m in CLONE_PATH.finditer(doc.read_text(encoding="utf-8"))]
    under = [p for p in paths if p]
    assert under, f"{doc.name} names no path under {CLONE_DIR}"
    for rel in under:
        assert rel.startswith("/guardrails-three-layer/"), (
            f"{doc.name} names {CLONE_DIR}{rel}, outside the kit directory of this repo"
        )
        target = rel.lstrip("/").rstrip("/")
        held = [t for t in TRACKED if t == target or t.startswith(target + "/") or fnmatch(t, target)]
        assert held, f"{doc.name} names {CLONE_DIR}{rel}, which a clone of this repo does not hold"
