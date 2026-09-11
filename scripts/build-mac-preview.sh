#!/bin/bash
# Supplemental shared-SwiftUI QA when only the macOS SDK is available.
# This is not an iOS build, simulator, archive, or App Store deliverable.
set -euo pipefail
cd "$(dirname "$0")/.."
preview_dir="$PWD/build/mac-preview"
app_dir="$preview_dir/Oddly Preview.app"
mkdir -p "$preview_dir/modules" "$preview_dir/cache" "$app_dir/Contents/MacOS" "$app_dir/Contents/Frameworks"
swiftc -parse-as-library -swift-version 6 -emit-library -emit-module -module-name CalculatorCore \
  -module-cache-path "$preview_dir/cache" \
  -emit-module-path "$preview_dir/modules/CalculatorCore.swiftmodule" \
  -Xlinker -install_name -Xlinker @rpath/libCalculatorCore.dylib \
  Sources/CalculatorCore/*.swift -o "$app_dir/Contents/Frameworks/libCalculatorCore.dylib"
swiftc -parse-as-library -swift-version 5 -I "$preview_dir/modules" \
  -module-cache-path "$preview_dir/cache" -L "$app_dir/Contents/Frameworks" -lCalculatorCore \
  -Xlinker -rpath -Xlinker @executable_path/../Frameworks \
  Oddly/*.swift -o "$app_dir/Contents/MacOS/OddlyPreview"
cat > "$app_dir/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>OddlyPreview</string>
<key>CFBundleIdentifier</key><string>org.oddly.local-preview</string>
<key>CFBundleName</key><string>Oddly Preview</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$app_dir/Contents/Frameworks/libCalculatorCore.dylib"
codesign --force --sign - "$app_dir"
echo "$app_dir"
