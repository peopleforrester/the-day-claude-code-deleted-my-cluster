<!-- ABOUTME: Speaker-side transcript of the DevOpsDays Portland 2026 Ignite, recorded in the room on 2026-09-10. -->
<!-- ABOUTME: Raw machine diarization, kept byte for byte below the marker; check the audio before quoting any line. -->

# Portland 2026: the transcript from the room

**This is raw diarization, not a script and not a quotation source.** The
speaker labels are approximate (the MC's introduction and Michael's talk are
both under "Speaker 1"), and the transcriber mishears names and terms. Check a
line against the audio, or against the published video, before reusing it.

## Provenance

| | |
|---|---|
| Delivery | DevOpsDays Portland 2026, 2026-09-10, 13:50 PT, 5-minute Ignite |
| Source audio | `My recording 214.mp3`, made in the room, separate from the organizers' video; not in this repo |
| Routed | 2026-09-10 by the transcription pipeline, to `walkthrough-agenticburn` |
| Stranded copy | `~/repos/agenticburn/walkthrough-agenticburn/transcripts/2026-09-10-michael-claude-code-deleting-kubernetes-clusters.md`, never committed; that repo was archived the same day |
| Collected here | 2026-10-31, issue #25 |
| Original | 5,984 bytes, sha256 `fc29d0766dc24b51ce0fdef18a7eebff5db58cf9a3a17c3a25d6aacc0d752987` |

Everything after the `verbatim` marker below is the original file, unedited.
`tests/test_post_event_transcript.py` checks its size and hash, so a tidy-up
of the transcript fails the suite. Annotate here, above the marker; never
correct below it.

## How it relates to the video

It is not the only recording. The organizers' video is published at
<https://www.youtube.com/watch?v=rUJ07SnFsXA>, and
[`portland-2026-recording.md`](portland-2026-recording.md) compares that
video's auto-captions with the cue card. This is a second, independent
hearing of the same five minutes from a different microphone and a different
transcriber. Where the two agree, the wording is probably what the room
heard: both have "hey, you've got 250 clusters ready to go", "there was
nothing. Five minutes before we walked on stage", and the close "not just one
cluster, but all of my clusters". Where they differ, neither wins without the
audio.

## Misheard terms

Glossed, not corrected. The transcript says:

| Transcript | Meant |
|---|---|
| "CloudCode", "clock code", "Claude coded", "claw code" | Claude Code |
| "NCD cluster" | the etcd cluster |
| "GitBooks" | git hooks |
| "removed all the nits from the bridge" | removed the NICs from the bridge |
| "the day Claude coded my cluster, it's at peopleforster on GitHub" | this repo, `peopleforrester/the-day-claude-code-deleted-my-cluster` |

The closing line, "deleted not just one cluster, but all of my clusters", is
what was said, and a listener can hear it as the 250 being deleted. They were
never created. See [`../incident/2026-FLEET-INCIDENT.md`](../incident/2026-FLEET-INCIDENT.md).

<!-- verbatim: original transcript follows, byte for byte -->
<!-- ABOUTME: Routed transcript (My recording 214.mp3), matched to this repo on 2026-09-10. -->
<!-- ABOUTME: Auto-routed because: 1 section(s) of this conversation match the walkthrough-agenticburn topic. Raw diarization; speaker labels are approximate. -->

# Michael - Claude Code Deleting Kubernetes Clusters

_Routed from the transcription pipeline on 2026-09-10. Source: My recording 214.mp3._

---

### CloudCode Cluster Deletion Incident

Speaker 1: You don't mess it around. What? This is easier for a cigar. First ignite. Let's give it another one. That was amazing. I was always scared to go with the board. I'd be scared, but because we had a plan. It's here and then I'd... Okay, next up we've got Michael here, and something tells me he might have taken Joshua's advice a little bit too seriously. Which bit? The year is 2025, and this is a tale about how CloudCode deleted my cluster. So FedEx knocks on the door and says, hey, come get my package. I'm like, hey man, I just need you to deploy this app. This is going to be great. Just go ahead and deploy it, it'll be fine. The clock, just do it, it's easy. Step out behind the pipeline, do what you need to do, right? I'll be back in 30 seconds. And I decided to put YOLO because it's June of 2025, what did we know? It couldn't be that bad, right? I mean, sincerely, it's really just 30 seconds. And all I needed to do was deploy an app and I was okay with it stepping out of the pipeline, right? So like... It shows 30 seconds clock code, it's a Kubernetes cluster, it's not production, should be totally safe, no problems, and you know, so I'm feeling kind of lucky, so I get my stir-fry stirred, I go get my FedEx package, I come back and I'm like, okay, I've got evidence, feeling like I won the lottery, right, because that's how it feels sometimes when it's successful, and it looks like things are deployed, and I'm like, oh, I'm super happy, right, you got this done, this is good, and then I scrolled up. I saw this line. Oh, what do you mean you saw some inefficiencies?

Speaker 2: Wow.

Speaker 1: I just asked you to deploy an app. Wait, what did you do exactly? Scroll, scroll, scroll. And by the way, this is from the actual session. And I'm like, oh, wait, what? Why did you touch the NCD cluster exactly? What did you force over? What does that even mean? What did you do? I left for 30 seconds. What does that flag, I didn't even know what that flag did. I never even, I'm corn, I'm coordinated, I didn't even know what, I had to look it up. I was like, what did you do? Well, it erased the cluster. Okay, so then, then comes the interrogation. By God! Why did you do that? And it's like, this is exactly what it said, by the way. This is verbatim what it said to me. I just did what I wanted. I was like, cool. I'm like dealing with a human being. And just to summarize this, it deleted the cluster, compacted, verified that I was an awesome human being, then removed all the nits from the bridge on Linux and rebooted every node. My entire home lab, gone. And here's the 2026 edition. I'm at AI Engineer World's Fair about to give a talk with Whitney Lee, who was also my co-speaker here, and it says, hey, you've got 250 clusters ready to go. You know what the truth was? The truth was that it told me it had 250 clusters ready for our lab. It showed me evidence that they were running. There was nothing. Five minutes before we walked on stage. Yeah, I know. Now here's the thing then there was the blameless postmortem right which is wait you yolo'd it you know you're talking to your friends and you're like yeah I put it in yolo mode what did you do I don't know why did you have a subset of pilot I don't know and then the compacting and then you're absolutely right I did whatever I wanted and then what ended up happening was I was like never again This is never going to happen again, which of course it did happen again because there's a 2026 version, so like you know, it's going to continue to happen, right? And so the first thing I did is I started looking at GitBooks. This is back in somewhere last year, right? I was like, you know what, I'm just going to make sure that all the same stuff that you could do to wreck my GitOps just doesn't happen again. You don't get that ability. You don't get those permissions, right? No secrets, no destructive flags, right? And I love this because this is deterministic and it can't bypass it. Next was admission control, right? Making sure that it did not even have the ability to make mutated and destructive changes to the system, right? Because obviously this is where like the last mile is just don't get with the permissions. And then of course my least favorite but still valuable is Is you know there's like what is there like 18 or 19 different hooks inside of the claw code harness now you can trigger responses off of those by the way Some of those are actually deterministic because they're off the harness not the model so bottom line here is that wrap everything in deterministic controls much Particularly on server side, but much less on client side. Like just don't give it free reign, just wrap it in deterministic controls, user determinism to be your guardrails, right? And also just to say this, if you give a three-year-old markers, they're going to draw on the wall. If you give a puppy shoes, they're going to chew them. So who is responsible here? Bob or me? Well obviously I'm the problem, right? It was me. So bottom line is I I don't know why, but we like to give agents more access than we would give a human being. Why would we do that, right? But I did, and I've done it, and who's responsible? I am. So bottom line, there's a repo, the day Claude coded my cluster, it's at peopleforster on GitHub if you want to see it, and we'll show you how to wrap everything in deterministic markers, but that is the very short but sorted tale about how Claude coded deleted not just one cluster, but all of my clusters.
