#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! xcrun --find simctl >/dev/null 2>&1; then
  echo "Full Xcode and an iOS Simulator runtime are required. Select Xcode in Settings > Locations > Command Line Tools." >&2
  exit 1
fi
device_id="${SIMULATOR_ID:-$(xcrun simctl list devices available -j | python3 scripts/select-simulator.py)}"
if [ -z "$device_id" ]; then
  echo "No available iPhone simulator. Install an iOS runtime in Xcode Settings > Components." >&2
  exit 1
fi
xcodebuild test -project Oddly.xcodeproj -scheme Oddly \
  -destination "platform=iOS Simulator,id=$device_id" \
  -derivedDataPath build/DerivedData -resultBundlePath "build/TestResults-$(date +%s).xcresult" \
  CODE_SIGNING_ALLOWED=NO
