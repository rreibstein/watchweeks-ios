# Validation evidence — 2026-11-08

- Linux Swift 6.2.1: 25 XCTest cases, 0 failures.
  Covered actual public Singapore/Austin decoding, index/detail transport mock,
  unsupported/malformed data, scoped identities, dates/timezones, selection storage,
  stale/offline fallback and retained checklist library, search/filter, HTTP/HTML
  errors, URL validation, website rating categories and analytics consent/properties.
- Separate Swift Testing runner has 0 tests; the 25 above are XCTest, not that runner.
- Swift frontend parsed native sources; parsing does not import/typecheck SwiftUI,
  UIKit or PostHog on Linux. Static review also corrected duplicate local/property
  declarations. Only actual Xcode compilation can establish iOS build readiness.
- Resource checks: icon opaque 1024 RGB, plist/scheme XML, public PostHog config.
- Real GETs: index, five details, privacy, site pages, public branding/style assets.
  No backend mutation or synthetic production analytics calls.
- No Xcode compilation, simulator/UI run, native SDK network-delivery test, device
  QA, native screenshots, signed archive, upload or App Review submission occurred.
- Environment draft read remains broken; no confirmed script/config merge. Newer
  watchweeks.com allowlist retained and verified operationally.
