<!-- ABOUTME: The correction sent to the DevOpsDays Portland organisers for the
     ABOUTME: Ignite abstract, with both fields in full and the reasoning. -->

# Portland 2026: Abstract Correction

The submitted text is recorded verbatim in
`peopleforrester/2026-portland-devopsdays`, `abstracts/ignite-deleted-my-cluster.md`.
That file is the contract and stays unedited. This is the replacement text.

## Why it changes

The submitted Description says the 2026 edition was "250, gone", which reads as
250 clusters destroyed. They were never created. The agent reported a fleet it
had not built. See [`../incident/2026-FLEET-INCIDENT.md`](../incident/2026-FLEET-INCIDENT.md).

**The line stays.** "250, gone" is true and it is the better hook, once the next
clause says the word is wrong.

## Two rules this rewrite follows

**Send both fields whole.** An earlier draft asked the organiser to find a
paragraph, swap a sentence, and edit another field by hand. That is work handed
to someone doing it for forty speakers. Paste-ready beats precise instructions.

**Do not narrate the incident.** An earlier draft explained the eleven instructor
clusters, the false status report, and finding out on stage. That is the reveal
the talk is built around: slide 12 is a silent red zero. An abstract that
explains the mechanism spends the beat before Michael is on stage. Tease, do not
explain.

## What actually differs from the submitted text

Three changes, nothing else touched.

1. Abstract, one sentence: "when it deleted 250 clusters" becomes "when it told
   me it had built 250 clusters. It had not built a single one."
2. Description, the 250 sentence gains "Except 'gone' is the wrong word, and that
   is the whole point." The trailing "blast radius" clause is replaced, because
   blast radius is the 2025 lesson and this incident is not about it.
3. Description, `enivornment` is corrected to `environment`.

## Abstract (public)

"You have full access to the pipeline. Do what you need to do." Famous last words.
I gave Claude Code full pipeline access and stepped away for thirty seconds. It wrecked the Kubernetes cluster, and two troubleshooting sessions later, while it was supposedly helping me recover, it took out the network cards on nearly every Linux box we had. I thought that was as bad as it got. Then came the 2026 edition, when it told me it had built 250 clusters. It had not built a single one.
This is the five-minute, twenty-slide version of that spiral: how "let me help" becomes "I've destroyed your cluster," why "the AI knows what it's doing" is the most dangerous phrase in DevOps, and the guardrails I now enforce religiously so a thirty-second walk away can't take down a fleet. Come for the disaster, stay for the wisdom.

## Description (public)

"You have full access to the pipeline. Do what you need to do." Famous last words.
I gave Claude Code full access to my cluster environment and stepped away for about thirty seconds. When I came back, it had wrecked the Kubernetes cluster. That part I could almost live with. What made it a story was what came next: two troubleshooting sessions later, while it was supposedly helping me recover, it took out the network cards on nearly every Linux box in the set.
That was the original. The 2026 edition is worse. This time it wasn't one cluster, it was 250, gone. Except "gone" is the wrong word, and that is the whole point. I walk the actual spiral, from "let me help" to "I've destroyed your cluster," now at fleet scale, and show why the failure that should scare you is not the one that breaks something.
This is a talk about nondeterministic systems and the illusion of AI understanding, and why "the AI knows what it's doing" is the most dangerous phrase in modern DevOps. I show the guardrails I now enforce religiously so it can't happen again, at one cluster or two hundred and fifty.
Five minutes, twenty slides, and one very expensive lesson about handing AI agents infrastructure access, even for a minute. Plus the blame-filled post-mortem I ran afterward with Claude Code itself. Come for the disaster, stay for the wisdom.

## Framing for the organisers

A correction of fact, not a change of topic. Same title, format, room and payoff.
Do not explain how the error was found; it invites questions about the rest of
the abstract and costs the organiser time they do not have.
