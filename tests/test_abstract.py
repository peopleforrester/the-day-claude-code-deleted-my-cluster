# ABOUTME: Asserts the current abstract, the as-submitted SREday record and the bio live under abstract/.
# ABOUTME: Also enforces the README link and keeps disproven incident claims out of current text.

from __future__ import annotations

from pathlib import Path


# The full talk title as submitted to SREday. If the abstract diverges from
# this verbatim title, the test should catch it — talk metadata is the kind
# of thing that drifts when copied between repos.
SUBMITTED_TITLE = (
    "The Day an AI Agent Deleted My Cluster "
    "(And the Guardrails That Would Have Stopped It)"
)


def test_abstract_dir_exists(repo_root: Path) -> None:
    assert (repo_root / "abstract").is_dir(), (
        "abstract/ directory missing. Capture the as-submitted SREday "
        "abstract and bio there."
    )


def test_abstract_md_has_title_and_format(repo_root: Path) -> None:
    """abstract/abstract.md must carry the talk title, format, duration and level."""
    path = repo_root / "abstract" / "abstract.md"
    assert path.is_file(), f"{path} missing."
    text = path.read_text(encoding="utf-8")

    assert SUBMITTED_TITLE in text, (
        f"abstract.md is missing the verbatim submitted title:\n  {SUBMITTED_TITLE!r}"
    )
    for required in ("Talk", "30 minutes", "Intermediate"):
        assert required in text, (
            f"abstract.md is missing the format field '{required}'."
        )


def test_sreday_as_submitted_record_is_kept(repo_root: Path) -> None:
    """The text SREday accepted stays on file, unrewritten, as the record.

    The current abstract corrects it; the record must still read as it was
    submitted, so it keeps its submission fields and its original wording.
    """
    path = repo_root / "abstract" / "sreday-austin-2026-as-submitted.md"
    assert path.is_file(), f"{path} missing."
    text = path.read_text(encoding="utf-8")

    assert SUBMITTED_TITLE in text, (
        f"{path.name} is missing the verbatim submitted title."
    )
    # The submission form fields are the durable record — keep them visible.
    for required in ("Talk", "30 minutes", "Intermediate", "Accepted"):
        assert required in text, (
            f"{path.name} is missing the submission field '{required}'."
        )
    for original in ("force-overrode etcd", "Forty minutes."):
        assert original in text, (
            f"{path.name} no longer carries the submitted wording {original!r}. "
            "It is a record; correct abstract.md instead."
        )


# Claims about the 2025 incident that the artifacts in incident/ disprove
# (issue #15). The reset log puts the etcd wipe six minutes into the session;
# the command was `kubeadm reset -f`; the transcript no longer exists.
DISPROVEN_CLAIMS = (
    "forty minutes",
    "force-overrode",
    "force-overridden",
    "session transcripts",
    "session jsonl",
)

CURRENT_TEXTS = (
    "abstract/abstract.md",
    "README.md",
    "docs/the-framework.md",
    "guardrails-three-layer/README.md",
    "guardrails-three-layer/layer-3-claude-hooks/CLAUDE.md",
)


def _without_change_table(text: str) -> str:
    """Drop the abstract's change table, which quotes the old wording on purpose."""
    marker = "## What changed from the as-submitted text"
    return text.split(marker, 1)[0]


def test_current_texts_drop_disproven_incident_claims(repo_root: Path) -> None:
    for rel in CURRENT_TEXTS:
        text = _without_change_table(
            (repo_root / rel).read_text(encoding="utf-8")
        ).lower()
        for claim in DISPROVEN_CLAIMS:
            assert claim not in text, (
                f"{rel} still says {claim!r}, which the incident artifacts "
                "disprove. See the change table in abstract/abstract.md."
            )


def test_current_texts_do_not_say_the_agent_ran_force_new_cluster(
    repo_root: Path,
) -> None:
    """The 2025 session ran `kubeadm reset -f`; no artifact shows `--force-new-cluster`."""
    for rel in CURRENT_TEXTS:
        text = " ".join((repo_root / rel).read_text(encoding="utf-8").split())
        for verb in ("executed", "executing", "ran", "running"):
            phrase = f"{verb} `etcd --force-new-cluster`"
            assert phrase not in text, (
                f"{rel} says the agent was {phrase!r}; the artifacts show "
                "`kubeadm reset -f`."
            )


def test_bio_md_has_speaker(repo_root: Path) -> None:
    """abstract/bio.md must identify the speaker."""
    path = repo_root / "abstract" / "bio.md"
    assert path.is_file(), f"{path} missing."
    text = path.read_text(encoding="utf-8")
    assert "Michael" in text and "Forrester" in text, (
        "bio.md is missing the speaker name."
    )


def test_readme_links_to_abstract(readme: str) -> None:
    """The README must link to abstract/abstract.md.

    Once a real submitted abstract is captured, the README should defer to
    it as the canonical source rather than carrying its own paraphrase.
    """
    assert "abstract/abstract.md" in readme, (
        "README does not link to abstract/abstract.md. Replace the "
        "paraphrased Talk Summary with a short intro plus a link to the "
        "as-submitted text."
    )
