#!/usr/bin/env python3
"""Portable regression tests for final signed-export selection and validation."""
import importlib.util
import os
from pathlib import Path
import plistlib
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("push_export", ROOT / "scripts/verify-push-archive.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class PushDistributionTests(unittest.TestCase):
    def testRapidExportRequiresCorrectIdentityAndNoAnalyticsOrAPNs(self):
        info={"WatchWeeksReleaseChannel":"rapid","CFBundleIdentifier":"com.watchweeks.app"}
        signed={"application-identifier":"TESTTEAM.com.watchweeks.app","get-task-allow":False}
        self.assertIn("Rapid signed export verified",module.validate(info,signed,True))
        for bad in [{},dict(signed,**{"aps-environment":"production"}),
                    dict(signed,**{"get-task-allow":True}),
                    dict(signed,**{"application-identifier":"OTHER.com.other.app"})]:
            with self.assertRaises(ValueError):module.validate(info,bad,True)
        for key,value in [("WatchWeeksPostHogToken","test"),("WatchWeeksPushIntegrationVerified",True)]:
            with self.assertRaises(ValueError):module.validate(dict(info,**{key:value}),signed,True)

    def setUp(self):
        self.info = {"WatchWeeksPushIntegrationVerified": True,
                     "WatchWeeksAPNsEnvironment": "production",
                     "CFBundleIdentifier": "com.watchweeks.app",
                     "CFBundleShortVersionString": "1.0.2", "CFBundleVersion": "27"}
        self.entitlements = {"aps-environment": "production",
                             "application-identifier": "TESTTEAM.com.watchweeks.app",
                             "get-task-allow": False}

    def package(self, path):
        with zipfile.ZipFile(path, "w") as archive:
            archive.writestr("Payload/WatchWeeks.app/Info.plist", plistlib.dumps(self.info))
        return path

    def testFinalProductionSignatureAndNamespacedIdentity(self):
        self.assertIn("production", module.validate(self.info, self.entitlements, True))
        signed = dict(self.entitlements)
        signed["com.apple.application-identifier"] = signed.pop("application-identifier")
        self.assertIn("production", module.validate(self.info, signed, True))

    def testIntermediateArchiveWithoutIdentityRemainsRejected(self):
        with self.assertRaisesRegex(ValueError, "application identifier"):
            module.validate(self.info, {"aps-environment": "production"}, True)

    def testWrongIdentityEnvironmentOrDevelopmentSignatureCannotUpload(self):
        for key, value in [("application-identifier", "TESTTEAM.com.other.app"),
                           ("aps-environment", "development"), ("get-task-allow", True)]:
            with self.subTest(key=key), self.assertRaises(ValueError):
                module.validate(self.info, dict(self.entitlements, **{key: value}), True)

    def testConflictingIdentityKeysAreRejected(self):
        signed = dict(self.entitlements, **{"com.apple.application-identifier": "OTHERTEAM.com.watchweeks.app"})
        with self.assertRaises(ValueError):
            module.validate(self.info, signed, True)

    def testExportDirectoryAndDirectIPAResolveTheFinalPayload(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            export = root / "app-store"
            export.mkdir()
            ipa = self.package(export / "WatchWeeks.ipa")
            # An unrelated symbols zip must not hide the IPA.
            (export / "Symbols.zip").write_bytes(b"not an application")
            for artifact in (ipa, export):
                with tempfile.TemporaryDirectory() as target:
                    app = module.distribution_app(artifact, Path(target))
                    self.assertEqual(app.name, "WatchWeeks.app")
                    self.assertEqual(plistlib.loads((app / "Info.plist").read_bytes()), self.info)

    def testSignedAppAndManualArchivePathsRemainSupported(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            archive = root / "WatchWeeks.xcarchive"
            app = archive / "Products/Applications/WatchWeeks.app"
            app.mkdir(parents=True)
            self.assertEqual(module.distribution_app(archive, root), app)
            self.assertEqual(module.distribution_app(app, root), app)

    def testUnsafeZipAndAmbiguousExportFailClosed(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            malicious = root / "unsafe.ipa"
            with zipfile.ZipFile(malicious, "w") as archive:
                archive.writestr("../escape", "not extracted")
            with self.assertRaises(ValueError):
                module.distribution_app(malicious, root / "output")
            self.assertFalse((root / "escape").exists())
            self.package(root / "other.ipa")
            with self.assertRaises(ValueError):
                module.distribution_app(root, root / "output")

    def testSignatureVerificationUsesTheSelectedSignedApp(self):
        with tempfile.TemporaryDirectory() as directory:
            app = Path(directory) / "WatchWeeks.app"
            app.mkdir()
            (app / "Info.plist").write_bytes(plistlib.dumps(self.info))
            with patch.object(module.subprocess, "run") as command:
                command.return_value = subprocess.CompletedProcess([], 0, plistlib.dumps(self.entitlements), b"")
                info, _, _ = module.inspect(app, True)
                self.assertEqual(info["CFBundleVersion"], "27")
                self.assertIn("--verify", command.call_args_list[0].args[0])
                self.assertTrue(all(call.args[0][-1] == str(app) for call in command.call_args_list))

    def testCloudHookUsesOnlyAppStoreExportAndRequiresProduction(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            binary = root / "python3"
            capture = root / "arguments"
            binary.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$WW_TEST_CAPTURE"\n')
            binary.chmod(0o700)
            env = dict(os.environ, PATH=str(root) + os.pathsep + os.environ["PATH"],
                       CI_XCODEBUILD_ACTION="archive", CI_XCODEBUILD_EXIT_CODE="0",
                       CI_PRIMARY_REPOSITORY_PATH=str(ROOT),
                       CI_APP_STORE_SIGNED_APP_PATH=str(root / "final-app-store"),
                       CI_ARCHIVE_PATH=str(root / "intermediate.xcarchive"), WW_TEST_CAPTURE=str(capture))
            subprocess.run(["/bin/sh", str(ROOT / "ci_scripts/ci_post_xcodebuild.sh")], env=env, check=True)
            arguments = capture.read_text()
            self.assertIn("--require-production", arguments)
            self.assertIn("final-app-store", arguments)
            self.assertNotIn("intermediate.xcarchive", arguments)
            del env["CI_APP_STORE_SIGNED_APP_PATH"]
            result = subprocess.run(["/bin/sh", str(ROOT / "ci_scripts/ci_post_xcodebuild.sh")],
                                    env=env, capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("signed export is missing", result.stderr)


if __name__ == "__main__":
    unittest.main()
