<!-- ABOUTME: Arcade artwork for the Portland v6 Ignite deck, with the provenance
     ABOUTME: and intended placement for each piece. -->

# Deck artwork

Original artwork, produced 2026-09-03 with the `image-gen` skill
(`gemini-3-pro-image`) using the deck's measured palette in the prompt. No
scraped or third-party meme imagery: a public talk about being careful should be
able to source its own art, and a borrowed reaction image has no rights trail.

| File | For | Notes |
|---|---|---|
| `p13-continue-sprite.png` | Slide 13, the post-mortem | Burning server rack, a calm pixel figure beside it, `CONTINUE? 9 8 7`. Sized for the empty right column inside the terminal box. |
| `p13-mockup.png` | Reference only | The sprite composited into slide 13 at the intended size and position. Not for the deck itself. |
| `gameover-fullbleed-alt.png` | Unused alternative | A full-bleed `GAME OVER / CONTINUE?` screen. Rejected: slide 13 already carries a title, a five-item list and two captions, so a full-bleed image would have to replace them. |

## Palette

Read off the live deck, not guessed.

| Role | Hex |
|---|---|
| Background | `#0A0A0A` |
| Terminal box fill | `#1F1A0A` |
| Neon green (`1UP`, Level 1 bar) | `#39FF14` |
| Amber (Level 3 bar, titles) | `#FFE500` |
| Red (`30`, `0`, Level 2 bar) | `#FF1744` |
| Orange (accents, `EVERY MEME`) | `#FF6B00` |
| Off-white (subheads) | `#E8E8FF` |

## Why a sprite and not a meme image

The deck's meme payload is already the contributing-factors list on slide 13,
quoted from the incident. Those land harder than a borrowed reaction image
because they are receipts. The sprite adds a visual beat in the deck's own idiom
and fills dead space, without spending a slide from a fixed twenty.

`CONTINUE? 9 8 7` is the joke that belongs to this story rather than to the
genre: the incident is a sequence of decisions to keep going after each failure.

## Placed on the live deck, 2026-09-03

`p13-continue-sprite-transparent.png` is on slide 13 as image object
`img_1788449928703324614`. The olive background was knocked out to alpha and the
fully transparent margins trimmed, so the terminal box's own fill shows through
and the given x/y/width map to the artwork itself rather than to padding.

```bash
gog -a michaelrishiforrester@gmail.com slides insert-image \
    1e8pZupiww6PlAjrMMhU22vCJsN_e9zmmrd5rp-OmA54 p13 \
    presentations/assets/p13-continue-sprite-transparent.png \
    --x 465.8 --y 114.8 --width 153.0 --height 120.5 --unit PT
```

The slide is 720 by 405 PT, so a position measured on a 1600 by 900 render
converts at 0.45. `insert-image` takes a local file, and `--unit` accepts PT or
EMU.

Slide 13's notes carry a cue not to explain the sprite or read it aloud. It is a
visual aside; the joke is that all five contributing factors were decisions to
keep going.
