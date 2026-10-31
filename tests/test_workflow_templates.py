# ABOUTME: Holds the guardrails kit's workflow templates and the root workflows/ to SHA-pinned actions and narrow permissions.
# ABOUTME: Readers copy these files into their own repos, so a regression here ships to them (#27, #41).

from __future__ import annotations

import re
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent
TEMPLATE_DIR = REPO_ROOT / "guardrails-three-layer" / "layer-1-git-ci" / ".github" / "workflows"
KIT_TEMPLATES = sorted(TEMPLATE_DIR.glob("*.yml"))
# Not active here, since they sit outside .github/, so no scan of this repo's
# own workflows covers them; workflows/README.md tells readers to copy them.
ROOT_WORKFLOWS = sorted((REPO_ROOT / "workflows").glob("*.yml"))
TEMPLATES = KIT_TEMPLATES + ROOT_WORKFLOWS

USES = re.compile(r"^\s*(?:-\s+)?uses:\s*(\S+)(.*)$")
PINNED = re.compile(r"^[\w.-]+/[\w./-]+@[0-9a-f]{40}$")
VERSION_COMMENT = re.compile(r"^\s+#\s+v?\d+(\.\d+)*$")


def _ids(path: Path) -> str:
    return path.relative_to(REPO_ROOT).as_posix()


def _uses(path: Path) -> list[tuple[int, str, str]]:
    found = []
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        match = USES.match(line)
        if match:
            found.append((number, match.group(1), match.group(2)))
    return found


def _top_level_block(path: Path, key: str) -> list[str]:
    """The indented lines under a top-level key, such as the workflow-level permissions."""
    lines = path.read_text(encoding="utf-8").splitlines()
    block: list[str] = []
    inside = False
    for line in lines:
        if not line.startswith((" ", "\t")) and line.strip():
            inside = line.rstrip() == f"{key}:"
            continue
        if inside and line.strip():
            block.append(line.strip())
    return block


def test_templates_found() -> None:
    """Guard against the glob finding nothing and every check passing vacuously."""
    names = {path.name for path in KIT_TEMPLATES}
    assert {"merge-queue.yml", "policy-check.yml", "pr-validation.yml", "security-scan.yml"} <= names
    assert {path.name for path in ROOT_WORKFLOWS} >= {"ci.yml", "e2e.yml"}


@pytest.mark.parametrize("template", TEMPLATES, ids=_ids)
def test_actions_pinned_by_sha_with_version(template: Path) -> None:
    for number, ref, rest in _uses(template):
        assert PINNED.match(ref), f"{template.name}:{number}: {ref} is not pinned by full commit SHA"
        assert VERSION_COMMENT.match(rest), f"{template.name}:{number}: {ref} has no version comment"


@pytest.mark.parametrize("template", TEMPLATES, ids=_ids)
def test_checkout_drops_credentials(template: Path) -> None:
    lines = template.read_text(encoding="utf-8").splitlines()
    for index, line in enumerate(lines):
        if not re.search(r"uses:\s*actions/checkout@", line):
            continue
        step = []
        for following in lines[index + 1 :]:
            if re.match(r"^\s*-\s", following) or not following.startswith("        "):
                break
            step.append(following.strip())
        assert "persist-credentials: false" in step, (
            f"{template.name}:{index + 1}: actions/checkout keeps its credentials"
        )


@pytest.mark.parametrize("template", TEMPLATES, ids=_ids)
def test_workflow_level_permissions_are_read_only(template: Path) -> None:
    permissions = _top_level_block(template, "permissions")
    assert permissions, f"{template.name} sets no workflow-level permissions"
    writes = [entry for entry in permissions if entry.split(":", 1)[1].split("#")[0].strip() != "read"]
    assert not writes, f"{template.name} grants {writes} to every job; grant them on the job that needs them"


def test_trivy_action_is_the_advisory_safe_release() -> None:
    """GHSA-69fq-xp46-6x23 names 0.35.0 the one trivy-action tag the March 2026 compromise did not rewrite."""
    refs = [ref for template in TEMPLATES for _, ref, _ in _uses(template) if "trivy-action" in ref]
    assert refs == ["aquasecurity/trivy-action@57a97c7e7821a5776cebc9bb87c984fa69cba8f1"]
