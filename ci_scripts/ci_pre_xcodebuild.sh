#!/bin/bash
# A loopback-only receiver for the explicit analytics consent UI test.
set -euo pipefail
case "${CI_XCODEBUILD_ACTION:-}" in
  test|build-for-testing|test-without-building) ;;
  *) exit 0 ;;
esac
repo_root="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/.." && pwd)}"
state_dir="${CI_DERIVED_DATA_PATH:-${TMPDIR:-/tmp}}/WatchWeeksAnalyticsQA"
mkdir -p "$state_dir"
if [[ -f "$state_dir/receiver.pid" ]] && kill -0 "$(cat "$state_dir/receiver.pid")" 2>/dev/null; then
  exit 0
fi
nohup python3 "$repo_root/scripts/qa-analytics-receiver.py" >"$state_dir/receiver.log" 2>&1 </dev/null &
receiver_pid=$!
printf '%s\n' "$receiver_pid" > "$state_dir/receiver.pid"
for attempt in {1..20}; do
  if curl --noproxy '*' -fsS --max-time 2 http://127.0.0.1:8766/events >/dev/null; then
    echo 'Loopback analytics QA receiver ready; fake key only.'
    exit 0
  fi
  sleep 0.25
done
cat "$state_dir/receiver.log" >&2
exit 1
