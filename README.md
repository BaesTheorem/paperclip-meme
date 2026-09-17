# paperclip-meme

Local clone of [kirk.is/tools/clippy](https://kirk.is/tools/clippy/), the office-assistant
joke meme generator: type a line of text plus a few fake radio buttons, get the yellow
speech balloon and the helper graphic.

The page is the original's markup, CSS and `update()`/`fixup()` script, unchanged. One
thing is added: **a square PNG download**, so the result goes straight into a chat, a post,
or a slide without cropping a screenshot yourself.

## Run

    bin/fetch-mascot          # once: downloads clippy.webp from the source tool
    bin/paperclip-meme        # serves on 127.0.0.1:5031 and opens it

Served over HTTP rather than opened as a `file://` path on purpose: the export reads the
image back out as a data URL, and both `fetch()` and canvas export are blocked on `file://`
origins. `clippy.webp` is gitignored, so the art stays a local copy.

## Syntax

The textarea is the whole input, exactly as upstream:

    It looks like you are about to make a horrible life decision.

    Would you like help?

    * Reconsider my options
    * Construct a blatently transparent rationalization
    * Learn to live with regret
    _ Don't show me this tip again

`*` draws a radio button, `_` a checkbox, everything else is a plain line.

## How the export works

The meme is laid out by the browser, not redrawn. On download, the `#shot` subtree is
cloned, the image is swapped for a data URL, the page's stylesheet is inlined, and the
whole thing is serialized into an SVG `<foreignObject>` and drawn to a canvas. The PNG is
the browser's own rendering of the same DOM you are looking at, down to the native radio
and checkbox widgets.

Two details that bite if you rebuild this:

- The `<foreignObject>` root does not inherit from `<body>`, so text falls back to serif.
  `rootStyle()` copies the computed font settings across.
- `cloneNode` copies attributes, not state, so a ticked checkbox exports unticked unless
  `checked` is set on the clone explicitly.

Sizes are 540 / 1080 / 2160, background white or transparent. The meme is scaled to 92% of
the square and centered.

Tested in Chromium. Safari's handling of `foreignObject` in an SVG image has historically
been patchy; if the export comes out blank there, use Chrome.
