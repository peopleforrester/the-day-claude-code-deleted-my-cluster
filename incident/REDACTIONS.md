# Redactions in this tree

The artifacts under `session-artifacts/` are recovered verbatim from git history,
with two deliberate exceptions. Credential **values** have been replaced with
`<REDACTED-...>` markers, counted in the table below. And the lines that name a
path under `/tmp` carry one fixed trailing comment, described under
[Annotations](#annotations). Structure, filenames, commands, and everything that
carries evidentiary weight are untouched.

| What | Count |
|---|---|
| Kubernetes service-account JWTs | 7 |
| kubeadm join tokens | 28 |
| Hardcoded password, token, and secret assignments | 27 |
| kubeconfig client private keys (`client-key-data`) | 1 |
| kubeadm certificate keys (`--certificate-key`, `certificate_key`, `CERT_KEY=`) | 12 |
| HAProxy stats basic-auth passwords | 6 |

Each row counts `<REDACTED-...>` markers in the tree, and
`tests/test_redactions.py` holds the table to them.

Left in place on purpose, because they are public material rather than
credentials: `--discovery-token-ca-cert-hash` values (hashes of the cluster CA's
public key), `certificate-authority-data` and `client-certificate-data` (the
certificates, without their keys), and container image digests.

The last three rows were missed by the first pass. The monthly security scan of
2026-10 (`peopleforrester/infrastructure-security-scanning#129`) found them, and
they were redacted on 2026-10-31 (#26). The first pass had redacted the token
beside each certificate key and left the key.

## Annotations

**133 lines in 37 files** end with this comment, added on 2026-11-15 (#48):

`# tmp-ok: incident evidence, command kept as recovered`

The house rule since November 2026 is that no script writes to the system
`/tmp`; each repo keeps its temp files in its own git-ignored `tmp/`, and a
check (`sk-tmp-check`) reads every tracked shell and Python file for a path
under `/tmp`, `/var/tmp` or `/dev/shm`. A line that has to keep such a path says
why with `tmp-ok: <reason>` on that line. These scripts are what the agent
wrote and ran in 2025, so the paths stay and each line says why.

Nothing else on those lines changed. Remove the comment, two spaces before the
`#` included, and the line is the recovered one byte for byte.
`tests/test_tmp_waivers.py` holds the count, the exact form of the comment, and
a digest of the 133 recovered lines with their positions.

On 105 of the lines the comment is an ordinary comment in the script itself,
and bash parses the file to the same commands as before. The other 28 sit
inside a quoted string or a heredoc opener that the script hands to `ssh`, so
the comment travels with the command text and is a comment to the remote shell
instead. It holds no quote, `$` or backslash, so it cannot close the string or
expand. The commands that run are the same either way; the text sent over
`ssh` on those 28 lines is longer by the comment.

Two lines the check also reports are left exactly as recovered, because they
name no path: a bare `mktemp -d` at line 34 of both copies of
`install-kube-vip.sh`. A bare `mktemp` follows `$TMPDIR`, and the check lists
it as a different kind of finding.

## Why, given the credentials are dead

They are. The cluster these belong to was destroyed in August 2025 and rebuilt
that September, so every token here authenticates against something that no longer
exists.

The redaction is not risk management. It is the repo practicing what the talk
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
