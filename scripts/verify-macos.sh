#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ $(uname -s) == Darwin ]] || { echo 'Requires macOS and Xcode 26 or newer.'; exit 1; }
xcodebuild -version
major=$(xcodebuild -version | awk '/Xcode/{split($2,a,"."); print a[1]}')
[[ $major -ge 26 ]] || { echo 'Select stable Xcode 26+ with xcode-select.'; exit 1; }
python3 scripts/validate-source.py
swift test --scratch-path "${WW_SWIFTPM_SCRATCH_PATH:-.build}"
mkdir -p release/archives
derived_data_path="${WW_XCODE_DERIVED_DATA_PATH:-DerivedData}"
xcodebuild -resolvePackageDependencies -project WatchWeeks.xcodeproj -scheme WatchWeeks -derivedDataPath "$derived_data_path"
# Supply a concrete installed simulator UUID, avoiding ambiguous destination names.
if [[ -z ${WW_SIMULATOR_ID:-} ]]; then
  WW_SIMULATOR_ID=$(xcrun simctl list devices available -j | python3 -c 'import json,sys; d=json.load(sys.stdin); print(next((x["udid"] for k,v in sorted(d["devices"].items(),reverse=True) if "iOS" in k for x in v if "iPhone" in x["name"]), ""))')
  if [[ -z $WW_SIMULATOR_ID ]]; then
    echo 'Install an iOS simulator runtime in Xcode > Settings > Components, then create an iPhone simulator.' >&2
    exit 1
  fi
fi
xcodebuild -project WatchWeeks.xcodeproj -scheme WatchWeeks -destination "platform=iOS Simulator,id=$WW_SIMULATOR_ID" -derivedDataPath "$derived_data_path" -parallel-testing-enabled NO -resultBundlePath "release/archives/Tests-$(date +%s).xcresult" CODE_SIGNING_ALLOWED=NO test
