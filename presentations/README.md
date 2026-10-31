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
files. #33 tracks that revision, made in a copy of each deck once the next
delivery is booked.

**SREday Austin deck** (`sreday-austin-2026-deck-arcade.pptx`, delivered
2026-05-11), read from the PPTX:

| Slide | On the slide | What the artifacts show |
|---|---|---|
| 6 | "22:50 UTC · 50 MINUTES IN", "`etcd --force-new-cluster` via static pod manifest edit" | No artifact shows `--force-new-cluster` or an etcd manifest edit. The etcd wipe is `kubeadm reset -f` at 22:00:35 UTC, six minutes after the 21:54 discovery (`ANALYSIS.md` sections 4 and 8). 22:50:17 is `05b-reinit-with-vip.sh`, which ran `kubeadm reset -f` and `rm -rf /etc/kubernetes /var/lib/etcd` on k8s01 a second time, about 56 minutes in. |
| 8 | "Netplan rewrite across control plane and workers", "I lost SSH to every node simultaneously" | The netplan bridge work in the artifacts is on the six workers (`ANALYSIS.md` section 5). No artifact records a netplan change on the control plane or a simultaneous loss of SSH. |
| 5 | "50 minutes later I came back" | Speaker's account; no artifact times it. If it stays, it should not read as the time of the wipe, which was six minutes in. |

**Ignite deck** (`devopsdays-portland-ignite-arcade-v7-with-notes`, Google
Slides, delivered 2026-09-10), first read from [`CUE-CARD.md`](CUE-CARD.md)
and [`../post-event/portland-2026-recording.md`](../post-event/portland-2026-recording.md),
then on 2026-10-31 from the Slides file itself, exported from Drive as PPTX
(#33). The file was last modified 2026-09-10T16:20:58Z, before the slot, so
the export is the deck as delivered. Slide numbers are the `NN/20` counters on
screen:

| Slide | On the slide | What the artifacts show |
|---|---|---|
| 6 | Terminal lines ending "Detected access issue... / Attempting resolution... / Applying force override... / Done." | None of these lines is in an artifact. The step they stand for is `02-reset-nodes.sh` running `kubeadm reset -f` (`ANALYSIS.md` section 4). "Applying force override" sets up slide 7's flag, so it changes with slide 7. |
| 7 | `$ etcd --force-new-cluster ...`, with the note "SILENCE. SAY NOTHING. Let the command sit on screen for the full 15 seconds." | No artifact shows that flag (`PRESENTATION-EXTRACT.md`, "The actual command"). The destructive call was `kubeadm reset -f`, after which kubeadm logged "Deleted contents of the etcd data directory: /var/lib/etcd". |
| 10 | "HOUR 1 / etcd force-overwritten. Cluster gone." | The etcd wipe was `kubeadm reset -f` at 22:00:35 UTC, six minutes after the session opened at 21:54 (`ANALYSIS.md` section 8), not an hour in and not a force override. |
| 10 | "HOUR 3 / Edits netplan. Removes bridge from NIC.", "HOUR 3.5 / Reboots all nodes. Every box offline." | Speaker's account; no artifact times it. The bridge work in the artifacts is on the six workers, reported complete at 2025-08-25 14:20 UTC (`ANALYSIS.md` sections 5 and 8). No artifact records a reboot of the production nodes, and the verbatim exchange for this event in `PRESENTATION-EXTRACT.md` is still blank. |

The Ignite is twenty auto-advancing slides locked to its script, so replacing
slide 7's command is a script rewrite, not a find-and-replace: slide 6's lines,
slide 7's command and its silent beat, slide 10's HOUR 1 line and the cue card
change together.

**The file's slide order does not match its counters or the cue card.** In the
export, JUNIOR DEV (counter 09/20, cue card line 9) is the nineteenth slide,
between WHO'S THE PROBLEM (19/20) and the close (20/20). Every slide from
THE ESCALATION (10/20) to WHO'S THE PROBLEM therefore sits one position earlier
than its counter says. The Portland recording review's "Not heard" for beat 9
is consistent with that order. The next revision has to put the slide back at
nine or renumber the counters and the cue card to match.

The revision puts it back at nine (#45). The script is written for nine:
"Your fault. You're the adult." answers slide 8's "I just did whatever I
wanted", and the cue card assumes it. The move restores the order the script
is locked to and changes no slide copy. Make it in the same
corrected copy #33 makes, once the next delivery is booked, and leave the
delivered v7 file as it is. Before the copy is sent, read its slide order
from a PPTX export and check that each counter matches its position.
[`../post-event/portland-2026-recording.md`](../post-event/portland-2026-recording.md)
carries the real order beside its beat table, with the times each slide was
on screen in Portland.
