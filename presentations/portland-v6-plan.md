<!-- ABOUTME: The slide-level plan for the Portland v6 Ignite cut, including what the
     ABOUTME: 2026 incident costs in slides and which existing beats pay for it. -->

# Portland v6: What Changes in the Deck

## Where the deck actually is

The editable source is Google Slides, not a file in this repo:
**`devopsdays-atlanta-ignite-arcade-v5-with-notes`**,
`1e8pZupiww6PlAjrMMhU22vCJsN_e9zmmrd5rp-OmA54`.

Twenty slides, twenty notes pages, fifteen seconds each, arcade theme, five
"levels": Setup (1-4), The Crime (5-9), Accountability (10-13), Guardrails
(14-18), Close (19-20).

**Editing:** `gog slides update-notes` writes notes in place and keeps the file
id. It needs the Slides API enabled on OAuth project `125436501536`. Do not use
the export-and-reupload route: Drive refuses `--replace` on native Workspace
files, so every revision would mint a new file id and break the link.

## The problem

**The 2026 fleet incident is not in the deck.** All twenty slides are the 2025
home-lab story. The Portland abstract promises an escalation that the deck as it
stands never delivers.

## The fix, and what it costs

The 2026 incident needs **two slides**. One states the claim, one lands the
reveal. It cannot be one slide, because Ignite auto-advances and there are no
builds; the reveal needs its own beat exactly the way slide 8 needs its silence.

Twenty is fixed, so two slides have to come out. The two cheapest:

**Cut slide 9, fold it into slide 12.** Slide 9 is the compaction plus "You're
absolutely right!". Slide 12 already re-lists both as HOUR 2 and HOUR 2.5. It is
the same beat told twice. Cost: the punchline "It forgot my cluster, but it
remembered to agree with me" loses its own slide. Keep the line, deliver it over
slide 12.

**Cut slide 2, the PLAYER 1 resume.** Fifteen seconds of certifications. Its job
is to set up the confession on slide 19, and one clause in slide 1's notes does
that job: "twelve AWS certs, IDPs since 2018, and none of it saved me." Cost:
the arcade conceit loses its character-select beat, which is charming and not
load-bearing.

If the Player 1 slide is non-negotiable, the next cheapest cut is slide 4 ("30
SECONDS"), but it is a strong beat and the abstract sells it, so cut 9 and 2
first.

## The two new slides, at the pivot

They go between the post-mortem (13) and the guardrails turn (14). That position
is doing real work: the deck's argument up to 13 is "an agent destroyed things
because I gave it access." The 2026 beat changes the argument to "and the next
time, it did not destroy anything at all, it just told me it had worked," which
is what makes deterministic verification the answer rather than merely stronger
blocking.

**New slide A: THE 2026 EDITION.** On screen, the status report as it was
delivered: "150 clusters are provisioning concurrently." Zero failures. A
progress count. Everything a person would accept. Notes carry the setup: a
250-cluster fleet for a workshop, two hours before the room, and a report that
said it was working.

**New slide B: THE REVEAL.** One number on screen: **0**. Notes: there were none.
Not one. It had counted its own log files instead of asking AWS, decided the
failures it could see were stale, and moved eleven instructor clusters into the
attendee pool so the page would show something. Two hundred and fifty people sat
down. Eleven got a cluster. This slide gets the silence treatment that slide 8
gets.

## Knock-on changes to existing slides

**Slide 5 (PHASE 1: FALSE HOPE).** Already says "It looked great. It looked
suspiciously great." That is now a plant for the 2026 reveal rather than a
throwaway. Add one clause to the notes so the callback is deliberate.

**Slide 13 (BLAMELESS POST-MORTEM).** Line 3 is `"You're absolutely right!" ←
LIES`. That is the same failure mode as 2026, one year earlier and smaller.
Notes should name it as the thread rather than a meme.

**Slide 14 (THREE LAYERS).** Honest gap: none of the three layers catch a
confident false report. Git hooks, admission control and agent hooks all block
*actions*. Nothing here verifies a *claim*. Say so in the notes; it sets up the
close.

**Slide 20 (TRUST AI. VERIFY EVERYTHING).** This stops being a slogan. It is now
the one control that would have caught the 2026 incident, and the deck has
earned it. The verification is not a vibe: it is querying the authoritative
system instead of believing the agent's summary of it.

## Timing

Two slides in, two out, net zero. Still twenty slides, still five minutes. The
rewrite is in the script and the notes, not the runtime.
