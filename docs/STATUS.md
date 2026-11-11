# Follow-up candidate after TestFlight 1.0.2 (13)

Source adds the forthcoming-guide Home promo (Geneva W&W, British Watchmakers' Day,
Las Vegas), moves About & privacy to the bottom of Home and expands in-app/privacy
and ASC disclosure guidance. Native APNs callbacks and safe guide routing are
prepared behind a verified-integration gate. The owner chose reliable publisher push;
there is NO notification permission prompt, device-token registration or push
subscription until the Lovable/APNs contract is implemented and verified.

The Home/footer candidate 046ae48 passed Xcode Cloud Verify in 6m 51s with zero
errors/failures/warnings. The subsequent source implements Lovable's preview
upcoming/enrollment contracts, per-guide last-good refresh, Keychain lifecycle and
unsubscribe retries, duplicate-tap suppression and signed APNs environment validation.
The signed-client source 4dfe333 passed Xcode Cloud Verify in 6m 58s with zero
errors/failures/warnings. The next UI run found a flaky lazy-footer hittability
check, now replaced with viewport-based scrolling. Final recovery-contract source
has 71 passing portable tests, client-generated durable credentials, backoff and
permission handling. Fresh final Xcode verification and signed upload are next.
The owner confirms provider credentials are in Lovable; do not request or change
them. Live upcoming is 200 JSON, capability false/delivery_unverified; installation
GET correctly requires auth. /notify is still 404 and the app falls back safely.
No notification sends or App Review/publication are authorized by the latest task.
See release/PUBLICATION_ALERTS_INTEGRATION.md and release/LOVABLE_PUSH_FINISH.md.
Existing build 13 is unchanged and available to test.
See release/LOVABLE_IOS_HANDOFF.md and release/APP_PRIVACY_1_0_2.md. Nothing was
submitted for App Review or published by this work.

# Next update: 1.0.2 (13) — available in TestFlight, not submitted for review

Includes opt-in PostHog Capture API analytics (no SDK/replay), a consent-gated
durable queue, whole-public-event Calendar export without a day chooser, native
tab font inheritance cleanup, home countdowns to the next public event and the
previous removal of shared release-group galleries. The approved 1.0.1 remains
unchanged. No account synchronization, reminders or offline-photo feature is merged.

Validation for this candidate: 42 portable XCTest cases passed on Swift 6.2.1 Linux;
static resource checks passed. Native source syntax parsing is not Xcode compilation.
Xcode Cloud verification passed, including mandatory consent UI QA. Apple confirmed
signed/uploaded version 1.0.2 (13) ready in TestFlight (owner-forwarded email,
2026-11-11), source 8b27440. Owner smoke QA and App Privacy sign-off are pending.
No synthetic production analytics were sent. See release/UPDATE_1_0_2.md for exact
release steps and docs/ANALYTICS.md for current collection and dashboard limits.

The rest of this file is the historical launch record, not validation of 1.0.2.

# WatchWeeks release status — 2026-11-08

Branch: development/native-launch, dedicated rreibstein/watchweeks-ios repository.
**Running on iPhone Simulator. Device and release acceptance remain open.**

## Implemented and preserved in source

- SwiftUI iPhone app, iOS 17+, Events, My list, Brands A–Z, New releases, About.
- Real public v1 index plus detail loading, native brand ratings/seen, release details
  with credited photos, event daily local schedules/access notes, native guide sharing.
- Always-visible top-right Account entry opens the verified existing account page;
  no native auth/sync claim. Web loading improvement proposal in ACCOUNT_ACCESS.md.
- Exact website interest categories (including Skip, distinct from cleared rating),
  canonical city+brandKey identity, search/filter, persistent selections, offline cache.
- First-party clock icon, licensed Space Grotesk fonts, mobile web references and
  product-parity worksheet. Typography/layout parity requires simulator comparison.
- The first release ships without a product analytics SDK, consent prompt, or
  replay. No web analytics or dashboards were changed.
- Release metadata, the native privacy policy, manual macOS CI and shared scheme
  are included. See [release handoff](../release/APP_STORE.md) for the current gate.

The checks below include earlier revisions and historical PostHog validation.

## Evidence

Live read-only GETs succeeded for index and all 5 guide details; Singapore/Austin
JSON regression fixtures retained only in test target. HTTP 404 JSON error and
300-second public caching observed. See API_CONTRACT.md for actual fields/gaps.
Portable Swift 6.2.1 ran 25 XCTest cases with 0 failures; these cover core
logic, observed wire fixtures, service transport mocks and consent.
Project/resource/plist/icon structure checks pass; Swift syntax parsing is separate
from unavailable SwiftUI/SDK typechecking. No Xcode/simulator/device result exists.
Mobile website SSR screenshots inspected; JS/third parties blocked to avoid web
analytics writes. Actual native screenshots have not been captured.

## Mac validation

- Xcode 26.3 (17C529) has the iOS and Simulator SDKs at 26.2. Xcode resolved
  PostHog 3.93.6 and wrote the package lock. SwiftPM compiled the app target
  and SDK for the iOS Simulator in Debug and Release. After installing the
  iOS 26.3 runtime, Xcode built and launched the Debug app on iPhone 17 Pro.
  The missing Swift modules were caused by building the app for both simulator
  architectures while its dependencies built only for the active architecture.
  Debug now uses the active architecture throughout the Xcode project.
  Xcode also built the unsigned Release configuration against the iPhone SDK.
  The live simulator test covered event day filters, the Singapore talk
  trade-off and copying the plan, Golden Hour, rating and shortlist checkoff,
  reopening a collapsed saved brand after relaunch, and the release directory.
- All 30 core tests and both guest and live-data simulator tests passed on the Mac. The verification script supports
  `WW_SWIFTPM_SCRATCH_PATH` to work around a SwiftPM database I/O error under
  the Documents checkout. `WW_XCODE_DERIVED_DATA_PATH` provides the same
  workaround for the Xcode build database.
- The Swift feed decoder loaded all five live city guides. A forced connection
  failure restored the full on-disk snapshot and a saved rating and seen state.
  The Account URL returned HTTP 200.
- Core Text registered the four Space Grotesk files under their expected
  PostScript names. The source clock SVG matched the live favicon, and the
  app icon is an opaque 1024×1024 PNG. The simulator app bundle includes the
  icon, four registered font filenames, and app and SDK privacy manifests.
- A localhost SDK check found and verified a fix for delivery of queued events
  during opt-out. See ANALYTICS.md for the scope and remaining iOS checks.

## Remaining required gates

1. Complete simulator flows and inspect privacy manifests in the eventual archive.
2. SDK delivery/queue/consent integration QA and accurate App Store privacy answers.
   No production synthetic events were sent. Existing PostHog admin access absent;
   exact dashboard specification provided instead. Native policy wording needs owner
   review/application in Lovable; this repository never edits the website.
3. API coverage: website Singapore advertises 56 releases, public API returns 47.
   Native renders actual feed only. Award payloads and lack of stable release IDs
   are documented future-contract risks, not fabricated data.
4. Final mobile visual/functional comparison, accessibility, device QA, real screenshot
   set and support/privacy verification. Plan My Day/comparisons remain on website.
5. Active Apple Developer membership/team, bundle availability, legal seller/DSA
   decisions, signed archive/upload/processing and explicit submission approval.
   No membership purchase, App Store record, upload, review or publication occurred.

## Environment migration

New published environment now allows watchweeks.com. Old helper files and local
uncommitted work did not survive. Pushed code was recovered, tools rebuilt and
needed changes reapplied. Draft reads still fail INVALID_ARGUMENT; newer unknown
script settings were not overwritten. See ENVIRONMENT_DRAFT.md for exact merge.
macOS CI remains manual; GitHub API/billing allowance could not be verified.

Use MAC_HANDOFF.md to continue in Codex on the Mac; no separate ChatGPT guidance
is needed. No background App Review monitoring is configured.
