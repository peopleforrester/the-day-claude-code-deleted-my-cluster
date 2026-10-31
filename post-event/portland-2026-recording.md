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

The issue records the 2026-09-10 run-through as 20 of 20 beats in deck order.
The room heard 16 of the 20, one of them (12) without its silence. Slide 7's
silence was talked over, and 9, the three-layers frame on 14, and the closing
line on 20 were lost.

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

## For the next delivery

1. The silences are the first thing to go under pressure, and on the evidence
   they went. Rehearse them against a clock, not a script.
2. Close on the slide 20 line. A practiced close came out on autopilot, which
   the v7 cue predicted.
3. Rehearse the 2026 report as the record has it: "150 clusters are
   provisioning concurrently."
