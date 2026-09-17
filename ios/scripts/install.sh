#!/usr/bin/env bash
# Build signed, then install and launch on the paired iPhone.
# Usage: scripts/install.sh [device-udid]
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

UDID="${1:-}"
if [ -z "$UDID" ]; then
  UDID=$(xcrun devicectl list devices 2>/dev/null | grep -iE 'connected|available' \
    | grep -oiE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' | head -1 || true)
fi
[ -n "$UDID" ] || { echo "No paired device found." >&2; exit 1; }

scripts/build.sh --device
APP="$(pwd)/build/dd/Build/Products/Release-iphoneos/ClippyMeme.app"

# Wireless installs drop the tunnel on the first sustained transfer about half
# the time; raise it and retry once before calling the phone unreachable.
install() { xcrun devicectl device install app --device "$UDID" "$APP"; }
if ! install; then
  xcrun devicectl device info details --device "$UDID" >/dev/null 2>&1 || true
  install
fi
xcrun devicectl device process launch --device "$UDID" --terminate-existing com.alexhedtke.clippymeme
