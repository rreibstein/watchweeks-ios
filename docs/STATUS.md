# WatchWeeks release status — 2026-11-08

Branch: development/native-launch, dedicated rreibstein/watchweeks-ios repository.
**Not submitted, not production-ready, no iOS build has run.**

## Implemented and preserved in source

- SwiftUI iPhone app, iOS 17+, Events, My list, Brands A–Z, New releases, About.
- Real public v1 index plus detail loading, native brand ratings/seen, release images
  and credits, event daily local schedules/access notes, native guide sharing.
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
