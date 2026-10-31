# ABOUTME: Asserts the README "Given at" table matches the verified delivery record.
# ABOUTME: This repo is multi-event, so the check is per-delivery rather than per-venue.
from __future__ import annotations

# One row per delivery. Each fact must appear somewhere in the README.
# The source of truth is conference-knowledge events/registry.yaml, ids
# devopsdays-atlanta-2026, sreday-austin-2026 and devopsdays-portland-2026
# (read 2026-10-31, #13), which keeps the speaking record; the README table is
# its public rendering. Original sources: SREday Austin Q2 page (verified
# 2026-04-28); the DevOpsDays Atlanta repo's own commit history, all dated
# 2026-04-19 to 04-21; the DevOpsDays Portland pretalx schedule export
# (verified 2026-08-26). Recordings are YouTube video ids: Atlanta and Portland
# from #8, SREday from the registry, its title checked through YouTube's
# oEmbed endpoint on 2026-10-31.
#
# If a delivery moves or a new one is added, it changes in the registry first;
# update this list and the README together to match. Talk metadata is exactly the kind of thing that drifts when copied
# between repos, which is what this suite exists to catch.
DELIVERIES: list[tuple[str, list[str]]] = [
    ("DevOpsDays Atlanta 2026", ["2026-04-21", "Ignite", "ts0ZnPDrBRI"]),
    ("SREday Austin Q2 2026", ["2026-05-11", "30 minutes", "EoQ-knQKMek"]),
    ("DevOpsDays Portland 2026", ["2026-09-10", "Ignite", "rUJ07SnFsXA"]),
]


def test_readme_lists_every_delivery(readme: str) -> None:
    """Every delivery, and its verified date and format, must appear in the README."""
    lower = readme.lower()
    missing: list[str] = []
    for event, facts in DELIVERIES:
        if event.lower() not in lower:
            missing.append(f"event={event!r}")
        for fact in facts:
            if fact.lower() not in lower:
                missing.append(f"{event}: {fact!r}")
    assert not missing, (
        "README is missing verified delivery facts: " + ", ".join(missing)
    )


def test_readme_has_given_at_section(readme: str) -> None:
    """The deliveries live under an explicit heading, not scattered in prose."""
    assert "## Given at" in readme, (
        "README is missing the '## Given at' section. This repo is named for the "
        "talk rather than an event, so the delivery record is how a reader tells "
        "which version they are looking at."
    )


def test_no_single_event_framing(readme: str) -> None:
    """Guard against the repo drifting back into being one event's repo.

    It was seeded from the SREday repo, whose README opened by naming that one
    conference. If a future edit reintroduces that framing, the multi-event
    premise is broken and the Given at table becomes decoration.
    """
    first_paragraph = readme.split("## ", 1)[0].lower()
    for venue in ("sreday austin", "devopsdays atlanta", "devopsdays portland"):
        assert venue not in first_paragraph, (
            f"README opens by naming {venue!r}. This repo is canonical across "
            "deliveries; individual events belong in the 'Given at' table."
        )


def test_readme_points_at_the_speaking_record(readme: str) -> None:
    """The Given at table names where the record of truth lives.

    conference-knowledge owns event information (#13). Without the pointer a
    reader, or an agent, takes the README table for the record and edits it
    here, which is how the SREday recording sat as "none linked" while the
    registry already had it.
    """
    section = readme.split("## Given at", 1)[1].split("\n## ", 1)[0]
    missing = [
        needle
        for needle in (
            "conference-knowledge",
            "events/registry.yaml",
            "devopsdays-atlanta-2026",
            "sreday-austin-2026",
            "devopsdays-portland-2026",
        )
        if needle not in section
    ]
    assert not missing, (
        "README 'Given at' section does not point at the speaking record in "
        "conference-knowledge; missing: " + ", ".join(missing)
    )
