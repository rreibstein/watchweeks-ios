# WatchWeeks implementation status

Updated 2026-11-08. Branch: development/native-launch. This is a substantial
implementation baseline, **not a production-ready or submitted application**.

## Implemented

SwiftUI discovery, event/venue schedules, brands with interest and seen controls,
search/filtering, native release browse/detail, share links, My Visit progress,
About/independence/privacy links. Guest-first; no analytics, auth or paid services.
Portable Swift core includes atomic local selection persistence, guide cache,
offline fallback, scoped IDs, HTTP/content-type errors, URL validation and event
local-time formatting. iPhone-only iOS 17 deployment; version 1.0.0 build 1.
Xcode project/shared scheme, UI smoke test, manual macOS CI, verify script,
release drafts and Mac continuation prompt. No website or other repository changed.

## Evidence

- Swift 6.2.1 on Linux compiled core and ran **17 XCTest tests, all passed**.
  Test-only synthetic values, no production contract claimed. Swift Testing runner
  has zero tests separately. An initial assertion typo failed and was corrected.
- Project file parsed with app/UI-test targets; scheme XML and privacy plist parse.
- Temporary opaque RGB icon is 1024×1024 and visually inspected, not identity approved.
- GitHub remote main read succeeded. GitHub API calls were blocked by proxy 403;
  Actions permissions/billing allowance unknown. No CI dispatch or paid usage.
- Public API probes repeatedly failed at proxy CONNECT 403, not origin responses.
- Runner inventory via raw.githubusercontent.com/actions/runner-images/main/images/
  macos/macos-15-Readme.md listed Xcode 26.3 at /Applications/Xcode_26.3.app;
  manual CI selects it, but actual runner execution remains unverified.

## Release blockers and exact next work

1. Allow watchweeks.com in cloud Additional allowed domains, save/publish, retry.
   Config draft service returned INVALID_ARGUMENT; persistence unconfirmed.
2. Actual feed contract, Singapore+second guide, detail loading, live fixtures,
   launched filtering, exact rating model, cache/pagination semantics. Adapter
   intentionally throws contractUnverified: no production feed is integrated yet.
3. Fetch first-party identity and privacy policy. Approve/replace temporary icon;
   confirm native policy coverage, support URL, image permissions and data handling.
4. macOS Xcode build, simulator/UI tests, device QA and screenshots. Linux parsing
   or core tests do not prove iOS compiles. No simulator/device result exists.
5. Apple membership/team/bundle availability, seller/DSA/legal/privacy decisions,
   signing, archive validation, upload/processing and exact build owner approval.
   No account or App Store record has been configured. No upload/submission/release.

## Known acceptance gaps

API-dependent UI cannot be exercised with real data yet. Full real screenshot
navigation automation, release search empty states and detailed accessibility QA
need simulator validation. External images are best effort, not a guaranteed offline
image library. Local data has no website synchronization. Guides removed from a
future feed may no longer appear in My Visit; selections remain stored but must be
reconciled with retention/availability semantics during actual API integration.
Native rating labels are provisional and must match the observed website model.
No claim of App Review compliance or November 12 launch feasibility is made.

See MAC_HANDOFF.md for one ready-to-paste continuation prompt and release steps.
