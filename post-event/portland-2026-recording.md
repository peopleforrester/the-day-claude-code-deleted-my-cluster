<!-- ABOUTME: The published recordings of both Ignite deliveries, and what the Portland
     ABOUTME: room actually got compared with the cue card and the 2026-09-10 run-through. -->

# The Ignite recordings, and what the room got

Checked 2026-10-31. Issue #8, with the slide boundaries and the quotes checked
against the media the same day (#29).

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

### The local copy

`recordings/` is gitignored, so the media never lands in the repo. Pulled
2026-10-31 (#29), 1080p H.264 with Opus audio:

| File | Bytes | Length | SHA-256 |
|---|---|---|---|
| `20261009-rUJ07SnFsXA.mp4` (Portland) | 37,728,772 | 5:10.7 | `6a0ecc3e9f14ed642d6093bb171fbb0f6ddd494c090f959b666486cace8bd77a` |
| `20260515-ts0ZnPDrBRI.mp4` (Atlanta) | 28,721,118 | 5:16.2 | `e23c6f211dd0ac7dae953d1df58a808bab59fadef406de14b0862659b82fe73f` |

Each file sits beside its `.en.vtt` auto-captions and `.info.json`.

A plain `yt-dlp` gets "Sign in to confirm you're not a bot" from the hosts
these runs use. With the default clients it also gets HTTP 429 or a
storyboard-only format list. The fix is the `web_embedded` player client plus
a JavaScript runtime to solve YouTube's `n` challenge. `yt-dlp[default]` pulls
in the solver, `yt-dlp-ejs`. No cookies or sign-in are needed:

```bash
cd recordings && \
  uvx --python 3.13 --from 'yt-dlp[default]==2026.10.26' yt-dlp \
    --js-runtimes node --extractor-args youtube:player_client=web_embedded \
    --write-auto-subs --sub-lang en --write-info-json \
    -f 'bv*[height<=1080]+ba/b' --merge-output-format mp4 \
    -o '%(upload_date)s-%(id)s.%(ext)s' \
    https://www.youtube.com/watch?v=rUJ07SnFsXA https://www.youtube.com/watch?v=ts0ZnPDrBRI && \
  ls -la
```

The merge needs `ffmpeg`. Check each `.mp4` with `ffprobe` for a video and an
audio stream and the length above. Do not rely on the exit code.

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

The comparison started from the auto-generated English captions, which carry
word timings. The first pass could not pull the media, so it inferred each
line's slide from content. The media was pulled later the same day (#29, recipe
under "The local copy" below), and **the slide boundaries are now observed**.
Where the media contradicted the first pass, the text below says so.

### Slide boundaries, as observed

The published edit cuts to a clean feed of the slides each time the slide
changes. Between cuts, the camera shots show the same slide on the room's
screen. Each cut sits on a 15-second grid to within a second. Every one checked
at half-second resolution (slides 7, 8, 12, 13, 9 and 20) is sharp to within
half a second.

| On screen | Slide (its `NN/20` counter) | From | To |
|---|---|---|---|
| 1st | 1, title | before 0:00 | 0:05 |
| 2nd | 2, the prompt | 0:05 | 0:35 |
| 3rd–8th | 3 to 8, in order | 0:35 | 2:05 |
| 9th–18th | **10** to 19, in order | 2:05 | 4:34 |
| 19th | **9**, junior dev, "WHO'S RESPONSIBLE? YOU." | 4:34 | 4:50 |
| 20th | 20, close | 4:50 | about 5:06 |

Each slide from 3 onward got 15 seconds: 7 ran 1:35–1:50 and 12 ran
2:35–2:50.

Two things the caption pass could not see:

- **Slide 9 was on screen, out of order.** Slide 10 followed 8 directly at
  2:05. The junior-dev slide, still numbered `09/20`, came up at 4:34 between
  19 and 20. The camera shots from 4:37 to 4:49 show it on the room's screen
  ("+ NO GUARDRAILS", Level 3 bar), so the room saw this order, not just the
  edit. The video cannot show whether the order came from the deck file or
  from the copy the organizers ran. They held the PDF and PPTX sent at
  10:00 PT.
- **Slide 2 held for about 30 seconds.** The room's screen shows it from no
  later than 0:12 until 0:35, and the slide feed has it from 0:05. Every later
  slide got 15.

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

There is no silence anywhere in the five minutes. Measured on the audio
(`ffmpeg silencedetect`), nothing in the recording stays below -30 dBFS for
longer than 1.3 seconds. The first pass put the longest pause at 1.8 seconds,
from caption timings. Caption timings are not pauses, so read that as
superseded.

- **Slide 7, `--force-new-cluster`, "SAY NOTHING."** Talked over, confirmed.
  The slide was up from 1:35 to 1:50, and the whole of it is speech: "I left
  for 30 seconds. What does that flag, I didn't even know what that flag did.
  ... Well, it erased the cluster." That is Whisper's hearing. "What did you
  force over? What does that even mean?", which the first pass placed here,
  comes at 1:29–1:32. That is on slide 6, whose screen reads "Applying force
  override...". The captions have "Well, here it erased the cluster." Both
  independent hearings (below) have no "here".
- **Slide 12, the 0, "Then stop."** The 0 came up at 2:35, on "The truth was
  that", and about a second of quiet followed it. The reveal ends at 2:47.9 on
  "walked on stage". After it comes under a second of near-silence (below
  -45 dBFS from 2:48.0 to 2:48.75), then room sound, then "Yeah, I know." at
  2:49.5. Word to word that is 1.6 seconds. The plan budgeted six.

### Beats against the cue card

Every beat that was heard came on its own slide, and the slides came in deck
order except 9 (see "Slide boundaries, as observed" above). The first pass said
all beats came in deck order and that 9 was not heard. The media shows 9 was
heard, on its own slide, in 19th place.

| # | Cue card | Slide up | Heard | When |
|---|---|---|---|---|
| 1 | Title, 2025 | before 0:00 | Yes: "the year is 2025" | 0:04 |
| 2 | The prompt | 0:05 | Yes: FedEx, "step out of the pipeline", "YOLO" for the DANGEROUSLY flag | 0:10 |
| 3 | 30 seconds | 0:35 | Yes: "It's just 30 seconds" (the 0:21 line the first pass took for this beat is on slide 2) | 0:38 |
| 4 | False hope | 0:50 | Yes, without the "suspiciously great" plant for slide 12 | 0:49 |
| 5 | Inefficiencies | 1:05 | Yes | 1:06 |
| 6 | Phase 2, etcd | 1:20 | Yes | 1:25 |
| 7 | `--force-new-cluster`, silent | 1:35 | **Talked over** | 1:35 |
| 8 | Interrogation | 1:50 | Yes, as "I just did what I wanted" | 1:56 |
| 9 | Junior dev, your fault | **4:34**, after 19 | Yes, on its slide: "we like to give agents more access than we would give a human being ... who's responsible? I am." | 4:38 |
| 10 | Escalation, compaction | 2:05 | Yes, compressed: "compacted, verified that I was an awesome human being", then the NICs and the reboot | 2:09 |
| 11 | The 2026 edition | 2:20 | Yes, with the report paraphrased (below) | 2:23 |
| 12 | 0, then stop | 2:35 | Yes, without "Eleven got a cluster" and without the silence | 2:35 |
| 13 | Post-mortem | 2:50 | Yes: yolo, compacting, "you're absolutely right" | 2:54 |
| 14 | Three layers | 3:05 | **Not framed as three layers**; "Never again" is the pivot | 3:11 |
| 15 | Git hooks | 3:20 | Yes | 3:19 |
| 16 | Admission control | 3:35 | Yes | 3:39 |
| 17 | Agent hooks | 3:50 | Yes | 3:53 |
| 18 | Core principle | 4:05 | Yes as "wrap everything in deterministic controls"; "You already have CI/CD" not heard | 4:09 |
| 19 | Who's the problem | 4:20 | Yes: markers, puppy, "I'm the problem, right? It was me." (the "I am" the first pass put here is slide 9's) | 4:23 |
| 20 | Don't trust AI, verify everything | 4:50 | **Not heard**; the repo plug and a different close instead | 4:52 |

"When" is when the beat is first heard. It can lead its slide by a second
(4, 15).

The issue records the 2026-09-10 run-through as 20 of 20 beats in deck order.
The room heard 17 of the 20, one of them (12) without its silence and one (9)
out of order. Slide 7's silence was talked over, and the three-layers frame on
14 and the closing line on 20 were lost.

### What was said that differs from the record

Quoted exactly from the captions and annotated, not corrected. This is what
the room heard; it is not slide copy. The captions are machine-generated and
mishear names ("cloud code" is Claude Code), so check the media before quoting
any line on a slide.

**Checked against the audio, 2026-10-31 (#29).** Each quote was compared with
two hearings independent of the captions. One is a fresh transcription of the
video's audio track with Whisper `medium.en`, word-timed. The other is the room
transcript from a different microphone,
[`portland-2026-transcript.md`](portland-2026-transcript.md). All three are
machine hearings. Where they agree, the words are settled. Where they differ,
the note says so, and a person has to listen before that word is reused.

- **2:31, the false report.** On stage: "it says, 'Hey, you've got 250 clusters
  ready to go.'" The session record at 19:46:56 is "150 clusters are
  provisioning concurrently" (`incident/2026-FLEET-INCIDENT.md`). The number
  and the verb both moved.
  *Audio: all three hearings agree word for word. It was said with slide 11
  behind it, and slide 11 shows the record's own line, "150 clusters are
  provisioning concurrently."*
- **2:46, the timing.** On stage: "there was nothing five minutes before we
  walked on stage." The record has the go-order roughly two hours before the
  room, and "0 attendee clusters exist right now" at 19:58:43.
  *Audio: the words agree. The captions run them together, but both other
  hearings break the sentence after "nothing": "There was nothing. Five minutes
  before we walked on stage." The audio has a pause there, about a second
  below -50 dBFS between "nothing" (ends 2:45.4) and "Five" (2:46.4). The break
  changes what the line claims. Unbroken, it says nothing existed five minutes
  before the room. Broken, it says the fleet did not exist, and that this was
  five minutes before going on. Quote it with the break.*
- **5:02, the close.** On stage: "the very short short but sorted tale about how
  cloud code deleted not just one cluster but all of my clusters." In a talk
  that has just told the 2026 story, a listener can hear that as the 250 being
  deleted. They were never created. The v7 thesis line, "Don't trust AI. Verify everything.",
  was replaced live by this one, which retells the destruction story instead of
  the verification one.
  *Audio: three points differ. "short short" is doubled only in the captions.
  Both other hearings have one "short", but machine transcription drops
  repetitions, so this is not settled. "sorted" is the captions' spelling of
  "sordid", the idiom, which Whisper writes out. Whisper hears "one cluster on
  all of my clusters". The captions and the room transcript hear "but all", two
  to one. Listen before reusing any of the three.*

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
