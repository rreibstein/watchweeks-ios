# Actual screenshot capture

No App Store screenshots have been produced. No mockups or synthetic content may
be represented as running app screenshots. Feed integration and branding approval
are prerequisites. Verify Apple's current reference on Mac:
https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications
Cloud access to developer.apple.com was blocked; current requirements unverified.

In App Store Connect, use the currently required iPhone screenshot size(s), then
select matching installed simulators in Xcode. iPhone-only first release; no iPad
screenshots unless iPad is intentionally enabled. Do not rely on a historical size
list. Capture actual pixels and verify dimensions with `sips -g pixelWidth -g pixelHeight`.

Run scripts/verify-macos.sh first. Boot the chosen simulator, launch the app with
live data, set a neutral status bar using `xcrun simctl status_bar booted override
--time '9:41' --batteryState charged --batteryLevel 100`, and capture via
`xcrun simctl io booted screenshot release/screenshots/01-discovery.png`.
Create directory first. Restore with `xcrun simctl status_bar booted clear`.

Capture five real flows: discovery; city brands; rating/seen interactions; release
detail with licensed actual imagery; My Visit. Seed personal selections by normal
UI interactions using real brands, not fabricated guide content. Extend UITests
with actual navigable labels after API verification. Existing capture attachment
covers only discovery and is opt-in; it is not a complete screenshot suite.
Inspect light/dark, large text, loading/error/empty/offline and VoiceOver order.
Do not upload the temporary icon or unverified identity without owner's approval.
