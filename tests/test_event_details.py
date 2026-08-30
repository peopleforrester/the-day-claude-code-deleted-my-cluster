# ABOUTME: Asserts the README "Given at" table matches the verified delivery record.
# ABOUTME: This repo is multi-event, so the check is per-delivery rather than per-venue.
from __future__ import annotations

# One row per delivery. Each fact must appear somewhere in the README.
# Sources: SREday Austin Q2 page (verified 2026-04-28); the DevOpsDays Atlanta
# repo's own commit history, all dated 2026-04-19 to 04-21; the DevOpsDays
# Portland pretalx schedule export (verified 2026-08-26).
#
# If a delivery moves or a new one is added, update this list and the README
# together. Talk metadata is exactly the kind of thing that drifts when copied
# between repos, which is what this suite exists to catch.
DELIVERIES: list[tuple[str, list[str]]] = [
    ("DevOpsDays Atlanta 2026", ["2026-04-21", "Ignite"]),
    ("SREday Austin Q2 2026", ["2026-05-11", "30 minutes"]),
    ("DevOpsDays Portland 2026", ["2026-09-10", "Ignite"]),
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
