# ABOUTME: Checks every SHA-pinned action in the kit templates and root workflows/ is the commit its version comment names on GitHub.
# ABOUTME: Needs the network and git; fails, never skips, without them. A pin to a tag that does not exist fails here (#41).

from __future__ import annotations

import re
import shutil
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
WORKFLOWS = sorted(
    [
        *(REPO_ROOT / "guardrails-three-layer" / "layer-1-git-ci" / ".github" / "workflows").glob("*.yml"),
        *(REPO_ROOT / "workflows").glob("*.yml"),
    ]
)
PIN = re.compile(r"^\s*(?:-\s+)?uses:\s*([\w.-]+/[\w.-]+)[\w./-]*@([0-9a-f]{40})\s+#\s+(\S+)\s*$")


def pins() -> set[tuple[str, str, str]]:
    """(owner/repo, pinned SHA, version comment) for every pinned action in the copied workflows."""
    found = set()
    for path in WORKFLOWS:
        for line in path.read_text(encoding="utf-8").splitlines():
            if match := PIN.match(line):
                found.add(match.groups())
    return found


def tag_commit(repo: str, tag: str) -> str | None:
    """The commit a tag points at on GitHub, peeling an annotated tag; None when the tag does not exist."""
    result = subprocess.run(
        ["git", "ls-remote", "--tags", f"https://github.com/{repo}", f"refs/tags/{tag}", f"refs/tags/{tag}^{{}}"],
        capture_output=True,
        text=True,
        timeout=60,
    )
    assert result.returncode == 0, (
        f"git ls-remote could not read github.com/{repo}: {result.stderr.strip()}. This suite needs the network."
    )
    refs = dict(reversed(line.split("\t")) for line in result.stdout.splitlines())
    return refs.get(f"refs/tags/{tag}^{{}}") or refs.get(f"refs/tags/{tag}")


def test_workflows_found() -> None:
    names = {path.name for path in WORKFLOWS}
    assert {"ci.yml", "e2e.yml", "security-scan.yml"} <= names, names
    assert len(pins()) >= 9, "fewer pins than the kit and root workflows hold; the pattern no longer matches them"


def test_every_pin_is_the_commit_its_version_tag_names() -> None:
    assert shutil.which("git"), "git is not on PATH; this suite needs it to read the action repos' tags"
    wrong = []
    for repo, sha, version in sorted(pins()):
        commit = tag_commit(repo, version)
        if commit != sha:
            wrong.append(f"{repo}@{sha} # {version}: tag {version} is {commit or 'missing'}")
    assert not wrong, "pins that do not match their version tag on GitHub:\n" + "\n".join(wrong)
