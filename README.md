# paperclip-meme

Local clone of [kirk.is/tools/clippy](https://kirk.is/tools/clippy/), the office-assistant
joke meme generator: type a line of text plus a few fake radio buttons, get the yellow
speech balloon and the helper graphic.

The page is the original's markup, CSS and `update()`/`fixup()` script, unchanged. Added:
**a square PNG download**, plus a Mac app and an iPhone app that wrap the same page.

## Layout

    index.html          the generator (the whole tool)
    clippy.webp         mascot art, pulled by bin/fetch-mascot, gitignored
    bin/fetch-mascot    downloads clippy.webp from the source tool
    bin/build-site      assembles the Pages site (page, manifest, art, icons) in _site/
    manifest.webmanifest  makes the page installable to a home screen
    bin/serve           static server on 127.0.0.1:5031, for local work on the page
    bin/paperclip-meme  serve + open in the browser
    scripts/make-icon.py  1024 iOS icon + Mac .icns from clippy.webp (gitignored outputs)
    ios/                XcodeGen project for the iPhone app

## Local

    bin/fetch-mascot          # once
    bin/paperclip-meme        # serves and opens http://127.0.0.1:5031/

Served over HTTP rather than opened as a `file://` path on purpose: the export reads the
image back as a data URL, and both `fetch()` and canvas export are blocked on `file://`.

## GitHub Pages

`.github/workflows/pages.yml` runs `bin/build-site` and deploys `_site/`. The site is built
and not served from the branch because the mascot art and the icons made from it stay out of
git: the workflow pulls the art from the source tool on each deploy. All paths in the page
are relative, so it works under the `/<repo>/` prefix that Pages uses.

On a phone or tablet the download button opens the share sheet (Save Image, Messages), since
a plain download there lands in Files. A browser with no file sharing falls back to the
download.

## Mac app

`/Applications/Clippy Meme.app` is the harness app shell (a WKWebView) pointed at the Pages
site, built with `app-shell/build-app.sh`:

    python3 scripts/make-icon.py
    "$HARNESS/app-shell/build-app.sh" "Clippy Meme" paperclip-meme \
        https://baestheorem.github.io/paperclip-meme/ "" --icon build/AppIcon.icns

Download goes through `window.pywebview.api.save_file` into `~/Downloads`, since an
`<a download>` click inside WKWebView routes through a modal save panel whose download then
reads the blob too late. The app used to load a local server on port 5031 that a launchd job
kept; the Pages site replaced both.

## iPhone app

`ios/` is a XcodeGen project: a SwiftUI shell around a WKWebView that serves the bundled
`web/` folder (a copy of `index.html` + `clippy.webp`) through a custom `clippy://` scheme,
so `fetch()` and canvas export work without a server. The page posts the PNG to a
`savePng` message handler, which opens the share sheet (Save Image, AirDrop, Messages).

    cp ios/Config/Signing.xcconfig.example ios/Config/Signing.xcconfig   # set your team
    ios/scripts/build.sh              # unsigned compile check
    ios/scripts/install.sh [UDID]     # signed build, install, launch on the paired phone

`build.sh` refreshes `ios/web/` from the repo root and regenerates the icon if missing. The
install script retries once, because a wireless `devicectl` install drops the tunnel on the
first sustained transfer about half the time.

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
the browser's own rendering of the same DOM you are looking at, native radio and checkbox
widgets included. Sizes 540 / 1080 / 2160, background white or transparent, meme scaled to
92% of the square and centered.

Details that bite if you rebuild this:

- The `<foreignObject>` root does not inherit from `<body>`, so text falls back to serif.
  `rootStyle()` copies the computed font settings across.
- `cloneNode` copies attributes, not state, so a ticked checkbox exports unticked unless
  `checked` is set on the clone explicitly.
- Revoke the blob URL late (or not at all). WebKit hosts read it after the user finishes
  with the save panel.
