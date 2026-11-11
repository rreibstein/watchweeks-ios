#!/bin/bash
# Xcode Cloud discovers this hook beside the primary Xcode project.
# It validates source and portable core tests; Apple owns signing/upload.
set -euo pipefail
repo_root="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$repo_root"
[[ $(uname -s) == Darwin ]] || { echo 'This hook requires a macOS Xcode runner.' >&2; exit 1; }
xcodebuild -version
xcode_major=$(xcodebuild -version | awk '/^Xcode / {split($2,parts,"."); print parts[1]}')
[[ "$xcode_major" =~ ^[0-9]+$ && "$xcode_major" -ge 26 ]] || { echo 'Select stable Xcode 26 or later in the workflow.' >&2; exit 1; }
python3 scripts/validate-source.py
python3 scripts/test-push-distribution.py
scratch_base="${CI_DERIVED_DATA_PATH:-${TMPDIR:-/tmp}}"
swift test --jobs 4 --scratch-path "$scratch_base/WatchWeeksCoreCI"
echo 'Source validation and core tests passed. Xcode Cloud must separately run the simulator Test action.'
