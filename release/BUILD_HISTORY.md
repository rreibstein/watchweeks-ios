# Build history

## Early-engagement analytics choice — verified, signed upload triggered

Source: 21f824dc7327ce8ef1a873455d9a9d3838b9e38a. Marketing version 1.0.2.
Inline optional analytics choice after two useful interactions and 30 active
seconds; no launch interruption or replay of earlier actions. Not now persists;
existing choices and later Settings changes are respected. Local capped counters
never reach analytics. The Home/cancellation and TestFlight push fixes are retained.

81 portable core tests, nine export-validator tests and source checks passed.
Xcode Cloud Verify passed in 9m 13s with zero errors, failures, analysis issues
or warnings, including both new early-choice UI tests and existing consent QA.
The initial refusal test needed to reveal a lazy Settings row; its correction
passed in the final run. The exact verified source was promoted to Upload at
18:28 UTC on Nov 11. Archive 130723535573 queued at 18:29:06 UTC, still reported
queued at 18:34 UTC. Archive/processing/build number remain unconfirmed; no
notification send, public push activation or App Review submission is performed.

## Home and TestFlight setup correction — verified, archive triggered

Source: 5eca70f6b1042274859949d0bce298a550a86703. Version 1.0.2.
Removes the city rail, puts the promo above Past guides, suppresses canceled-request
errors/coalesces refresh, and uses verified StoreKit download metadata for TestFlight
access. Signed APNs environment remains production; StoreKit sandbox metadata does
not change the APNs host. No transaction/JWS/account data is transmitted.

77 core tests and nine export tests pass. Xcode Cloud Verify passed in 6m 59s with
zero errors/failures/analysis issues/warnings, including foreground/browsing and
consent QA. The exact source was promoted to Upload; Archive began 16:00:40 UTC.
New TestFlight number, processing and actual remote receipt are not yet confirmed.


## Publication-alert release — corrected archive succeeded

App source verified: dbb61b790793f08911cd53be5c08dc2ccfb7e0c4.
Release scripts/notes source: 1bc5b73596f3f7f2a4299b0c3dd27ea1b7175d58.
Marketing version 1.0.2; new processed TestFlight number unconfirmed.

Xcode Cloud Verify succeeded in 6m 19s with zero errors, failures or warnings.
Core suite: 72 tests; required navigation, notification-gating and consent UI
checks passed. Optional live screenshot capture was not claimed as passed.

Build 26 then compiled and exported every distribution variant, but our validator
checked the intermediate archive rather than the final export and blocked the
post-action. The corrected checker validates the actual App Store export and passes
nine regression tests. No application/Swift code changed.

The exact script-corrected source was promoted to release/cloud-upload.
[Xcode Cloud Archive succeeded](https://github.com/rreibstein/watchweeks-ios/commit/1bc5b73596f3f7f2a4299b0c3dd27ea1b7175d58/checks)
in 4m 43s with zero errors/warnings, including final signature/APNs validation.
TestFlight distribution/processing and exact build number are not yet confirmed.
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
