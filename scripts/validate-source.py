#!/usr/bin/env python3
from pathlib import Path
import json,plistlib,struct,xml.etree.ElementTree as ET
root=Path(__file__).resolve().parents[1]
p=plistlib.loads((root/'App/PrivacyInfo.xcprivacy').read_bytes());assert p['NSPrivacyTracking'] is False
info=plistlib.loads((root/'App/Info.plist').read_bytes())
if info.get('WatchWeeksReleaseChannel') == 'rapid':
 assert p['NSPrivacyCollectedDataTypes'] == []
 assert 'WatchWeeksPostHogToken' not in info and 'WatchWeeksAPNsEnvironment' not in info
 assert plistlib.loads((root/'App/WatchWeeks.entitlements').read_bytes()) == {}
 assert 'UNUserNotificationCenter' not in (root/'App/WatchWeeksApp.swift').read_text()
 assert 'us.i.posthog.com' not in (root/'App/WatchWeeksApp.swift').read_text()
else:
 assert {i['NSPrivacyCollectedDataType'] for i in p['NSPrivacyCollectedDataTypes']} == {'NSPrivacyCollectedDataTypeDeviceID', 'NSPrivacyCollectedDataTypeProductInteraction'}
assert p['NSPrivacyTrackingDomains'] == []
assert 'XCRemoteSwiftPackageReference' not in (root/'WatchWeeks.xcodeproj/project.pbxproj').read_text()
ET.parse(root/'WatchWeeks.xcodeproj/xcshareddata/xcschemes/WatchWeeks.xcscheme')
a=root/'App/Assets.xcassets/AppIcon.appiconset'
for e in json.loads((a/'Contents.json').read_text())['images']:
 d=(a/e['filename']).read_bytes();assert struct.unpack('>IIBBBBB',d[16:29])==(1024,1024,8,2,0,0,0)
print('PASS: project resources, icon format, privacy and local-only package dependencies; no Xcode compilation')
