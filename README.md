# paperclip-meme

Local clone of [kirk.is/tools/clippy](https://kirk.is/tools/clippy/), the office-assistant
joke meme generator: type a line of text plus a few fake radio buttons, get the yellow
speech balloon and the helper character.

Added here: **the result downloads as a square PNG**, so it goes straight into a chat,
a post, or a slide without cropping a screenshot.

## Run

    bin/fetch-mascot          # once: pulls the mascot art and inlines it
    bin/paperclip-meme        # opens index.html in the browser

No build step, no server, no dependencies. One HTML file plus the mascot, works over
`file://` or from any static host.

`assets/` is gitignored: the art is pulled from the original tool for local use, not
redistributed here. `bin/fetch-mascot` downloads `clippy.webp` and writes
`assets/mascot.js`, which sets `window.MASCOT_URL` to a base64 data URL. The data URL
matters: an `<img>` loaded from a `file://` path taints the canvas and breaks PNG export,
a data URL does not. Without `assets/`, the generator falls back to a paperclip drawn in
code.

## Syntax

The textarea is the whole input:

    It looks like you are about to make a horrible life decision.

    Would you like help?

    * Reconsider my options
    * Construct a transparent rationalization
    * Learn to live with regret
    _ Don't show me this tip again

- `*` at the start of a line draws a radio button
- `_` draws a checkbox
- blank lines are vertical spacing
- everything else is plain text, wrapped to the balloon width

## Differences from the original

| | kirk.is | here |
|---|---|---|
| output | HTML you screenshot | square PNG download (540 / 1080 / 2160) |
| renderer | DOM | canvas, so preview and export are the same code path |
| background | page white | white, black, or transparent |
| mascot | bundled image | same art, inlined as a data URL, or load your own with the file picker |

To use different art, pick any image file. It is read as a data URL too, so the canvas
stays untainted and export keeps working offline.

## Layout knobs

All the geometry is fractions of the canvas edge, in the `CFG` object near the top of the
script: balloon width, padding, font size, line height, option indent, mascot width. Change
a number, reload, done.
