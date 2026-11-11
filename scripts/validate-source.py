#!/usr/bin/env python3
from pathlib import Path
import json,plistlib,struct,xml.etree.ElementTree as ET
root=Path(__file__).resolve().parents[1]
p=plistlib.loads((root/'App/PrivacyInfo.xcprivacy').read_bytes());assert p['NSPrivacyTracking'] is False
assert {i['NSPrivacyCollectedDataType'] for i in p['NSPrivacyCollectedDataTypes']} == {'NSPrivacyCollectedDataTypeDeviceID', 'NSPrivacyCollectedDataTypeProductInteraction'}
assert p['NSPrivacyTrackingDomains'] == []
assert 'XCRemoteSwiftPackageReference' not in (root/'WatchWeeks.xcodeproj/project.pbxproj').read_text()
ET.parse(root/'WatchWeeks.xcodeproj/xcshareddata/xcschemes/WatchWeeks.xcscheme')
a=root/'App/Assets.xcassets/AppIcon.appiconset'
for e in json.loads((a/'Contents.json').read_text())['images']:
 d=(a/e['filename']).read_bytes();assert struct.unpack('>IIBBBBB',d[16:29])==(1024,1024,8,2,0,0,0)
print('PASS: project resources, icon format, privacy and local-only package dependencies; no Xcode compilation')
