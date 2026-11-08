# WatchWeeks iOS

Independent native SwiftUI iPhone guide. Dedicated iOS code only; the production
website is not modified by this project. iOS 17+, Swift 6, one runtime SDK dependency (official PostHog).

**Not release-ready:** real public v1 guide/detail integration is implemented with
Singapore/Austin regression fixtures. Optional official PostHog analytics is wired
to the existing public project, with consent and no replay. Xcode/SDK compilation,
simulator/device QA and privacy sign-off still require macOS. See
[status](docs/STATUS.md), [analytics](docs/ANALYTICS.md) and [API contract](docs/API_CONTRACT.md).

Open `WatchWeeks.xcodeproj` using stable Xcode 26+. Run `swift test` for portable
core tests and `scripts/verify-macos.sh` for Xcode/simulator checks on macOS.
[Mac continuation and release instructions](MAC_HANDOFF.md).

Architecture: SwiftPM `WatchWeeksCore` models/networking/cache/selection logic,
SwiftUI app, XCTest core tests, UI smoke tests, deterministic project generator.
Regenerate the checked-in project with Python `pbxproj==4.3.3` and
`scripts/generate-project.py` when changing project membership. Generation alone
is not Xcode validation. First-party clock icon and Space Grotesk font assets are included; simulator comparison remains required.
