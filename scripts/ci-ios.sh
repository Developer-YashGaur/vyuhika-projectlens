#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
xcrun simctl list devices available --json > build/simulators.json
simulator_id=$(python3 - <<'PY'
import json
with open('build/simulators.json') as f:
    devices = json.load(f)['devices']
for runtime in sorted(devices, reverse=True):
    if '.iOS-' not in runtime:
        continue
    for device in devices[runtime]:
        if device.get('isAvailable') and device['name'].startswith('iPhone'):
            print(device['udid'])
            raise SystemExit(0)
raise SystemExit('No available iPhone simulator. Install an iOS simulator runtime in Xcode Settings.')
PY
)
# A unique result path lets local validation run repeatedly without deleting prior results.
result_path="build/TestResults-$(date -u +%Y%m%dT%H%M%SZ)-$$.xcresult"
xcodebuild -project ProjectLens.xcodeproj -scheme ProjectLens \
  -configuration Debug -destination "platform=iOS Simulator,id=$simulator_id" \
  -derivedDataPath build/DerivedData -resultBundlePath "$result_path" \
  CODE_SIGNING_ALLOWED=NO test
