# ABOUTME: Holds incident/REDACTIONS.md's counts to the <REDACTED-...> markers in the session artifacts.
# ABOUTME: Fails on the credential shapes the first redaction pass missed (#26): client keys, certificate keys, basic auth.

from __future__ import annotations

import re
from pathlib import Path

import pytest

# Each REDACTIONS.md table row, by its opening words, and the markers it counts.
ROW_MARKERS = {
    "Kubernetes service-account JWTs": ("<REDACTED-K8S-SERVICEACCOUNT-JWT>",),
    "kubeadm join tokens": ("<REDACTED-KUBEADM-TOKEN>",),
    "Hardcoded password, token, and secret assignments": (
        "<REDACTED-PASSWORD>",
        "<REDACTED-TOKEN>",
        "<REDACTED-SECRET>",
    ),
    "kubeconfig client private keys": ("<REDACTED-KUBECONFIG-CLIENT-KEY>",),
    "kubeadm certificate keys": ("<REDACTED-KUBEADM-CERTIFICATE-KEY>",),
    "HAProxy stats basic-auth passwords": ("<REDACTED-BASIC-AUTH-PASSWORD>",),
}

# Credential values in the clear, as they appeared before #26.
LEAK_PATTERNS = {
    "kubeconfig client key": re.compile(r"client-key-data:\s*(?!<REDACTED-)\S"),
    "kubeadm certificate key": re.compile(
        r"(certificate[-_]key\W{1,4}|CERT_KEY=\"?|Certificate key:\s*)[0-9a-f]{64}\b", re.I
    ),
    "basic-auth login": re.compile(r"(-u|stats auth)\s+[\w.-]+:(?!<REDACTED-)[^\s$\"']+"),
}


def _artifacts(repo_root: Path) -> list[Path]:
    root = repo_root / "incident" / "session-artifacts"
    files = sorted(p for p in root.rglob("*") if p.is_file())
    assert files, f"no session artifacts found under {root}"
    return files


def _text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def _table(repo_root: Path) -> dict[str, int]:
    text = (repo_root / "incident" / "REDACTIONS.md").read_text(encoding="utf-8")
    rows = {}
    for label, count in re.findall(r"^\| (.+?) \| (\d+) \|$", text, re.M):
        rows[label] = int(count)
    return rows


def test_table_has_a_row_per_category(repo_root: Path) -> None:
    labels = list(_table(repo_root))
    missing = [row for row in ROW_MARKERS if not any(lab.startswith(row) for lab in labels)]
    assert not missing, f"REDACTIONS.md has no row for {missing}"
    assert len(labels) == len(ROW_MARKERS), f"unexpected rows in REDACTIONS.md: {labels}"


@pytest.mark.parametrize("row", ROW_MARKERS)
def test_table_count_matches_markers(repo_root: Path, row: str) -> None:
    table = _table(repo_root)
    stated = next(count for label, count in table.items() if label.startswith(row))
    corpus = [_text(p) for p in _artifacts(repo_root)]
    found = sum(text.count(marker) for text in corpus for marker in ROW_MARKERS[row])
    assert found == stated, f"REDACTIONS.md says {stated} for {row!r}; the tree has {found}"


@pytest.mark.parametrize("kind", LEAK_PATTERNS)
def test_no_unredacted_credential(repo_root: Path, kind: str) -> None:
    pattern = LEAK_PATTERNS[kind]
    hits = []
    for path in _artifacts(repo_root):
        for number, line in enumerate(_text(path).splitlines(), start=1):
            if pattern.search(line):
                hits.append(f"{path.relative_to(repo_root)}:{number}")
    assert not hits, f"unredacted {kind} at {hits}"


@pytest.mark.parametrize(
    ("kind", "line"),
    [
        ("kubeconfig client key", "    client-key-data: LS0tLS1CRUdJTiBSU0Eg"),
        ("kubeadm certificate key", '    "certificate_key": "' + "ab" * 32 + '",'),
        ("kubeadm certificate key", "  --control-plane --certificate-key " + "0f" * 32),
        ("kubeadm certificate key", 'CERT_KEY="' + "12" * 32 + '"'),
        ("kubeadm certificate key", "- Certificate key: " + "cd" * 32),
        ("basic-auth login", 'curl -s -u admin:hunter2 http://$IP:8080/stats'),
        ("basic-auth login", "    stats auth admin:hunter2"),
    ],
)
def test_leak_patterns_catch_the_original_shapes(kind: str, line: str) -> None:
    """Guard against a pattern that silently matches nothing."""
    assert LEAK_PATTERNS[kind].search(line)


@pytest.mark.parametrize(
    ("kind", "line"),
    [
        ("kubeconfig client key", "    client-key-data: <REDACTED-KUBECONFIG-CLIENT-KEY>"),
        ("kubeadm certificate key", "  --certificate-key $CERT_KEY"),
        ("basic-auth login", "curl -u admin:<REDACTED-BASIC-AUTH-PASSWORD> http://x"),
        ("basic-auth login", 'curl -u "$USER:$PASS" http://x'),
    ],
)
def test_leak_patterns_pass_redacted_lines(kind: str, line: str) -> None:
    assert not LEAK_PATTERNS[kind].search(line)
