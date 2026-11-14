# ABOUTME: Asserts the repo has a LICENSE file and the README's License section names the same license.
# ABOUTME: Public talk repos without a license, or with two that disagree, leave reuse rights ambiguous.

from __future__ import annotations

import re
from pathlib import Path

# Each license this check recognises: the pattern that identifies it in a
# LICENSE file's text, and the pattern that names it in prose. Add a row here
# before relicensing, or the check fails because it cannot read the new one.
LICENSES: dict[str, tuple[re.Pattern[str], re.Pattern[str]]] = {
    "CC BY 4.0": (
        re.compile(r"Creative\s+Commons\s+Attribution\s+4\.0\s+International"),
        re.compile(r"\bCC[\s-]BY[\s-]4\.0\b|Creative\s+Commons\s+Attribution\s+4\.0\b"),
    ),
    "MIT": (
        re.compile(r"\bMIT License\b|Permission is hereby granted, free of charge"),
        re.compile(r"\bMIT\b"),
    ),
    "Apache-2.0": (
        re.compile(r"Apache License,?\s+Version 2\.0"),
        re.compile(r"\bApache(?: License)?[\s-](?:Version\s+)?2\.0\b"),
    ),
}


def license_file_names(text: str) -> set[str]:
    """The recognised licenses whose text a LICENSE file carries."""
    return {name for name, (in_file, _) in LICENSES.items() if in_file.search(text)}


def prose_names(text: str) -> set[str]:
    """The recognised licenses a piece of prose names."""
    return {name for name, (_, in_prose) in LICENSES.items() if in_prose.search(text)}


def readme_license_section(readme: str) -> str:
    """The body of the README's `## License` section, up to the next `## ` heading."""
    match = re.search(r"^## License[ \t]*\n(.*?)(?=^## |\Z)", readme, re.MULTILINE | re.DOTALL)
    assert match, "README has no '## License' section."
    return match.group(1)


def test_license_file_present(repo_root: Path) -> None:
    """A LICENSE file must exist at repo root.

    The repo is public; without a license, default copyright applies and
    reuse rights are murky. The senior review flagged this directly.
    """
    license_path = repo_root / "LICENSE"
    assert license_path.is_file(), (
        "LICENSE file missing at repo root. The repo is public, so reuse "
        "rights need to be explicit."
    )
    contents = license_path.read_text(encoding="utf-8")
    assert contents.strip(), "LICENSE file exists but is empty."


def test_readme_references_license(readme: str) -> None:
    """README must mention the license so readers know what applies."""
    lower = readme.lower()
    assert "license" in lower, (
        "README does not mention the license. Add a short License section."
    )


def test_readme_license_section_names_the_license_file(repo_root: Path, readme: str) -> None:
    """The README's License section names the one license LICENSE grants, and no other.

    Until #52 the section said MIT while LICENSE was CC BY 4.0, and the suite
    only checked that the README said "license" somewhere.
    """
    in_file = license_file_names((repo_root / "LICENSE").read_text(encoding="utf-8"))
    assert len(in_file) == 1, (
        f"LICENSE should carry exactly one recognised license, found {sorted(in_file)}. "
        f"If it is a license not in LICENSES, add a row for it in tests/test_license.py."
    )
    in_readme = prose_names(readme_license_section(readme))
    assert in_readme == in_file, (
        f"README's License section names {sorted(in_readme) or 'no recognised license'}, "
        f"but LICENSE is {sorted(in_file)[0]}. Make them agree."
    )


def test_check_tells_the_pre_52_readme_from_the_license_file(repo_root: Path) -> None:
    """The check reads the README text #52 found as MIT, which LICENSE is not."""
    pre_52 = (
        "## License\n\nMIT. See [`LICENSE`](LICENSE). The incident artifacts are "
        "included as evidence for\nthe talk; reuse them freely.\n"
    )
    in_file = license_file_names((repo_root / "LICENSE").read_text(encoding="utf-8"))
    assert prose_names(readme_license_section(pre_52)) == {"MIT"}
    assert prose_names(readme_license_section(pre_52)) != in_file
