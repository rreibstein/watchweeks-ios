# Public contract: BLOCKED, not inferred

On 2026-11-08, GET https://watchweeks.com/api/public/guides failed at CONNECT
with proxy HTTP 403 (envoy). The request did not reach the origin. Earlier detail
probe /guides/1 failed identically; no such ID is asserted to exist. No schema,
launch flag, ratings scale, pagination, cache headers, error envelope, image host,
privacy filtering or Singapore/second guide has been verified. docs/ios-handoff.md
is not present in this repository; no private Lovable repository was accessed.

`Guide`, `Event`, `Brand` and `Release` are internal view/cache representations,
not claims about wire fields. `UnverifiedContract` fails closed. Nothing synthetic
is in the app bundle. Test models use Test City/Example names only in test code.
Interest uses a provisional 3-state native model; reconcile it with the website's
actual rating scale before release. Keys combine guide ID and canonical brand ID,
so multiple appearances of one brand within a guide share a selection and cities
remain isolated. Confirm this choice against real stable IDs and organizer semantics.

## Resume once watchweeks.com is allowed

1. GET the index with response headers; verify JSON rather than an HTML SPA fallback.
2. Choose Singapore and another returned ID. Fetch both details. Do not guess slugs.
3. Record envelope, launch semantics, identifiers, nullability, date-only versus
   instants and event timezone, rating meaning, event-brand relationships, image
   URLs, canonical guide URLs, pagination and last-page semantics.
4. Inspect payloads for personal/admin fields before saving sanitized public
   fixtures in Tests/WatchWeeksCoreTests/Fixtures (declare SwiftPM resources).
5. Implement a concrete FeedContract and detail loading. The current index-only
   service cannot load detail payloads and must be extended, not assumed sufficient.
6. Inspect actual Cache-Control/ETag/Last-Modified. Implement pagination if present;
   test non-200/malformed/missing-field responses and duplicate IDs.
7. Reconcile internal models and native interest labels with the observed contract.
   Assert only launched guides are visible. Validate two real guide fixtures.
8. Verify privacy page and first-party logo/icon/styles; replace temporary assets.
9. Test loss of network after live loading, selections, retry and image failures.

No release is permitted with the unverified adapter. A buildable empty feed screen
is not a complete production application.
