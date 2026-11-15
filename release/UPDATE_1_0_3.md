# WatchWeeks 1.0.3 — saved-guide safety

Bundle: com.watchweeks.app. Version: 1.0.3. Xcode Cloud supplies an unused build
number; do not use cloud run 41 or the old 1.0.2 binary for this update.

This candidate consists of the rapid build-41 source plus cache validation,
recovery, seven regression tests and release metadata. No account-sync, photo,
reminder, analytics or push feature branch is included. Ratings/Seen remain local.
The iOS 27.3 beta crash reported by a friend remains unconfirmed; do not claim
this update fixes that specific crash before testing or receiving its stack.

## Validation

108 Swift tests passed with release optimization on Linux for the cache patch.
Source/resource/privacy and export-validator checks are required before promotion.
Actual Xcode compilation, signature validation, simulator results and TestFlight
processing must be reported separately when observed. No beta-device validation
has been performed here.

## Owner steps — iPad is sufficient

1. Wait for the TestFlight update whose version is **1.0.3**, notes starting
   **WatchWeeks 1.0.3 — Safer saved-guide loading**. Install over the existing app.
2. Open Home and My list; check that saved ratings/Seen remain. Close/reopen once.
   If previously cached content is available, briefly check Airplane Mode too.
   Record the actual installed TestFlight version/build.
3. App Store Connect → Apps → WatchWeeks → Distribution. Once 1.0.2 is Ready for
   Distribution, use the + beside iOS App (or + Version or Platform → iOS), enter
   **1.0.3**, and create it. If 1.0.2 is still Waiting for Review/In Review, report
   that state before changing the existing submission; do not withdraw blindly.
4. On the 1.0.3 version page, scroll to Build → + / Add Build. Select the same
   1.0.3 build just tested in TestFlight; Save. Cloud run number alone is not
   independent verification of the installed binary's build number.
5. Paste What's New and App Review notes below. Keep the existing correct name,
   seller, pricing, territories, URLs and screenshots. Privacy behavior remains
   the rapid release's actual behavior: no PostHog/push collection; normal public
   content requests still apply. Resolve any Apple-required banner accurately.
6. Select **Automatically release this version**, Save, Add for Review, then
   Submit for Review. This owner action authorizes publication after Apple's
   approval. Choose manual release only if a separate publication decision is
   desired. No agent submission or publication is authorized/performed here.

## What's New — paste exactly

Improved reliability when loading saved guides, while preserving your ratings and checklists.

## App Review notes — paste exactly

Maintenance update to our independent watch-event guide. Validates cached public guide data before display and supports recovery during refresh. Existing on-device ratings and Seen selections are preserved. No login, new permissions, analytics or push enrollment added. Guest browsing remains available. No organizer affiliation is implied.
