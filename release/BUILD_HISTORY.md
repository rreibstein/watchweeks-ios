# Build history

## Publication-alert candidate — signed upload running

Source: dbb61b790793f08911cd53be5c08dc2ccfb7e0c4. Marketing version 1.0.2;
new build number and Apple processing pending confirmation.

Xcode Cloud Verify succeeded Nov 11 in 6m 19s with zero reported errors, test
failures, analysis issues or warnings. Core suite has 72 tests; required guest,
notification-gating and analytics-consent UI checks passed. Optional live screenshot
capture is separate and was not claimed as passed.

The exact source was promoted to release/cloud-upload. Archive started 12:53 UTC.
[Archive status](https://github.com/rreibstein/watchweeks-ios/commit/dbb61b790793f08911cd53be5c08dc2ccfb7e0c4/checks/130534757008).
No provider notification, Apple credential change or App Review submission occurred.


## 1.0.2 (13) — TestFlight ready, 2026-11-11

Source: 8b27440f498cc04f33963c9ac67796efa3575fe1, release/cloud-upload.
App: WatchWeeks: Watch Event Guide, com.watchweeks.app, ASC ID 6832395283.

Evidence: owner forwarded Apple's “1.0.2 (13) is ready to test on iOS” email and
Xcode Cloud WatchWeeks Upload notification listing Archive - iOS and TestFlight
Internal Testing - iOS. Source commit title matches the promoted release SHA.
GitHub's public archive check still showed running and may lag Apple notifications.
No App Store Connect API query was used to establish processing.

Verification: 42 portable core tests passed. Xcode Cloud Verify passed with required
self-contained consent UI QA (zero reported errors, test failures or warnings).
The prior listener-startup failure was corrected by removing the external test
server dependency. Release app contains neither test receiver nor diagnostic UI.

Includes: opt-in PostHog, durable consented queue/opt-out; whole-public-event Calendar
without day picker; tab font inheritance cleanup; event-local public countdowns;
removal of extra release-group galleries. No account sync, reminder or offline-photo
feature branch included.

Remaining: owner device smoke test, actual authorized PostHog ingestion check,
privacy disclosures and explicit App Review/public release approvals. This build
was not submitted for review or published by this task.
