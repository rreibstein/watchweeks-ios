# Rapid content release — current candidate

Branch: release/rapid-schedule. Version: 1.0.2, with a new Xcode Cloud build number.
Do not submit if that version train has already closed; advance/rebuild in that case.
The full-feature source, including this native program/dealer implementation and
the prior analytics/push work, is preserved at development/program-and-dealers
and development/native-launch, source 18801be. Do not replace either with this branch.

## Included

- IAMWATCH's published 25-session program is the first event tab, matching the
  website. Day filters, speaker/session/room search, times, rooms, descriptions and
  participant groups are native. Invitation-only sessions retain that label.
- Program source is https://watchweeks.com/singapore/event/iamwatch, read-only.
  API v1 currently contains opening hours but no program records. The narrow HTML
  adapter validates the published Program section/count/times and runs no scripts.
  If the site changes shape or is unavailable, retain last-good cache; do not
  reconstruct sessions from guesses. No program fixtures are in the Release app.
- Coconut Grove's public feed dealers are vertical, A–Z, with name search. Home
  previews four rows and links to the full list. No invented booth numbers or URLs.
- Existing guest checklists, local ratings/Seen, native sharing, Calendar, releases,
  dynamic guide discovery and loading/cancellation fixes remain.

## Deferred in this candidate

- App startup/production code has no PostHog client or key, analytics opt-in/UI,
  APNs registration/delegate, notification opt-in/promo, or push entitlement.
- Existing user data and previous consent/queue keys are preserved, not read or
  transmitted by the inert event facade. No backend records are changed/deleted.
- Signed export validation must verify identity/distribution signing and reject
  any APNs entitlement or analytics configuration in this rapid build.
- Full-feature tests for intentionally absent opt-in flows are absent from this
  variant; rapid UI tests explicitly check their absence. Native program/dealer,
  browsing/foreground tests remain, and all portable core tests still run.

## Validation

91 portable tests passed before the fork, including the actual public 25-session
HTML fixture, timezone/day/search, malformed program rejection, stable derived IDs,
dealer sorting/isolation and offline persistence. The rapid source adds a 10th
signed-export validator case. Xcode/simulator and signed archive results must be
recorded after execution; Linux tests do not establish an iOS build.

## Owner minimum, on iPad

1. Install the TestFlight build whose notes start **Rapid release — IAMWATCH schedule
   and Coconut Grove dealers**. Record its version/build; retain your local data.
2. Open Singapore → IAMWATCH: Schedule first, change day, expand Session details.
   Open Miami → Coconut Grove: verify the vertical dealer list and search.
3. Check a rating/Seen and My list. Briefly disconnect after loading the program;
   confirm cached content/selections remain. Restore the connection.
4. Select that exact build in the existing App Store Connect update. Keep the
   current accurate listing/screenshots; remove claims of push/analytics from this
   update. Native privacy policy URL:
   https://github.com/rreibstein/watchweeks-ios/blob/release/rapid-schedule/release/PRIVACY_RAPID.md
5. No analytics/push nutrition-label categories are added by this app build.
   Retained guide/image/program request metadata still needs accurate answers;
   do not assert Data Not Collected solely from SDK absence. Confirm existing
   hosting/provider collection before reusing the live app's privacy answers.
6. Confirm the actual version/build, seller, storefronts, privacy answers and
   unresolved issues before explicit owner submission approval. Submit via Add
   for Review → Submit for Review, with manual release selected. No App Review
   submission or public release is authorized by this document.

What's New:

> Explore IAMWATCH's day-by-day program with session times, speakers and room
> details. Browse Coconut Grove dealers in a searchable A–Z list. Includes guide
> loading and navigation improvements.

App Review notes:

> WatchWeeks is an independent watch-event guide, not affiliated with organizers.
> No login is required. Events → Singapore → IAMWATCH opens the native Schedule
> tab; day filters, search and session details use the published WatchWeeks program.
> Events → Miami → Coconut Grove shows the dealer directory. Ratings/checklists
> remain on-device; previously loaded guides/programs work offline. This content
> update includes no native product analytics, notification enrollment or tracking.
> Program data is read from a public page without executing website scripts.

Optional expedited-review request, only after submission:

> Please consider expedited review of WatchWeeks (Apple ID 6832395283). This update
> adds native access to the IAMWATCH November 13–15 program and improves the
> Coconut Grove November 13–15 dealer directory for attendees this weekend.
> WatchWeeks is an independent guide. The existing app is already available;
> this request is for the time-sensitive content/usability update.

## Review timing and relative risk

No automatic-approval status or app-specific approval probability is established.
Apple has historically published a general 90%-reviewed-within-24-hours benchmark;
that is not an approval probability or guarantee for this update. The official
review page was blocked by this cloud proxy during this task, so no live queue
claim is made. Reference: https://developer.apple.com/app-store/review/.

| Candidate | Relative readiness/review risk | Planning approach |
| --- | --- | --- |
| Native schedule + dealer/content/UI fixes | Lowest new review surface; first choice for this weekend after QA | A few hours is possible; allow 24–48 hours and more if rejected or delayed |
| Same + consented analytics | Common functionality; privacy accuracy and ingestion QA add readiness work | No reliable separate review-time penalty can be predicted |
| Same + analytics + push | Currently blocked by unverified device delivery/public activation | Do not submit as a working notification release until verified; timing uncertain |

Correct analytics/push can pass quickly; removing them reduces this project's open
gates, not Apple's queue. App Store Connect download metrics remain available;
detailed native PostHog measurement is deferred. Do not request fake urgency,
claim a crash fix, or submit multiple competing versions at once.
