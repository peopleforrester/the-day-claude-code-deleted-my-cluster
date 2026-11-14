# ABOUTME: Asserts LICENSE (CC BY 4.0, content) and LICENSE-CODE (MIT, code) agree with the README's License section.
# ABOUTME: Public talk repos without a license, or with two that disagree, leave reuse rights ambiguous.

from __future__ import annotations

import re
import subprocess
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


# Each license file at the repo root, with the license it must carry. LICENSE
# covers the talk content and LICENSE-CODE the code (#54).
LICENSE_FILES: dict[str, str] = {
    "LICENSE": "CC BY 4.0",
    "LICENSE-CODE": "MIT",
}

# A code path as the README's License section lists it, `- [`hooks/`](hooks/)`,
# and as LICENSE lists it, an indented `hooks/` on a line of its own.
README_CODE_PATH = re.compile(r"^- \[`([^`]+/)`\]\(\1\)\s*$", re.MULTILINE)
LICENSE_CODE_PATH = re.compile(r"^[ \t]+([A-Za-z0-9._-]+/)[ \t]*$", re.MULTILINE)


def readme_code_paths(readme: str) -> list[str]:
    """The paths the README's License section says LICENSE-CODE covers."""
    return README_CODE_PATH.findall(readme_license_section(readme))


def test_each_license_file_carries_its_license(repo_root: Path) -> None:
    """LICENSE carries CC BY 4.0 alone and LICENSE-CODE carries MIT alone."""
    for file_name, expected in LICENSE_FILES.items():
        path = repo_root / file_name
        assert path.is_file(), f"{file_name} missing at repo root."
        found = license_file_names(path.read_text(encoding="utf-8"))
        assert found == {expected}, (
            f"{file_name} should carry {expected} and nothing else, found "
            f"{sorted(found) or 'no recognised license'}. If it is a license not "
            f"in LICENSES, add a row for it in tests/test_license.py."
        )


def test_readme_license_section_names_the_license_files(readme: str) -> None:
    """The README's License section names the licenses the two files grant, and no other.

    Until #52 the section said MIT while LICENSE was CC BY 4.0, and the suite
    only checked that the README said "license" somewhere. Since #54 MIT is
    right, for the code, so the section must name both and link both files.
    """
    section = readme_license_section(readme)
    in_readme = prose_names(section)
    granted = set(LICENSE_FILES.values())
    assert in_readme == granted, (
        f"README's License section names {sorted(in_readme) or 'no recognised license'}, "
        f"but the license files grant {sorted(granted)}. Make them agree."
    )
    for file_name in LICENSE_FILES:
        assert f"]({file_name})" in section, (
            f"README's License section does not link {file_name}."
        )


def test_readme_and_license_list_the_same_code_paths(repo_root: Path, readme: str) -> None:
    """The paths the README puts under LICENSE-CODE are the ones LICENSE carves out.

    LICENSE says the code is licensed separately and lists where it is; the
    README says the same. If one gains or loses a path the other did not, the
    two files grant different terms for it.
    """
    in_readme = readme_code_paths(readme)
    assert in_readme, "README's License section lists no code paths for LICENSE-CODE."
    assert len(in_readme) == len(set(in_readme)), f"README lists a code path twice: {in_readme}."
    in_license = LICENSE_CODE_PATH.findall((repo_root / "LICENSE").read_text(encoding="utf-8"))
    assert sorted(in_readme) == sorted(in_license), (
        f"README puts {sorted(in_readme)} under LICENSE-CODE, but LICENSE carves out "
        f"{sorted(in_license)}. Make them agree."
    )


def test_code_paths_exist_and_hold_every_executable(repo_root: Path, readme: str) -> None:
    """Each code path exists, and every executable outside incident/ is under one.

    An executable is code by any reading. One that lands outside the listed
    paths would fall under CC BY 4.0 by default; the incident forensics are
    the exception, since what was recovered there is evidence, not code to run.
    """
    paths = readme_code_paths(readme)
    for path in paths:
        assert (repo_root / path).is_dir(), f"README lists code path {path}, which is not a directory."
    listing = subprocess.run(
        ["git", "-C", str(repo_root), "ls-files", "-s"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    executables = [
        line.split("\t", 1)[1]
        for line in listing.splitlines()
        if line.startswith("100755 ")
    ]
    assert executables, "git ls-files reports no executable files; the check read nothing."
    stray = [
        name
        for name in executables
        if not name.startswith("incident/") and not any(name.startswith(p) for p in paths)
    ]
    assert not stray, (
        f"Executables outside the code paths LICENSE-CODE covers: {stray}. Move them "
        f"under one, or add their path to the README's License section and to LICENSE."
    )


def test_check_tells_the_pre_52_readme_from_the_license_files(repo_root: Path) -> None:
    """The check reads the README text #52 found as MIT alone, which is not both licenses."""
    pre_52 = (
        "## License\n\nMIT. See [`LICENSE`](LICENSE). The incident artifacts are "
        "included as evidence for\nthe talk; reuse them freely.\n"
    )
    assert prose_names(readme_license_section(pre_52)) == {"MIT"}
    assert prose_names(readme_license_section(pre_52)) != set(LICENSE_FILES.values())
    assert readme_code_paths(pre_52) == []
