# WatchWeeks release status — 2026-11-08

Branch: development/native-launch, dedicated rreibstein/watchweeks-ios repository.
**Simulator and device acceptance remain open. No submission.**

## Implemented and preserved in source

- SwiftUI iPhone app, iOS 17+, Events, My list, Brands A–Z, New releases, About.
- Real public v1 index plus detail loading, native brand ratings/seen, release images
  and credits, event daily local schedules/access notes, native guide sharing.
- Always-visible top-right Account entry opens the verified existing account page;
  no native auth/sync claim. Web loading improvement proposal in ACCOUNT_ACCESS.md.
- Exact website interest categories (including Skip, distinct from cleared rating),
  canonical city+brandKey identity, search/filter, persistent selections, offline cache.
- First-party clock icon, licensed Space Grotesk fonts, mobile web references and
  product-parity worksheet. Typography/layout parity requires simulator comparison.
- Official PostHog 3.93.6 dependency, verified existing public token/US host, first-run
  consent, opt-out, manual requested events, anonymous native identity. Replay off
  for v1 as owner prioritizes reliable approval. No web analytics/dashboard changed.
- Dashboard specification, proposed native policy addition, release metadata,
  manual macOS CI, Xcode project/shared scheme and ready-to-paste Mac continuation.

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
  and SDK for the iOS Simulator in Debug and Release without a device runtime.
- All 25 core tests passed on the Mac. The verification script supports
  `WW_SWIFTPM_SCRATCH_PATH` to work around a SwiftPM database I/O error under
  the Documents checkout.
- The Swift feed decoder loaded all five live city guides. A forced connection
  failure restored the full on-disk snapshot and a saved rating and seen state.
  The Account URL returned HTTP 200.
- Core Text registered the four Space Grotesk files under their expected
  PostScript names. The source clock SVG matched the live favicon, and the
  app icon is an opaque 1024×1024 PNG.
- A localhost SDK check found and verified a fix for delivery of queued events
  during opt-out. See ANALYTICS.md for the scope and remaining iOS checks.

## Remaining required gates

1. Mac stable Xcode 26+ resolves SDK/transitive lock, compiles app and tests. Fix any
   issues found there; validate fonts, privacy manifests and iPhone simulator flows.
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
