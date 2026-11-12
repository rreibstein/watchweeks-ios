#!/usr/bin/env python3
"""Validate APNs configuration against the final distribution signature."""
import argparse
import json
from pathlib import Path, PurePosixPath
import plistlib
import subprocess
import sys
import tempfile
import zipfile


def validate(info, entitlements, require_production=False):
    if info.get("WatchWeeksReleaseChannel") == "rapid":
        if info.get("CFBundleIdentifier") != "com.watchweeks.app":
            raise ValueError("Unexpected rapid application bundle identifier.")
        identities = [entitlements[key] for key in
                      ("application-identifier", "com.apple.application-identifier")
                      if key in entitlements]
        if not identities or any(not isinstance(value, str) or not value.endswith(".com.watchweeks.app")
                                 for value in identities) or len(set(identities)) != 1:
            raise ValueError("Rapid signed application identifier is invalid.")
        if "WatchWeeksPostHogToken" in info or info.get("WatchWeeksPushIntegrationVerified") is True:
            raise ValueError("Rapid build must not contain analytics or push configuration.")
        if "aps-environment" in entitlements:
            raise ValueError("Rapid build must not carry an APNs entitlement.")
        if require_production and entitlements.get("get-task-allow") is True:
            raise ValueError("Rapid TestFlight export must have a distribution signature.")
        return "Rapid signed export verified: no analytics configuration or APNs entitlement."
    if info.get("WatchWeeksPushIntegrationVerified") is not True:
        return "Push integration disabled; no notification activation in this build."
    expected = {"development": "sandbox", "production": "production"}.get(
        entitlements.get("aps-environment")
    )
    if expected is None or info.get("WatchWeeksAPNsEnvironment") != expected:
        raise ValueError("Push configuration must match the final signed aps-environment entitlement.")
    if info.get("CFBundleIdentifier") != "com.watchweeks.app":
        raise ValueError("Unexpected application bundle identifier.")
    identities = [entitlements[key] for key in
                  ("application-identifier", "com.apple.application-identifier")
                  if key in entitlements]
    if not identities or any(not isinstance(value, str) or
                             not value.endswith(".com.watchweeks.app")
                             for value in identities) or len(set(identities)) != 1:
        raise ValueError("Final signed application identifier does not match the fixed APNs topic.")
    if require_production and (expected != "production" or entitlements.get("get-task-allow") is True):
        raise ValueError("TestFlight/App Store distribution requires production APNs and a distribution signature.")
    return f"Final signed push configuration verified: {expected}. Delivery still requires device QA."


def single_app(directory):
    apps = list(directory.glob("*.app"))
    if len(apps) != 1:
        raise ValueError("Expected exactly one application in the distribution payload.")
    return apps[0]


def distribution_app(path, unpack_directory):
    """Accept Xcode Cloud's export directory, its IPA, a signed app, or manual archive."""
    if path.suffix == ".app" and path.is_dir():
        return path
    if path.suffix == ".xcarchive" and path.is_dir():
        return single_app(path / "Products/Applications")
    if path.is_dir():
        packages = list(path.glob("*.ipa")) or list(path.glob("*.zip"))
        if len(packages) == 1:
            path = packages[0]
        elif not packages:
            return single_app(path / "Payload" if (path / "Payload").is_dir() else path)
        else:
            raise ValueError("Expected exactly one App Store export package.")
    if not path.is_file() or path.suffix.lower() not in (".ipa", ".zip"):
        raise ValueError("App Store signed export was not found; intermediate archive is not a substitute.")
    with zipfile.ZipFile(path) as package:
        for member in package.infolist():
            item = PurePosixPath(member.filename)
            if item.is_absolute() or ".." in item.parts:
                raise ValueError("Unsafe path in distribution package.")
        if sys.platform == "darwin":
            # Preserve executable bits and signed bundle symlinks on Apple's runner.
            subprocess.run(["/usr/bin/ditto", "-x", "-k", str(path), str(unpack_directory)],
                           check=True, capture_output=True)
        else:
            package.extractall(unpack_directory)
    payload = unpack_directory / "Payload"
    return single_app(payload if payload.is_dir() else unpack_directory)


def inspect(path, require_production=False):
    info = plistlib.loads((path / "Info.plist").read_bytes())
    if info.get("WatchWeeksPushIntegrationVerified") is not True and info.get("WatchWeeksReleaseChannel") != "rapid":
        return info, {}, validate(info, {}, require_production)
    subprocess.run(["/usr/bin/codesign", "--verify", "--strict", str(path)],
                   check=True, capture_output=True)
    signed = subprocess.run(
        ["/usr/bin/codesign", "--display", "--entitlements", ":-", str(path)],
        check=True, capture_output=True,
    )
    entitlements = plistlib.loads(signed.stdout)
    return info, entitlements, validate(info, entitlements, require_production)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("artifact", type=Path, help="Final signed export directory, IPA or app; manual xcarchive also supported")
    parser.add_argument("--require-production", action="store_true")
    arguments = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix="watchweeks-signed-export-") as temporary:
        app = distribution_app(arguments.artifact, Path(temporary))
        info, entitlements, message = inspect(app, arguments.require_production)
        print(message)
        # Deliberately limited to non-secret release metadata. No complete plist,
        # signing credentials, device tokens or installation secrets are printed.
        print(json.dumps({"bundle_id": info.get("CFBundleIdentifier"),
                          "version": info.get("CFBundleShortVersionString"),
                          "build": info.get("CFBundleVersion"),
                          "aps_environment": entitlements.get("aps-environment")}, sort_keys=True))


if __name__ == "__main__":
    main()
