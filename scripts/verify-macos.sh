#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ $(uname -s) == Darwin ]] || { echo 'Requires macOS and Xcode 26 or newer.'; exit 1; }
xcodebuild -version
major=$(xcodebuild -version | awk '/Xcode/{split($2,a,"."); print a[1]}')
[[ $major -ge 26 ]] || { echo 'Select stable Xcode 26+ with xcode-select.'; exit 1; }
swift test --parallel
mkdir -p release/archives
xcodebuild -resolvePackageDependencies -project WatchWeeks.xcodeproj -scheme WatchWeeks
# Supply a concrete installed simulator UUID, avoiding ambiguous destination names.
if [[ -z ${WW_SIMULATOR_ID:-} ]]; then
  WW_SIMULATOR_ID=$(xcrun simctl list devices available -j | python3 -c 'import json,sys; d=json.load(sys.stdin); print(next(x["udid"] for k,v in sorted(d["devices"].items(),reverse=True) if "iOS" in k for x in v if "iPhone" in x["name"]))')
fi
xcodebuild -project WatchWeeks.xcodeproj -scheme WatchWeeks -destination "platform=iOS Simulator,id=$WW_SIMULATOR_ID" -derivedDataPath DerivedData -resultBundlePath "release/archives/Tests-$(date +%s).xcresult" CODE_SIGNING_ALLOWED=NO test
