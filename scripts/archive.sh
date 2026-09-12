#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! xcodebuild -version >/dev/null 2>&1; then
  echo "Install full Xcode 26 or later and select it in Xcode Settings > Locations." >&2
  exit 1
fi
xcode_major="$(xcodebuild -version | awk '/Xcode/{split($2,v,".");print v[1]}')"
if [ "$xcode_major" -lt 26 ]; then
  echo "App Store uploads currently require Xcode 26 or later." >&2
  exit 1
fi
if [ ! -f Oddly/Signing.xcconfig ] || grep -Eq 'YOUR_TEAM_ID|com\.yourcompany\.|com\.example\.' Oddly/Signing.xcconfig; then
  echo "Create Oddly/Signing.xcconfig with your real DEVELOPMENT_TEAM and unique ODDLY_BUNDLE_IDENTIFIER. See the Run section in README.md." >&2
  exit 1
fi
swift test
xcodebuild archive -project Oddly.xcodeproj -scheme Oddly -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/Oddly.xcarchive
echo "Archive created. Open build/Oddly.xcarchive in Xcode Organizer to validate and distribute."
