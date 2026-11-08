# WatchWeeks iOS

Independent native SwiftUI iPhone guide. Dedicated iOS code only; the production
website is not modified by this project. iOS 17+, Swift 6, no runtime dependencies.

**Not release-ready:** actual public API contract is blocked by cloud networking.
The adapter fails closed; no fictional event content is bundled. See
[status](docs/STATUS.md) and [API integration gates](docs/API_CONTRACT.md).

Open `WatchWeeks.xcodeproj` using stable Xcode 26+. Run `swift test` for portable
core tests and `scripts/verify-macos.sh` for Xcode/simulator checks on macOS.
[Mac continuation and release instructions](MAC_HANDOFF.md).

Architecture: SwiftPM `WatchWeeksCore` models/networking/cache/selection logic,
SwiftUI app, XCTest core tests, UI smoke tests, deterministic project generator.
Regenerate the checked-in project with Python `pbxproj==4.3.3` and
`scripts/generate-project.py` when changing project membership. Generation alone
is not Xcode validation. Temporary icon must be reconciled with first-party identity.
