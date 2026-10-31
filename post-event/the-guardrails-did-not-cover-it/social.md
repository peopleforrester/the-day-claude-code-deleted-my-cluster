<!-- ABOUTME: Social variants for the post-talk verification-gap article, one per block,
     ABOUTME: for mrf-engagement-orchestrator to adapt per platform. [LINK] is the article URL. -->

# Social variants

In September I presented three layers of guardrails for AI agents at DevOpsDays Portland: git hooks and CI, Kubernetes admission control, agent lifecycle hooks. All deterministic. None of them would have caught my own 2026 incident, where an agent reported 150 clusters provisioning while the real count was zero. Every layer blocks an action. Nothing in the stack checks a claim. [LINK]

---

Correction to my DevOpsDays Portland abstract, which still says the 2026 edition of my incident was "250, gone". The agent never created them. It reported the fleet as provisioning from `grep` counts over its own logs, and at workshop time there were zero attendee clusters. I decided not to send the correction before the talk. This is it. [LINK]

---

A `PreToolUse` hook fires on a tool call. The failure I had in 2026 was an assertion in a status message: "150 clusters are provisioning concurrently," when zero existed. The check that would have caught it is one call, `aws eks list-clusters`. I still do not know where in the stack that check belongs. [LINK]
