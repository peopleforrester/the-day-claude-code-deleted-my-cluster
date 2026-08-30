# Redactions in this tree

The artifacts under `session-artifacts/` are recovered verbatim from git history,
with one deliberate exception: credential **values** have been replaced with
`<REDACTED-...>` markers. Structure, filenames, commands, and everything that
carries evidentiary weight are untouched.

| What | Count |
|---|---|
| Kubernetes service-account JWTs | 7 |
| kubeadm join tokens | 28 |
| Hardcoded password, token, and secret assignments | 30 |

## Why, given the credentials are dead

They are. The cluster these belong to was destroyed in August 2025 and rebuilt
that September, so every token here authenticates against something that no longer
exists.

The redaction is not risk management. It is the repo practising what the talk
argues. A talk about deterministic controls that ships live-looking credentials in
its own evidence undercuts itself, and the reader cannot tell a dead token from a
live one by looking. Redacting is the cheap deterministic control, applied to the
one artifact set most likely to be read closely.

## If you need an original

The unredacted tree is public in
`peopleforrester/DevOpsDaysAtlanta_2026_Cluster_Destruction_Ignite` under
`presentation-recovery/session-artifacts/`, where it has been since 2026-04-20.
Nothing here is being hidden; it is being presented deliberately.

## For the deck

This is a talk beat, not just a repo note. The evidence for a talk about agents
destroying infrastructure was itself published with cluster credentials in it, by
the person giving the talk, and sat that way for eighteen weeks. That is the same
class of failure the talk is about: a thing that looked finished, was not checked,
and nobody noticed because nothing failed loudly. Consider it for the closing,
where the argument is that you cannot rely on catching this by being careful.
