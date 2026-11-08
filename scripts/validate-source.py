#!/usr/bin/env python3
from pathlib import Path
import json,plistlib,struct,xml.etree.ElementTree as ET
root=Path(__file__).resolve().parents[1]
p=plistlib.loads((root/'App/PrivacyInfo.xcprivacy').read_bytes());assert p['NSPrivacyTracking'] is False
assert len(p['NSPrivacyCollectedDataTypes'])==3
ET.parse(root/'WatchWeeks.xcodeproj/xcshareddata/xcschemes/WatchWeeks.xcscheme')
a=root/'App/Assets.xcassets/AppIcon.appiconset'
for e in json.loads((a/'Contents.json').read_text())['images']:
 d=(a/e['filename']).read_bytes();assert struct.unpack('>IIBBBBB',d[16:29])==(1024,1024,8,2,0,0,0)
c=plistlib.loads((root/'App/AnalyticsConfig.plist').read_bytes());assert c['projectToken'].startswith('phc_');assert c['host']=='https://us.i.posthog.com'
print('PASS: project resources, icon format, privacy and public analytics configuration; no Xcode compilation')
