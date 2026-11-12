# Build history

## Home cleanup and guide-list follow-up — TestFlight received

Source ef408fe1d8da67a5ef186dd0627d80146a764e17, marketing version 1.0.2.
Owner supplied Xcode Cloud run 41: Archive and TestFlight Internal Testing both
succeeded, duration 13 minutes. Owner subsequently confirmed receiving the update.
The public GitHub check remained stale at running; this is not a failed upload.
Includes no duplicate bottom event list when today’s schedule is shown, removal
of the unreliable city By day view, and the preceding Just announced, native
IAMWATCH program, event-brand chips and dealer-list features. 101 portable tests
and 10 export-validator cases passed before upload. No new simulator result
claimed for this follow-up. Analytics/push remain in the separate full-feature
branch. No App Review submission, public release, or real notification sent.

## Branded Home notification promo — signed archive succeeded

Source bc4d8654813ad8b13e0138cd8807badb924acd88, marketing version 1.0.2.
Xcode Cloud Upload / Archive succeeded in 4m 54s, zero errors, failures, analysis
issues or warnings. This styling revision retains the native permission and
analytics behavior UI-verified at 88307be; no new UI test pass is claimed for
the styling itself. Mandatory core/export validation ran through the archive hook.
Apple processing/new TestFlight number remain unconfirmed from this cloud session.
Notes begin "Guide alerts — prominent Home button." Public backend availability
still reports false/delivery_unverified; actual iPad receipt and activation remain.
No App Review submission, public release or provider notification occurred here.

## One-tap native notification permission — Xcode verified, upload triggered

Source: 88307bedae4404d91b620c2d9890669a667c2bac. Version 1.0.2.
Home Notify me calls Apple's native authorization directly, without opening the
guide-updates page or a second enable button. Authorized intent survives restart;
late APNs tokens are accepted and failures retry quietly with bounded backoff.
Revocation/unsubscribe cancels that intent. Server acknowledgement still gates On;
public activation and internal signed TestFlight remain separate. Analytics and
previous Home/cancellation fixes are retained.

85 portable Swift tests and nine export-validator tests pass. Xcode Cloud Verify
succeeded in 9m 35s with zero errors, failures, analysis issues or warnings,
including the real simulator permission flow, browsing and analytics consent QA.
The simulator test never registers a device token or enrolls with the backend.
That exact source was promoted to Upload at 19:27 UTC on Nov 11. Archive
130755869562 started 19:28:25 UTC and still reported running at 19:36 UTC. Public
check reports can lag; signed archive outcome, processed build number and physical
receipt remain unconfirmed. No App Review submission, public activation or
provider notification was performed. TestFlight notes start "One-tap guide notifications."

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
