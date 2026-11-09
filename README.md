# WatchWeeks iOS

Independent native SwiftUI iPhone guide for iOS 17 and later. The first release
uses the public WatchWeeks feed, stores selections locally and ships without a
product analytics SDK or consent screen. See [release status](docs/STATUS.md),
[App Store handoff](release/APP_STORE.md) and [API contract](docs/API_CONTRACT.md).

Open `WatchWeeks.xcodeproj` using stable Xcode 26+. Run `swift test` for portable
core tests and `scripts/verify-macos.sh` for Xcode/simulator checks on macOS.
[Mac continuation and release instructions](MAC_HANDOFF.md).

Architecture: SwiftPM `WatchWeeksCore` models/networking/cache/selection logic,
SwiftUI app, XCTest core tests, UI smoke tests, deterministic project generator.
Regenerate the checked-in project with Python `pbxproj==4.3.3` and
`scripts/generate-project.py` when changing project membership. Generation alone
is not Xcode validation. First-party clock icon and Space Grotesk font assets are included; simulator comparison remains required.
