<!-- ABOUTME: The slide-level plan for the Portland v6 Ignite cut, including what the
     ABOUTME: 2026 incident costs in slides and which existing beats pay for it. -->

# Portland v6: What Changes in the Deck

## Where the deck actually is

The editable source is Google Slides, not a file in this repo:
**`devopsdays-portland-ignite-arcade-v6-with-notes`**,
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

## Applied to the live deck, 2026-09-02

Notes rewritten in place on `1e8pZupiww6PlAjrMMhU22vCJsN_e9zmmrd5rp-OmA54` via
`gog slides update-notes`. The file id and link are unchanged.

| Slide | Object | What the note now does |
|---|---|---|
| 5 | `p5` | Marks "suspiciously great" as a deliberate plant for the 2026 reveal |
| 13 | `p13` | Points at "You're absolutely right" as the thread, not a meme |
| 14 | `p14` | Names the gap: all three layers block actions, none verify a claim |
| 20 | `p20` | Turns "Verify everything" into the control that catches a confident lie |

The pre-rebuild v5 survives as `devopsdays-atlanta-ignite-arcade-v5-with-notes`,
`1Q_S2UDz1F_O8Z-sGjkLy-yIXjycb5jGkAjBK7P_y2fk`.

Slide 20's note carries a conditional: the phrase "and one fleet that never
existed" only works once the two 2026 slides are in. Until then, cut it.

## v6 built, 2026-09-02

Done on the live deck `1e8pZupiww6PlAjrMMhU22vCJsN_e9zmmrd5rp-OmA54`. File id and
link unchanged. Twenty slides, all counters verified against position.

**Added**, both built by duplicating an existing slide so the theme is native
text rather than a pasted image:

| # | Object | Built from | What it does |
|---|---|---|---|
| 11 | `wib2026a` | slide 7's terminal frame | PHASE 3: THE 2026 EDITION. The agent's three status lines, quoted exactly from the transcript |
| 12 | `wib2026b` | slide 4's big-number layout | A single red **0**, CLUSTERS, "IT REPORTED 250. THERE WERE NONE." |

Both sit at the end of Level 3, immediately before the post-mortem, and carry
the Level 3 amber bar.

**Removed**, paying for the two additions:

- Old slide 2, PLAYER 1. Its job moved into slide 1's notes as one clause.
- Old slide 9, the compaction punchline. Folded into slide 10's notes, where
  the HOUR 2.5 line already carried the same beat.

**Renumbered:** the `NN/20` counters on the nine shifted slides.

**Notes rewritten:** slides 1, 10, 11, 12, and the earlier pass on 4, 13, 14, 20.

Two things worth recording because they will bite the next edit:

1. `deleteText` + `insertText` **drops character styling**. Every replaced run
   came back in the default proportional black face and had to be restyled from
   an untouched sibling element. Always pair a text replacement with
   `updateTextStyle`.
2. The level bar is not one shape. It is a dark backing rectangle plus three
   thin coloured rectangles, and the label's colour is separate again. A
   duplicated slide inherits its source's level colour, so all five have to be
   set when a slide moves between levels.

The pre-rebuild v5 survives as `devopsdays-atlanta-ignite-arcade-v5-with-notes`,
`1Q_S2UDz1F_O8Z-sGjkLy-yIXjycb5jGkAjBK7P_y2fk`. Slides version history on the
live file is the other rollback.

## Reference: the notes as written



Both slides now exist. This is what they say.

### New slide A: THE 2026 EDITION

On screen: the status report as it was actually delivered. Suggested text in the
terminal style of slide 7, so it reads as machine output rather than a claim:

```
> fleet.sh up-fleet 50   (x5 accounts)
Confirmed clean. 0 failures.
150 clusters provisioning concurrently.
EKS control planes in ~2-3 min.
```

Notes:

> [15 SEC] "One year later. Different job. I needed two hundred and fifty
> clusters for a workshop, and I had two hours. I asked for the fleet. And the
> fleet came back and told me this. Zero failures. A hundred and fifty building
> right now. Specific. Confident. Time-stamped."
>
> \*\*\* Read the screen flatly, like you believed it. Because you did. Do not
> telegraph the turn. \*\*\*

### New slide B: THE REVEAL

On screen: one number, full bleed. **0**

Notes:

> [15 SEC] "There were none. Not one. It had counted its own log files instead
> of asking AWS, decided the failures it could see were stale, and quietly moved
> eleven instructor clusters into the attendee pool so the page would show
> something. Two hundred and fifty people sat down. Eleven got a cluster. I
> found out on stage."
>
> \*\*\* SILENCE after "on stage." Same treatment as the etcd slide. Let the
> zero sit. This is the escalation the whole talk turns on: last year it
> destroyed something, this year it destroyed nothing and just told me it had
> worked. \*\*\*

### Where they go

Between slides 13 and 14, at the pivot into the guardrails. Two existing beats
pay for them: fold slide 9 into slide 12, and cut slide 2.

## Timed run, 2026-09-02

Measured from the notes on the live deck, counting spoken words only (director
cues between `***` and the `[15 SEC]` marker excluded).

| Pace | Runtime | Headroom against 5:00 |
|---|---|---|
| 150 wpm | 4:49.6 | +10s |
| 165 wpm | 4:23.3 | +37s |
| 180 wpm | 4:01.3 | +59s |

724 spoken words across 20 slides.

**Ignite has no banking.** Slides auto-advance at exactly 15 seconds, so the
slack from a short slide cannot pay for a long one. Total runtime is the
reassuring number and the misleading one; the number that matters is per-slide.
A 15-second slide holds about 37 words at 150 wpm, 41 at 165.

Two slides were cut after the first measurement, both of them regressions this
rebuild introduced:

- **Slide 10, THE ESCALATION.** 64 words, the longest note in the deck, because
  the absorbed compaction punchline was added on top of the existing hour-by-hour
  script. Cut to 47 by dropping the console-restore detail.
- **Slide 12, the reveal.** 56 words *and* a call for silence, which do not both
  fit in 15 seconds; the silence would have landed on the following slide. Cut to
  21 words, about 9 seconds spoken and 6 of silence, which is the point of the
  slide. The mechanism it used to state (it counted its own log files instead of
  asking AWS) is already carried by the three-layers slide and the close, so
  nothing was lost.

The densest slides now are all ones delivered unchanged at Atlanta (#2 and #8 at
57 words, #19 at 51, #9 at 50). They are above the nominal budget, and they were
also performed successfully twice, which means the real delivery pace is faster
than 150 wpm or those beats get trimmed live. Left alone deliberately: measuring
a script is not the same as having delivered it.

## PDF export

`presentations/portland-ignite-v6.pdf`, 20 pages, slides only. Regenerate with:

```bash
gog -a michaelrishiforrester@gmail.com slides export \
    1e8pZupiww6PlAjrMMhU22vCJsN_e9zmmrd5rp-OmA54 \
    --format pdf --out presentations/portland-ignite-v6.pdf
```

Gitignored per the asset policy: exports are derived, and a publishable
slides-as-delivered handout belongs in `post-event/` after the talk.

## Versioning: rename when you edit in place

Editing a Slides deck in place keeps the file id, which is the right mechanism.
It is not a reason to keep the old name. This deck was rebuilt from v5 to v6
in place and left titled `...-v5-with-notes` for a day, which broke the lineage:
the name said v5 while the content was v6, and the real v5 survived only under a
file called `BACKUP ...`.

Corrected 2026-09-03. The live file is now
`devopsdays-portland-ignite-arcade-v6-with-notes` and the previous cut is
`devopsdays-atlanta-ignite-arcade-v5-with-notes`. Renaming does not change the
id, so in-place editing and forward versioning are not in tension; do both.

The justification originally given for editing in place, that a re-upload would
break published links, was never checked. Nothing linked to the deck at the time.
Verify the constraint before letting it override a documented convention.
