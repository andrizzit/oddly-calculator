#!/usr/bin/env python3
"""Validate checked-in metadata without requiring Xcode or external packages."""
import json
import plistlib
import struct
import subprocess
import xml.etree.ElementTree as ET
from pathlib import Path

root = Path(__file__).resolve().parents[1]
for name in ['Oddly/Info.plist', 'Oddly/PrivacyInfo.xcprivacy']:
    with (root / name).open('rb') as source:
        plistlib.load(source)
for path in (root / 'Oddly/Assets.xcassets').rglob('Contents.json'):
    data = json.loads(path.read_text())
    for image in data.get('images', []):
        if 'filename' in image:
            assert (path.parent / image['filename']).is_file(), f'Missing image in {path}'
icon = (root / 'Oddly/Assets.xcassets/AppIcon.appiconset/AppIcon.png').read_bytes()
assert icon[:8] == b'\x89PNG\r\n\x1a\n', 'Icon must be PNG'
width, height = struct.unpack('>II', icon[16:24])
assert (width, height) == (1024, 1024), 'Icon must be 1024 square'
assert icon[25] == 2, 'App icon must be RGB with no alpha channel'
ET.parse(root / 'Oddly.xcodeproj/xcshareddata/xcschemes/Oddly.xcscheme')
subprocess.run(['plutil', '-lint', str(root / 'Oddly.xcodeproj/project.pbxproj')], check=True)
project = json.loads(subprocess.check_output(['plutil', '-convert', 'json', '-o', '-', str(root / 'Oddly.xcodeproj/project.pbxproj')]))
for value in project['objects'].values():
    if value.get('isa') == 'PBXFileReference' and value.get('sourceTree') == '<group>':
        assert (root / value['path']).exists(), f"Missing project file {value['path']}"
assert (root / 'LICENSE').is_file()
assert (root / 'Sources/CalculatorCore/Personality.swift').is_file()
print('PASS: plist, privacy manifest, project references, scheme, asset catalog, and opaque 1024px icon')
