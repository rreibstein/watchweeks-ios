#!/usr/bin/env python3
"""Fail an enabled-push archive whose configuration disagrees with its signature."""
import argparse
import plistlib
from pathlib import Path
import subprocess


def validate(info, entitlements):
    if info.get("WatchWeeksPushIntegrationVerified") is not True:
        return "Push integration disabled; no notification activation in this build."
    expected = {"development": "sandbox", "production": "production"}.get(
        entitlements.get("aps-environment")
    )
    if expected is None or info.get("WatchWeeksAPNsEnvironment") != expected:
        raise ValueError("Push configuration must match the final signed aps-environment entitlement.")
    if info.get("CFBundleIdentifier") != "com.watchweeks.app":
        raise ValueError("Unexpected application bundle identifier.")
    application_id = entitlements.get("application-identifier", "")
    if not application_id.endswith(".com.watchweeks.app"):
        raise ValueError("Signed application identifier does not match the fixed APNs topic.")
    return f"Signed push configuration verified: {expected}. Delivery still requires device QA."


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path, help="Signed .xcarchive or .app")
    arguments = parser.parse_args()
    path = arguments.archive
    if path.suffix == ".xcarchive":
        apps = list((path / "Products/Applications").glob("*.app"))
        if len(apps) != 1:
            parser.error("Expected exactly one app in the archive.")
        path = apps[0]
    info = plistlib.loads((path / "Info.plist").read_bytes())
    if info.get("WatchWeeksPushIntegrationVerified") is not True:
        print(validate(info, {}))
        return
    signed = subprocess.run(
        ["/usr/bin/codesign", "--display", "--entitlements", ":-", str(path)],
        check=True, capture_output=True,
    )
    entitlements = plistlib.loads(signed.stdout)
    print(validate(info, entitlements))


if __name__ == "__main__":
    main()
