#!/bin/sh
set -eu
# Validate actual signed entitlements on archive actions, never Debug/Release labels.
if [ "${CI_XCODEBUILD_ACTION:-}" = "archive" ]; then
    if [ -z "${CI_ARCHIVE_PATH:-}" ]; then
        echo "Archive action did not provide CI_ARCHIVE_PATH." >&2
        exit 1
    fi
    python3 "${CI_PRIMARY_REPOSITORY_PATH:-$PWD}/scripts/verify-push-archive.py" "$CI_ARCHIVE_PATH"
fi
