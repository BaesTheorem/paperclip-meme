#!/usr/bin/env bash
# Build the iOS app. Pass --device for a signed build, otherwise an unsigned
# compile check.
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
command -v xcodegen >/dev/null 2>&1 || PATH="/opt/homebrew/bin:$PATH"

[ -f Config/Signing.xcconfig ] || { echo "Config/Signing.xcconfig is missing; copy the .example and set your team." >&2; exit 1; }
[ -f ../clippy.webp ] || { echo "clippy.webp is missing; run bin/fetch-mascot first." >&2; exit 1; }
[ -f ClippyMeme/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png ] || python3 ../scripts/make-icon.py

# web/ is what ships in the bundle; keep it a copy of the page at the repo root
mkdir -p web
cp ../index.html ../clippy.webp web/

xcodegen generate
if [ "${1:-}" = "--device" ]; then
  TEAM=$(awk -F'= *' '/DEVELOPMENT_TEAM/ {print $2}' Config/Signing.xcconfig | tr -d ' ')
  xcodebuild -project ClippyMeme.xcodeproj -scheme ClippyMeme \
    -configuration Release -destination 'generic/platform=iOS' \
    -derivedDataPath build/dd -allowProvisioningUpdates \
    "DEVELOPMENT_TEAM=$TEAM" build
  echo "Built: build/dd/Build/Products/Release-iphoneos/ClippyMeme.app"
else
  xcodebuild -project ClippyMeme.xcodeproj -scheme ClippyMeme \
    -destination 'generic/platform=iOS' \
    -derivedDataPath build/dd CODE_SIGNING_ALLOWED=NO build
  echo "Compile check passed (unsigned)."
fi
