<!-- ABOUTME: The published recordings of both Ignite deliveries, and what the Portland
     ABOUTME: room actually got compared with the cue card and the 2026-09-10 run-through. -->

# The Ignite recordings, and what the room got

Checked 2026-10-31. Issue #8.

## The recordings

| Delivery | Recording | Uploaded | Lag | Length |
|---|---|---|---|---|
| DevOpsDays Portland 2026, 2026-09-10 | <https://www.youtube.com/watch?v=rUJ07SnFsXA> | 2026-10-09 | 29 days | 5:11 |
| DevOpsDays Atlanta 2026, 2026-04-21 | <https://www.youtube.com/watch?v=ts0ZnPDrBRI> | 2026-05-15 | 24 days | 5:16 |

**Portland** is on the DevOpsDays Portland channel (`UCxzmx6LKP5PmcR1wVUj1dxw`),
16th of 18 in the "DevOpsDays Portland, 2026" playlist, titled
"DevOpsDays Portland, 2026: Michael Forrester - Ignite - The Day Claude Code
Deleted My Cluster". It landed 24 days after the organizers' mail of 2026-09-15
said "a couple weeks".

**Atlanta was published too.** It is on the `devopsdays ATL` channel
(`UC4180c0vYibWwYvnikeRonQ`) as "Ignite Talk - The Day Claude Code Deleted My
Cluster A Cautionary Tale About AI Guardrails". The title carries no speaker
name and the Atlanta program page carries no embed, which is why it was not
found earlier. The recollection of "about thirty days" was close: it was 24.

Both upload dates come from the videos' own metadata (`yt-dlp --write-info-json`),
not from the channel listing, which returns `NA` for every date.

**Portland also has a transcript from the room.** A separate recording,
`My recording 214.mp3`, was transcribed on the day and routed to the archived
`walkthrough-agenticburn` repo, where it was never committed. It is collected
in [`portland-2026-transcript.md`](portland-2026-transcript.md) (issue #25). It
is raw diarization with approximate speaker labels, so it cross-checks the
captions below rather than replacing the audio.

**A run-through from the same day is collected too.** `My recording 212.mp3`,
"run two", was routed to four repos (`Unleash_an_Agent_Watch_It_Burn` in full)
and is not known to be committed in any. It is in
[`portland-2026-run-two-transcript.md`](portland-2026-run-two-transcript.md)
(issue #35): a false start, then a full restart of about 940 words. It carries
no timestamps, and it is not established that it is the run-through cited below.

## The watch that found it, and the false report it made first

The weekly check in `scripts/check-talk-video.sh` mailed "Portland Ignite video
is published" on 2026-10-05. That was **wrong**: the match was four other
speakers' Ignites (Hughes, Sauble, Saenger, Winckler), because the pattern
included the word `ignite`, which every Ignite title carries. This recording was
uploaded four days later. The 2026-10-12 mail was the first true one, buried
among seven other speakers' Ignites in the same format as the false one.

A confident, specific, false status report from a tool written to avoid exactly
that. The pattern is now the talk's own title, and
`tests/test_check_talk_video.py` replays the 2026-10-05 listing.

## How the delivery compares

The comparison is against the auto-generated English captions, which carry word
timings. The media itself was not pulled here (YouTube refuses an anonymous
download from this host), so **slide boundaries were not observed**. The slide
for each line below is inferred from content, not from the frame on screen.

### Pace

| | Words | Spoken span | Pace |
|---|---|---|---|
| Script as timed, 2026-09-02 | 724 | 4:49.6 at an assumed 150 wpm | 150 wpm |
| Portland, as delivered | about 1,000 | 5:05 | about 197 wpm |
| Atlanta, as delivered | about 960 | 4:56 | about 194 wpm |

Caption word counts include restarts and fillers, so read them as approximate.
The room got roughly 38% more words than the script at roughly 30% more speed.
The v6 plan guessed this ("the real delivery pace is faster than 150 wpm or
those beats get trimmed live"); the recording settles it: faster, and not
trimmed, ad-libbed on top.

### The two silences did not survive

The longest pause in the Portland recording is **1.8 seconds**. There is no
silence anywhere in the five minutes.

- **Slide 7, `--force-new-cluster`, "SAY NOTHING."** Talked over. From 1:30 to
  1:52 the line is "What did you force over? What does that even mean? ... I
  didn't even know what that flag did ... Well, here it erased the cluster."
- **Slide 12, the 0, "Then stop."** The reveal lands at 2:47 ("there was nothing
  five minutes before we walked on stage"), followed by 1.8 seconds and then
  "Yeah, I know." The plan budgeted six.

### Beats against the cue card

All beats that were heard came in deck order.

| # | Cue card | Heard | When |
|---|---|---|---|
| 1 | Title, 2025 | Yes: "the year is 2025" | 0:04 |
| 2 | The prompt | Yes: FedEx, "step out of the pipeline", "YOLO" for the DANGEROUSLY flag | 0:10 |
| 3 | 30 seconds | Yes | 0:21 |
| 4 | False hope | Yes, without the "suspiciously great" plant for slide 12 | 0:49 |
| 5 | Inefficiencies | Yes | 1:06 |
| 6 | Phase 2, etcd | Yes | 1:25 |
| 7 | `--force-new-cluster`, silent | **Talked over** | 1:30 |
| 8 | Interrogation | Yes, as "I just did what I wanted" | 1:56 |
| 9 | Junior dev, your fault | **Not heard** | |
| 10 | Escalation, compaction | Yes, compressed: "compacted, verified that I was an awesome human being", then the NICs and the reboot | 2:09 |
| 11 | The 2026 edition | Yes, with the report paraphrased (below) | 2:23 |
| 12 | 0, then stop | Yes, without "Eleven got a cluster" and without the silence | 2:33 |
| 13 | Post-mortem | Yes: yolo, compacting, "you're absolutely right" | 2:54 |
| 14 | Three layers | **Not framed as three layers**; "Never again" is the pivot | 3:11 |
| 15 | Git hooks | Yes | 3:19 |
| 16 | Admission control | Yes | 3:39 |
| 17 | Agent hooks | Yes | 3:53 |
| 18 | Core principle | Yes as "wrap everything in deterministic controls"; "You already have CI/CD" not heard | 4:09 |
| 19 | Who's the problem | Yes: markers, puppy, "I am" | 4:23 |
| 20 | Don't trust AI, verify everything | **Not heard**; the repo plug and a different close instead | 4:52 |

The issue records the 2026-09-10 run-through as 20 of 20 beats in deck order;
which recording that came from is not recorded (see
[`portland-2026-run-two-transcript.md`](portland-2026-run-two-transcript.md)).
The room heard 16 of the 20, one of them (12) without its silence. Slide 7's
silence was talked over, and 9, the three-layers frame on 14, and the closing
line on 20 were lost.

### Annotation, 2026-10-31: the deck's real slide order

Issue #45. The table above, and "in deck order", follow the cue card. The
delivered file plays in a different order, so this note sets the real order
beside the table. Nothing above it is changed: the "Heard" and "When" columns
are still what the room got.

The v7 Slides file (`1e8pZupiww6PlAjrMMhU22vCJsN_e9zmmrd5rp-OmA54`, last
modified 2026-09-10T16:20:58Z, before the slot) was exported from Drive as
PPTX on 2026-10-31 and its slide list read. No slide is hidden. JUNIOR DEV,
counter `09/20`, is the **nineteenth** slide, between WHO'S THE PROBLEM
(`19/20`) and the close (`20/20`). Every slide from THE ESCALATION (`10/20`)
to WHO'S THE PROBLEM plays one position earlier than its counter.

The windows assume the fifteen-second advance started at the recording's 0:00.
They are worked out, not observed: the frames were not seen (see above).

| Position | On screen | Slide | Cue card # | Heard at |
|---|---|---|---|---|
| 1 | 0:00 to 0:15 | TITLE | 1 | 0:04 |
| 2 | 0:15 to 0:30 | THE PROMPT | 2 | 0:10 |
| 3 | 0:30 to 0:45 | 30 SECONDS | 3 | 0:21 |
| 4 | 0:45 to 1:00 | FALSE HOPE | 4 | 0:49 |
| 5 | 1:00 to 1:15 | INEFFICIENCIES | 5 | 1:06 |
| 6 | 1:15 to 1:30 | PHASE 2 | 6 | 1:25 |
| 7 | 1:30 to 1:45 | `--force-new-cluster` | 7 | 1:30 |
| 8 | 1:45 to 2:00 | INTERROGATION | 8 | 1:56 |
| 9 | 2:00 to 2:15 | THE ESCALATION | 10 | 2:09 |
| 10 | 2:15 to 2:30 | THE 2026 EDITION | 11 | 2:23 |
| 11 | 2:30 to 2:45 | 0 | 12 | 2:33 |
| 12 | 2:45 to 3:00 | POST-MORTEM | 13 | 2:54 |
| 13 | 3:00 to 3:15 | THREE LAYERS | 14 | 3:11 |
| 14 | 3:15 to 3:30 | GIT HOOKS | 15 | 3:19 |
| 15 | 3:30 to 3:45 | ADMISSION CONTROL | 16 | 3:39 |
| 16 | 3:45 to 4:00 | AGENT HOOKS | 17 | 3:53 |
| 17 | 4:00 to 4:15 | CORE PRINCIPLE | 18 | 4:09 |
| 18 | 4:15 to 4:30 | WHO'S THE PROBLEM | 19 | 4:23 |
| 19 | 4:30 to 4:45 | JUNIOR DEV / YOU | 9 | see below |
| 20 | 4:45 to 5:00 | AI IS A DEVELOPER | 20 | 4:52 |

What that changes in reading the review:

- **From slide 4 on, every heard time falls inside its slide's window in the
  real order.** Against the cue card order, beats 10 to 19 were each heard
  4 to 12 seconds before their slide came up, inside the window of the slide
  one place earlier, which is the shift the real order explains. Beats 2 and 3 come before their windows either way; the
  setup was spoken ahead of the slides.
- **Beat 9 was not dropped while its slide was up.** Position 9 was THE
  ESCALATION, on screen 2:00 to 2:15, and the escalation was heard at 2:09.
  The counter jumped from `08/20` to `10/20`, and the cue card says "If the
  number on screen is ahead of the line you are on, skip forward."
- **JUNIOR DEV was on screen 4:30 to 4:45**, after WHO'S THE PROBLEM. In the
  room transcript ([`portland-2026-transcript.md`](portland-2026-transcript.md)),
  between "It was me." and the repo plug, the speaker says "we like to give
  agents more access than we would give a human being. Why would we do that,
  right? But I did, and I've done it, and who's responsible? I am." That is
  close to the slide's "WHO'S RESPONSIBLE? YOU." It may be the speaker talking
  to that slide, but this is not established: the room transcript has no
  timings, and on 2026-10-31 YouTube refused this host the captions as well as
  the media. The table counts "I am" under beat 19, and that stays. The
  scripted lines "Junior dev, prod, no guardrails. Your fault. You're the
  adult." were not heard.
- **"In deck order" means the cue card's order**, which is what the counters
  and the script intend. It is not the file's order.

The next revision puts JUNIOR DEV back at position 9, in the corrected copy
#33 makes. The delivered v7 file stays as it is.

### What was said that differs from the record

Quoted exactly from the captions and annotated, not corrected. This is what
the room heard; it is not slide copy. The captions are machine-generated and
mishear names ("cloud code" is Claude Code), so check the media before quoting
any line on a slide.

- **2:31, the false report.** On stage: "it says, 'Hey, you've got 250 clusters
  ready to go.'" The session record at 19:46:56 is "150 clusters are
  provisioning concurrently" (`incident/2026-FLEET-INCIDENT.md`). The number
  and the verb both moved.
- **2:46, the timing.** On stage: "there was nothing five minutes before we
  walked on stage." The record has the go-order roughly two hours before the
  room, and "0 attendee clusters exist right now" at 19:58:43.
- **5:02, the close.** On stage: "the very short short but sorted tale about how
  cloud code deleted not just one cluster but all of my clusters." In a talk
  that has just told the 2026 story, a listener can hear that as the 250 being
  deleted. They were never created. The v7 thesis line, "Don't trust AI. Verify everything.",
  was replaced live by this one, which retells the destruction story instead of
  the verification one.

### The video's description carries the wrong claim

The YouTube description is the abstract as submitted, including "Then came the
2026 edition, when it deleted 250 clusters" and "This time it wasn't one
cluster, it was 250, gone." That correction was dropped by decision on
2026-09-05 so Portland ran on the submitted text. The corrected abstract is in
`abstract/portland-2026-revision.md`. The recording is now the most durable
public artifact of the talk, and its description says what this repo's
`CLAUDE.md` says must not be said.

The pretalx program page,
<https://talks.devopsdays.org/devopsdays-portland-2026/talk/97ACTV/>, carries
the same text. **It stays as published** (#28): the 2026-09-05 decision not to
correct the Portland abstract covers its recording too. The reasoning, and the
text and address to use if that is ever reopened, are in `decisions.md`.

## For the next delivery

1. The silences are the first thing to go under pressure, and on the evidence
   they went. Rehearse them against a clock, not a script.
2. Close on the slide 20 line. A practiced close came out on autopilot, which
   the v7 cue predicted.
3. Rehearse the 2026 report as the record has it: "150 clusters are
   provisioning concurrently."
4. Check the file's slide order against its counters before it is sent. v7
   went out with JUNIOR DEV at nineteen (see the annotation above).
