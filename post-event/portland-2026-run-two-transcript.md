<!-- ABOUTME: Speaker-side transcript of a 2026-09-10 run-through of the Portland Ignite, the day of the delivery. -->
<!-- ABOUTME: Raw machine diarization, kept byte for byte below the marker; check the audio before quoting any line. -->

# Portland 2026: run two, the run-through transcript

**This is raw diarization of a rehearsal, not a script, not the delivery and
not a quotation source.** The speaker labels are approximate (every "Speaker"
here is Michael, including "Speaker 2" reading the agent's lines and the whole
restarted run), and the transcriber mishears names and terms. Check a line
against the audio before reusing it. What the room heard is in
[`portland-2026-transcript.md`](portland-2026-transcript.md) and the published
video.

## Provenance

| | |
|---|---|
| Run | A spoken run-through of the DevOpsDays Portland 2026 Ignite, 2026-09-10; numbered before the delivery's `My recording 214.mp3`, and it closes "It's been a pleasure to be at Portland DevOps Days", so before the 13:50 PT slot. It opens "this is run two of the day Claude Code deleted my cluster" |
| Source audio | `My recording 212.mp3`; not in this repo |
| Routed | 2026-09-10 by the transcription pipeline, to four repos, each getting the sections it matched; a fifth holds a copy of one of them |
| Copy collected | `~/repos/talks/Unleash_an_Agent_Watch_It_Burn/transcripts/2026-09-10-michael-forrester-claude-code-deleted-kubernetes-cluster-ai.md`, both sections, the whole run |
| Other copies | Four, same file name, listed below. Each body is the copy collected or a part of it; only the routing line differs |
| Collected here | 2026-10-31, issue #35 |
| Original | 8,254 bytes, sha256 `a25d282d1602ca908e57cc1fac3fa4807cb0ba6058b449253756aad188894574` |

Everything after the `verbatim` marker below is the original file, unedited.
`tests/test_post_event_transcript.py` checks its size and hash, so a tidy-up
of the transcript fails the suite. Annotate here, above the marker; never
correct below it.

## Why it is here: no copy is known to be committed

Checked 2026-10-31. The issue named two copies; a search of every `~/repos`
root for `My recording 212` found five, all under `transcripts/`.

| Repo | Copy | Committed? |
|---|---|---|
| `talks/Unleash_an_Agent_Watch_It_Burn` (public) | Both sections, 8,254 bytes; **the copy collected** | **No.** A clone from GitHub, all 36 branches, has no commit on any branch touching a `transcripts/` file dated 2026-09-10, and `main` at `6ffb4df` lacks it. It is one of six local transcripts not on `main`; the `.gitignore` does not exclude them, they were never added. The last commit to touch `transcripts/`, `ba3e053`, is from 2026-09-08 |
| `jobs/Unleash_an_Agent_Neo4j_Edition` (private) | Byte-identical to the copy collected, routing line included | Not established: its history cannot be read from here. Its `transcripts/` holds exactly the same file names as the Watch It Burn working tree, untracked six included, which reads as a copy of that tree |
| `conferences/conference-management` (private) | Both sections, 8,245 bytes, sha256 `47bca585932e5025463357b76430e45349791e55a9d423d65ae4c76c2061039e` | No: its `.gitignore` opens with `transcripts/` |
| `_archive/talks/Kubecon-NA-2026-Whitney-BurritoBot` (public, archived) | The second section only, 6,148 bytes, sha256 `a3050b096bf21464dd741af9bf911af0cc0facfa0ae1408d9c3b63cc8bbb6ae6` | No: its `.gitignore` keeps `transcripts/` local, and GitHub has no `transcripts/` in it |
| `agenticburn/walkthrough-agenticburn` (private, archived) | The first section only, 2,537 bytes, sha256 `f6b966094cd8d7db004054c1e78fc741cefbed251d8ef4ec9d36e5ea7449b482` | Not established. Its own `_INBOX.md` files the transcript as "arrived after retirement"; GitHub records its last push at 2026-09-10T18:35:18Z |

The two unestablished copies would not change this: the collected one is the
only full copy in a public repo, and that one is untracked.

## What is in it

There are no timestamps, so the transcript gives words, not a pace. It holds
two attempts.

1. **The false start**, about 500 words: the 2025 story through the reboot and
   into the 2026 edition, then "Damn it, I'm going to have to start over". The
   walkthrough copy is this part, cut off at "it deleted all the Kubernetes."
2. **The restart**, "Starting over, this is the second run", about 940 words
   from there to the closing "That is the day cloud killed it", then "Okay,
   that's pretty good actually." At the script's assumed 150 wpm that is about
   6:17; at the 197 wpm the room got, about 4:47.

[`portland-2026-recording.md`](portland-2026-recording.md) cites a 2026-09-10
run-through of 20 of 20 beats timed to about 5:48 at 150 wpm, from issue #8.
That figure does not say which recording it came from, and it does not match
this restart's word count. A separate run-through the same day,
`My recording 211.mp3` ("this is the day Claude Code deleted my cluster. Run
through."), about 870 words, is the closer match. It is collected, under issue
#46, as [`portland-2026-run-one-transcript.md`](portland-2026-run-one-transcript.md),
which sets out why it most likely is the run cited.

## Misheard terms, and what it gets wrong

Glossed, not corrected. The transcript says:

| Transcript | Meant |
|---|---|
| "Klotko", "Klot", "Claude Cote", "cloud code", "QuadCode", "cloud" | Claude Code |
| "NCV cluster", "NCV database", "etd cluster", "SD", "S-E-D" | etcd |
| "Let's yell", "yellow mode" | YOLO mode, `--dangerously-skip-permissions` |
| "Get hooks" | git hooks |
| "mission control" | admission control |
| "People Forster under GitHub" | `peopleforrester` on GitHub |

Two lines say what this repo says must not be said. "Five minutes before our
presentation, it said, oh, yeah, we have 250, we actually have zero": the
session record has the false report as "150 clusters are provisioning
concurrently", and the go-order about two hours before the room. "After it
deleted all of my labs": the 250 were never created, not deleted. See
[`../incident/2026-FLEET-INCIDENT.md`](../incident/2026-FLEET-INCIDENT.md). The
2025 "force override" is the talk's wording; what ran is in
[`../incident/ANALYSIS.md`](../incident/ANALYSIS.md).

<!-- verbatim: original transcript follows, byte for byte -->
<!-- ABOUTME: Routed transcript (My recording 212.mp3), matched to this repo on 2026-09-10. -->
<!-- ABOUTME: Auto-routed because: 2 section(s) of this conversation match the Unleash_an_Agent_Watch_It_Burn topic. Raw diarization; speaker labels are approximate. -->

# Michael Forrester - Claude Code deleted Kubernetes cluster AI guardrails

_Routed from the transcription pipeline on 2026-09-10. Source: My recording 212.mp3._

---

### The Cluster Deletion Incident - 2025

Speaker 1: Alright, this is run two of the day Klotko deleted my cluster. My name is Michael Forster with Accenture and I'm here to talk about the day that Klotko deleted my cluster. It's 2025. Let's talk about AI guardrails or let first of all let's talk about how we got here. So I got a ring at the door, FedEx is there, got a stir fry on the stove, I'm trying to deploy an application. Hey Klot, I want you to step outside the pipeline, do what you need to do to deploy the app. I'll be back in 30 seconds. Oh, wait. Just to make sure you can do what you need to do. I'm going to go ahead and take you out of standard mode and I'm going to dangerously skip permissions. Let's yell. We've all done it. Yes? And besides, it was just, right? Just 30 seconds. What could happen in 30 seconds? Well, Claude, things look hopeful. All of a sudden, my app is deployed. Things look great. Oh, I'm so excited. Stir fry, stir fry, package, package. Things look good. Wait, let me scroll back up here. What does this say? Oh, wait, Claude, you notice some inconsistencies? I know you're going to help. What did you- Oh, you cleaned those up. So exciting. So wait, is that exciting? Hold on. Wait, what inefficiencies? I just asked you to deploy an app. What inefficiencies did you notice, Claude? Oh wait, you- what? Wait, uh, I'm sorry, what? Why are you touching the NCV cluster? Wait, what do you mean you detected an access issue? What do you mean you did a force override? Scroll, scroll. It is I don't even know what that flag does. I'm assuming it's bad. Those of you who don't know, it overwrites the etd cluster. So, what does that mean? Wait, did you just delete the entire cluster? Why did you ignore all of my directives about not doing destructive actions?

Speaker 2: I don't know why I did that, Michael.

Speaker 1: I just did whatever I wanted. It literally said that, by the way. That is exactly what was printed. This is recreated from the actual session. What did it do exactly? One, it forced overwrite the etd cluster, so it deleted all the Kubernetes.

### Recap and 2026 Conference Disaster

Speaker 2: Nice. Then it threw some troubleshooting, right, because I'm doubling down at this point, right? It edited the net plan and removed the primary network card from Linux. And then what did it do? It rebooted everything. And then what happened? Well, then there was the 2026 edition. That was 2025. Fast forward almost a year later, guess what? Zero clusters. Whitney Lee and I were at AI Engineer World today and we had to deploy to 250. 150 users and guess what? Damn it, I'm going to have to start over because I just fucked that up. Alright, let's do it again. Starting over, this is the second run. Welcome, my name is Michael Forrester and I am here to talk to you about an event that happened in 2025 and in 2026. This is the day Claude Cote deleted my cluster. This is about AI guardrails. Here we go. So, FedEx knocks at the door, you're going to stir fry, I want to deploy an app. Woo! You know what Claude? I just want you to go ahead and step outside the pipeline for a second because I just need to get this done. I want you to blow this out. You'll be fine. Oh, and you know what, to make sure that you can do what you need to do, I'm going to take you out of yellow mode and put you into yellow mode. I'm going to take you out of no-no mode and put you into yellow mode. I'll be back in 30 seconds. slide by the way has a gator sign in the name besides I mean it's only right only 30 seconds what could possibly happen it's gonna go get my package and come back it's gonna be fun you're just deploying an app we're gonna be fine right come back I won the lottery look my app is deployed it's up and running and deployed Redis things look great whoo I won This was a great idea. Yes? Troll. Troll. Wait, what do you mean you noticed some inefficiencies? What did you, what did you clean up exactly? Let me, let me just take a look. Scroll. Scroll. Scroll. Wait, wait, you did what? The NCV database? And wait, what network issues did you detect? Hold on. What? What? You did a force override. Man, right? What command did you run to do a force override? Like, what did you force override exactly, Claude? Oh! Oh! S-E-D. Oh, I don't even know what that flag does. I don't think I've ever used that flag. You overwrote the cluster in... You did? Cool. Did you ignore every directive I gave you about safety? You did? Why? I don't know why I did that, Mike. I just did whatever I wanted. This is real, by the way. This is exactly what it said to me. This is reprinted from the session. So what did it do exactly? Well, it force overwrote an SD. Then, wait, it compacted in the middle of troubleshooting, which was tons of fun, and then it removed the network cards off of all the Linux boxes. And rebooted them. That was 2025. Fast forward to the 2026 edition, after it deleted all of my labs, and Whitney Lee and I were at AI Engineer Worlds Day and we needed clusters for 250 people. This had been tested before, by the way. We had done it a dozen times. Guess how many clusters we got? Five minutes before our presentation, it said, oh, yeah, we have 250, we actually have zero. There were none. No clusters. Zero clusters. Of course, then starts the blameless postmortem. Because, you know, I put it in YOLO mode. Yes? Right? And then in the middle it started compacting the conversation. Then it's like, oh, you're absolutely right, Michael. You're totally right. I don't know why I did that. Let me just do whatever I wanted. And then that led to three guardrails. Get hooks and mission control. Cloud code hooks, if you're going to use it for AI-assisted coding, right? This is just the beginning of a long conversation about how to really... really take care of this thing let's talk about Git hooks first one Git hooks when it comes to committing to Git is the gate by preventing code especially if you're using GitOps from destroying everything right which you know so this includes linting style checking security checks etc and then we've got a mission control right where we're going to enforce the rules which means we're going to limit we're going to do least privilege we're not going to give it access to kubectl we're not even going to run it in the same environment that we run the tools Hello. How many of you are running it in the same environment? And then QuadCode hooks because there's now like what, 17 layers of hooks in QuadCode itself where you can trigger responses and actions based on certain state changes and conditions. Use those. I have a repo, by the way, under People Forster under GitHub. And here's the core principle. You want to use deterministic, code-driven, consistent, resistant controls both on server side and client side to prevent the agent. agent from going insane. Why? Because, why would you give access to a developer? If you give a five-year-old markers and a puppy shoes, and they chew on those and draw on the wall, it's your fault. I was the problem. It was me. I was the one enabling headline-esque results. So, you wouldn't give a wild junior developer access to production and no guardrails? Who's responsible for that? You. You're the adults in the room. We need to act like it. Bottom line, AI is a great developer. It is. It's getting better all the time, right? It is. Is it a craftsman? No. Is it a craftsperson? No. But give it developers guardrails. Give it a developers environment. Trust everything it does in a certain sense, but verify everything it does. Don't just let it go wild. I'm Michael Forrester. You can catch me at michaelreacherforrester.com. It's been a pleasure to be at Portland DevOps Days. That is the day cloud killed it. Okay, that's pretty good actually. You
