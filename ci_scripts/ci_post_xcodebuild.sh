#!/bin/sh
set -eu
# Xcode Cloud exports distribution variants before this hook. The raw archive
# can carry an intermediate identity; validate the actual App Store export.
if [ "${CI_XCODEBUILD_ACTION:-}" = "archive" ]; then
    if [ "${CI_XCODEBUILD_EXIT_CODE:-0}" != "0" ]; then
        exit 0 # Preserve the original Xcode build failure.
    fi
    if [ -z "${CI_APP_STORE_SIGNED_APP_PATH:-}" ]; then
        echo "App Store signed export is missing: CI_APP_STORE_SIGNED_APP_PATH is unset." >&2
        exit 1
    fi
    python3 "${CI_PRIMARY_REPOSITORY_PATH:-$PWD}/scripts/verify-push-archive.py" \
        --require-production "$CI_APP_STORE_SIGNED_APP_PATH"
fi
