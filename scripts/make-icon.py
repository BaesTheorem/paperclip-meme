#!/usr/bin/env python3
"""Compose the app icons from clippy.webp.

Writes the 1024 opaque PNG the iOS asset catalog wants and an .icns for the
Mac app. Both are derived from the gitignored art, so they are gitignored too;
run this after bin/fetch-mascot.

Rules that matter (learned on the Study Bible icon):
  * iOS masks with its own superellipse, so the artwork is a full-bleed opaque
    square. No baked-in rounded corners.
  * No alpha in a home-screen icon; paint the background explicitly.

Run from the repo root:  python3 scripts/make-icon.py
"""

import shutil
import subprocess
import tempfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "clippy.webp"
IOS_PNG = ROOT / "ios/ClippyMeme/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png"
MAC_ICNS = ROOT / "build/AppIcon.icns"

SIZE = 1024
BACKGROUND = (238, 238, 119)  # the balloon's #EEEE77
COVERAGE = 0.80


def compose() -> Image.Image:
    art = Image.open(SOURCE).convert("RGBA")
    bbox = art.getbbox()
    if bbox:
        art = art.crop(bbox)
    scale = (SIZE * COVERAGE) / max(art.width, art.height)
    art = art.resize((round(art.width * scale), round(art.height * scale)), Image.LANCZOS)
    canvas = Image.new("RGB", (SIZE, SIZE), BACKGROUND)
    canvas.paste(art, ((SIZE - art.width) // 2, (SIZE - art.height) // 2), art)
    return canvas


def write_icns(icon: Image.Image) -> None:
    with tempfile.TemporaryDirectory() as tmp:
        iconset = Path(tmp) / "AppIcon.iconset"
        iconset.mkdir()
        for px in (16, 32, 128, 256, 512):
            icon.resize((px, px), Image.LANCZOS).save(iconset / f"icon_{px}x{px}.png")
            icon.resize((px * 2, px * 2), Image.LANCZOS).save(iconset / f"icon_{px}x{px}@2x.png")
        MAC_ICNS.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(["iconutil", "-c", "icns", str(iconset), "-o", str(MAC_ICNS)], check=True)


def main() -> None:
    if not SOURCE.exists():
        raise SystemExit("clippy.webp is missing; run bin/fetch-mascot first")
    icon = compose()
    IOS_PNG.parent.mkdir(parents=True, exist_ok=True)
    icon.save(IOS_PNG, "PNG")
    write_icns(icon)
    print(f"wrote {IOS_PNG.relative_to(ROOT)} and {MAC_ICNS.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
