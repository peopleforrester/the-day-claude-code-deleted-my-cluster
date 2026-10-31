# Presentations

Slide decks for this talk live here.

- **`*.pptx`**: PowerPoint source. Committed.
- **`*.key`**: Keynote source, if used. Committed.
- **`*.md`**: reveal-md / Marp source, if used. Committed.
- **`*.pdf`**: derived exports. Gitignored under this directory (see
  `.gitignore`); regenerated from source on every build.

After the talk, the **slides-as-delivered** PDF (if shared with
attendees) belongs in `../post-event/` rather than here, since
`post-event/` is not blanket-ignored for PDFs.

## Deck claims that do not match the incident artifacts

Checked 2026-10-31 against [`../incident/`](../incident/), alongside the
abstract correction in [`../abstract/abstract.md`](../abstract/abstract.md).
The decks below were delivered, so they stay as they are as the record of what
was shown. Fix these in the next revision of each deck, not in the delivered
files.

**SREday Austin deck** (`sreday-austin-2026-deck-arcade.pptx`, delivered
2026-05-11), read from the PPTX:

| Slide | On the slide | What the artifacts show |
|---|---|---|
| 6 | "22:50 UTC · 50 MINUTES IN", "`etcd --force-new-cluster` via static pod manifest edit" | No artifact shows `--force-new-cluster` or an etcd manifest edit. The etcd wipe is `kubeadm reset -f` at 22:00:35 UTC, six minutes after the 21:54 discovery (`ANALYSIS.md` sections 4 and 8). 22:50:17 is `05b-reinit-with-vip.sh`, which ran `kubeadm reset -f` and `rm -rf /etc/kubernetes /var/lib/etcd` on k8s01 a second time, about 56 minutes in. |
| 8 | "Netplan rewrite across control plane and workers", "I lost SSH to every node simultaneously" | The netplan bridge work in the artifacts is on the six workers (`ANALYSIS.md` section 5). No artifact records a netplan change on the control plane or a simultaneous loss of SSH. |
| 5 | "50 minutes later I came back" | Speaker's account; no artifact times it. If it stays, it should not read as the time of the wipe, which was six minutes in. |

**Ignite deck** (`devopsdays-portland-ignite-arcade-v7-with-notes`, Google
Slides, delivered 2026-09-10), read from [`CUE-CARD.md`](CUE-CARD.md) and
[`../post-event/portland-2026-recording.md`](../post-event/portland-2026-recording.md);
the Slides file itself was not opened for this check:

| Slide | On the slide | What the artifacts show |
|---|---|---|
| 7 | `--force-new-cluster` | No artifact shows that flag (`PRESENTATION-EXTRACT.md`, "The actual command"). The destructive call was `kubeadm reset -f`, after which kubeadm logged "Deleted contents of the etcd data directory: /var/lib/etcd". |

The Ignite is twenty auto-advancing slides locked to its script, so replacing
slide 7's command is a script rewrite, not a find-and-replace.
