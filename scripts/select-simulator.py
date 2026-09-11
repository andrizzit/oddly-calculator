#!/usr/bin/env python3
"""Read simctl's available-device JSON and select the newest supported iPhone."""
import json
import re
import sys

devices = json.load(sys.stdin).get('devices', {})
candidates = []
for runtime, entries in devices.items():
    match = re.search(r'\.iOS-(\d+)-(\d+)(?:-(\d+))?$', runtime)
    if not match:
        continue
    version = tuple(int(value or 0) for value in match.groups())
    if version < (17, 0, 0):
        continue
    for device in entries:
        if device['name'].startswith('iPhone') and device.get('isAvailable', True):
            candidates.append((version, device['name'] == 'iPhone 16 Pro Max', device['name'], device['udid']))
print(max(candidates)[-1] if candidates else '')
