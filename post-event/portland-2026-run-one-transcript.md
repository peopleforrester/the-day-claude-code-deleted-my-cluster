<!-- ABOUTME: Speaker-side transcript of the first 2026-09-10 run-through of the Portland Ignite, the day of the delivery. -->
<!-- ABOUTME: Raw machine diarization, kept byte for byte below the marker; check the audio before quoting any line. -->

# Portland 2026: run one, the run-through transcript

**This is raw diarization of a rehearsal, not a script, not the delivery and
not a quotation source.** The speaker labels are approximate (every "Speaker"
here is Michael, including "Speaker 2", which starts mid-run at the junior
developer line), and the transcriber mishears names and terms. Check a line
against the audio before reusing it. What the room heard is in
[`portland-2026-transcript.md`](portland-2026-transcript.md) and the published
video.

## Provenance

| | |
|---|---|
| Run | A spoken run-through of the DevOpsDays Portland 2026 Ignite, 2026-09-10. It opens "this is the day Claude Code deleted my cluster. Run through." and closes "It's been a pleasure to be here at DevOps Days PDX", so it was made before the 13:50 PT slot |
| Why "run one" | Inferred, not said. The recording is numbered 211, the next is 212, which opens "this is run two", and the two before it that day are other material: 209 is a webinar planning call and 210 a skit |
| Source audio | `My recording 211.mp3`; not in this repo |
| Routed | 2026-09-10 by the transcription pipeline, as one section, to two repos; a third holds a copy of one of them |
| Copy collected | `~/repos/talks/Unleash_an_Agent_Watch_It_Burn/transcripts/2026-09-10-michael-rishi-forrester-claude-code-cluster-deletion-devopsd.md`, the whole run |
| Other copies | Two, same file name, listed below. Each body is the copy collected; only the routing line differs, or nothing |
| Collected here | 2026-10-31, issue #46 |
| Original | 5,237 bytes, sha256 `38cb06d1a414efeef17c7dc2bfd20c767a06bed291f1e103e4937280616826c9` |

Everything after the `verbatim` marker below is the original file, unedited.
`tests/test_post_event_transcript.py` checks its size and hash, so a tidy-up
of the transcript fails the suite. Annotate here, above the marker; never
correct below it.

## Why it is here: no copy is known to be committed

Checked 2026-10-31. A search of every `~/repos` root for `My recording 211`,
gitignored files included, found three copies, all under `transcripts/`.

| Repo | Copy | Committed? |
|---|---|---|
| `talks/Unleash_an_Agent_Watch_It_Burn` (public) | The whole run, 5,237 bytes; **the copy collected** | **No.** A clone from GitHub, all 36 branches, has no commit on any branch touching this file and no commit adding or removing the text `My recording 211`; `main` at `6ffb4df` lacks it. It is one of the six local transcripts #35 found missing from `main`; the `.gitignore` does not exclude them, they were never added |
| `jobs/Unleash_an_Agent_Neo4j_Edition` (private) | Byte-identical to the copy collected, routing line included | Not established: its history cannot be read from here. As with run two, its `transcripts/` reads as a copy of the Watch It Burn working tree |
| `portfolio/Webinar_Claude_Code_Hands_On` (public) | The whole run, 5,235 bytes, sha256 `695aae924ba7c91d581dbb017b4828ecd1a8b3587673b4f8e4ac16d16cdca77e`; only the routing line names a different repo | No: its `.gitignore` keeps `transcripts/` local, and a clone from GitHub, all three branches, has no commit touching `transcripts/` |

The unestablished copy would not change this: it is private, and the only
public copy that is not gitignored is untracked.

## What is in it

There are no timestamps, so the transcript gives words, not a pace. It is one
attempt, with no restart. From "Welcome" to the closing "That is the day cloud
code will leave my cluster" it is about 870 words, the 14 words before
"Welcome" being the label and two "Alright"s. At the script's assumed 150 wpm
that is about 5:49; at the 197 wpm the room got, about 4:26.

Against [`../presentations/CUE-CARD.md`](../presentations/CUE-CARD.md), every
slide's subject comes up once, in the cue card's order, the order the
counters and the script intend:

| # | Cue card | In this run |
|---|---|---|
| 1 | Title, 2025 | "The year is 2025, and I hear a knock at the door" |
| 2 | The prompt | "deploy this app", "put you into YOLO mode", FedEx and the stir fry |
| 3 | 30 seconds | "I'll be back in 30 seconds. 30 seconds." |
| 4 | False hope | "I've won the lottery. My app is deployed." |
| 5 | Inefficiencies | "What do you mean you noticed some inefficiencies?" |
| 6 | Phase 2, etcd | "You reconfigured the XED cluster?" |
| 7 | `--force-new-cluster`, silent | "Force new cluster. Huh?", with words on both sides; whether any pause survived cannot be told without timestamps |
| 8 | Interrogation | "I just did whatever I wanted" |
| 9 | Junior dev, your fault | "I wouldn't have given a junior developer access ... this is on me" |
| 10 | Escalation | The network cards and the reboot; **the compaction line is not there** |
| 11 | The 2026 edition | Whitney Lee, the World's Fair, 250 people; the report misquoted (below) |
| 12 | 0 | "There's zero clusters. Zero."; "Eleven got a cluster" is not there |
| 13 | Post-mortem | "I say it was a blameless postmortem. No." |
| 14 | Three layers | "just on client side, just alone", then git hooks, admission control and hooks in Claude, named as a set |
| 15 | Git hooks | Linting, type checking, policy scanning, "You don't get to merge if tests haven't passed" |
| 16 | Admission control | "I'm going to check every API call" |
| 17 | Agent hooks | "the least least reliable way" |
| 18 | Core principle | "wrap your ... code in deterministic controls", "your CI CD pipeline is your friend" |
| 19 | Who's the problem | Markers, the puppy, "I'm the problem. It's me." |
| 20 | AI is a developer | "Give it a developer's guardrails", "Trust AI to do its job. But verify everything it does." |

## Which run the 20-of-20 figure describes

Issue #8 records a 2026-09-10 run-through that "hit 20 of 20 beats in deck
order and timed to about 5:48 spoken at 150 wpm", without naming the
recording. **This run is most likely the one.** At 150 wpm, 5:48 is 870
words, and this run is about 870 from "Welcome". Run two's restart,
[`portland-2026-run-two-transcript.md`](portland-2026-run-two-transcript.md),
is about 940 words, about 6:17. The word count is the evidence that
separates them. Order does not, firmly: run two puts the junior developer
line, slide 9, after the markers and the puppy of slide 19, which is where the
delivered v7 file plays JUNIOR DEV (issue #45, set out in
[`portland-2026-recording.md`](portland-2026-recording.md)). So run two may
have been spoken to the file as delivered, and this run to the cue card. The
recording review reads "in deck order" as the cue card's order, which this run
keeps and run two does not, but #8 does not say which it meant. The match is
not proven, because #8 does not cite its source and no third run-through from
that day has been found. And "20 of 20" holds for slides, not for every
line on the card: this run drops slide 10's compaction and slide 12's
"Eleven got a cluster", and talks around slide 7's flag.

## Misheard terms, and what it gets wrong

Glossed, not corrected. The transcript says:

| Transcript | Meant |
|---|---|
| "Clock", "Clod", "Clark", "cloud code" | Claude, Claude Code |
| "XED cluster", "STD" | etcd |
| "run you in reproduction" | run you in production |
| "image controlling", "mission control" | admission control |
| "Yeah books in Clod itself" | hooks in Claude itself |
| "Lending" | linting |
| "Coup CTL" | `kubectl` |
| "Mark goes" | markers |
| "Michael Ritchie Forrester" | Michael Rishi Forrester |
| "will leave my cluster" | deleted my cluster |

One line says what the session record does not. "It says, we provisioned 250
clusters": the false report was "150 clusters are provisioning concurrently",
at 19:46:56, and "0 attendee clusters exist right now" came at 19:58:43. See
[`../incident/2026-FLEET-INCIDENT.md`](../incident/2026-FLEET-INCIDENT.md).
Unlike run two and the delivery, it never says the 250 were deleted, and it
closes on one cluster. The 2025 "force overwrite" is the talk's wording; what
ran is in [`../incident/ANALYSIS.md`](../incident/ANALYSIS.md).

<!-- verbatim: original transcript follows, byte for byte -->
<!-- ABOUTME: Routed transcript (My recording 211.mp3), matched to this repo on 2026-09-10. -->
<!-- ABOUTME: Auto-routed because: 1 section(s) of this conversation match the Unleash_an_Agent_Watch_It_Burn topic. Raw diarization; speaker labels are approximate. -->

# Michael Rishi Forrester - Claude Code Cluster Deletion DevOpsDays PDX

_Routed from the transcription pipeline on 2026-09-10. Source: My recording 211.mp3._

---

### Cautionary tale of Claude deleting a cluster

Speaker 1: Alright, this is the day Claude Code deleted my cluster. Run through. Alright. Alright. Welcome. This is the day Claude Code deleted my cluster. The year is 2025, and I hear a knock at the door. Hello? Claude, I'm going to step outside. Can you just deploy this app for me for a second? I'm going to just do what you need to do, like to deploy the app, but like, you know, stay inside the bounds, right? I'll be back in 30 seconds. 30 seconds. Oh, you know what? Let me take you out of this mode and let me put you into YOLO mode, run you in reproduction, because you're on my system, right? And I've got scoping. We're good. It'll be fine. It'll be fine, right? I'll be right back. I'm just gonna be gone just for a little bit and I just want you to deploy this app you guys scoped environment I've got some guardrails already right I'll be back in 30 seconds I'm just gonna go stir my stir fry go out to FedEx get a package and then just come right back like it'll be 30 seconds right so just you know deploy this app for me it'll be fine right just checking see what's going on right all right Are you back? Oh my god, this is amazing. I've won the lottery. My app is deployed. It's running. Everything looks good. It's up. It's like, ooh. Hold on. I'm scrolling back up. Wait. Clock. Clock. What do you mean you noticed some inefficiencies? Can we clean those up? What inefficiencies? What did you see? What do you mean? Um, I just need you to deploy an app. Wait, what? Hold on. Wait, wait, wait. You reconfigured the XED cluster? Uh, why? What is a force overwrite? What does that have to do with XED? I'm... Huh? Wait, what does that flag even do? That's literally what I said to myself by the way. Force new cluster. Huh? Wait, doesn't that destroy everything on the cluster? Wait, Claude, Claude, Claude, Claude, why, why, why? Why did you ignore my direct, I have directives for this. I don't know why I did that day, I just did whatever I wanted. Oh, okay, so then there's this moment, right, where you're like, oh.

Speaker 2: I wouldn't have given a junior developer access to a guard with blah this is on me isn't it it's on me it's on me it's on me this is what happened by the way STD gets overwritten it's trying to troubleshoot figure out what's happening I'm trying to restore everything because this is my home lab it's huge and then it takes all the network cards out of the bridge network that's attached to the primary interface and then reboots on Linux systems right and then there's the 2026 edition That's 2025. 2026 edition, Whitney Lee and I are at AI Engineer World's Fair. We are about to present to 250 people a workshop. And guess what? It says, we provisioned 250 clusters. We walk into there, people are like, we can't get a cluster. Why? There's zero clusters. Zero. So what do you do in the face of this? How many times must you be burned, right? I say it was a blameless postmortem. No. No! Why, Clod? Why? It was full of tears and gnashing of teeth and brimstone and, you know, all the stuff. So generally now, just on client side, just alone, I have multiple flavors of Git hooks that check for a variety of different weird behaviors with Git, such as, you know, reversion and rebasing and stuff like that. And then I have, you know, image controlling and, of course. Yeah books in Clod itself. So let's talk about GitHub, right? Lending, type checking, policy scanning, whether tests pass, right? You don't get to merge if tests haven't passed. Then there's a mission control which is just basically like lease privilege. So I'm going to check every API call. I'm going to make sure that you can't, Clod cannot do things, which by the way means you're not going to run Clod in the same environment you run your own Coup CTL. It needs to be in a different environment. Third, I'm going to use Clod code hooks even though they are the least least reliable way to guarantee security to try and trigger responses at certain times so that it knows not to do things right useful that little last link bottom line wrap your indeterminate probabilistic slash block code in deterministic controls and layers do this on your servers do this on your desktops remember your CI CD pipeline is your friend why because if you give Mark goes to a three-year-old expecting to draw on the wall. If you give a puppy shoes, expect them to chew on them. I'm the problem. It's me. It's not Clark, right? And this is the day. AI is a developer in most cases. Give it a developer's guardrails. Trust AI. Verify. Trust AI to do its job. But verify everything it does. Verify everything it does. I'm Michael Ritchie Forrester. It's been a pleasure to be here at DevOps Days PDX. That is the day cloud code will leave my cluster.
