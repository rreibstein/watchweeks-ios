# Latest follow-up — Home and guide fixes

This follow-up supersedes the frozen candidate below. Home omits its bottom
repeat event list when today’s schedule is shown. The unreliable city "By day"
view has been removed for this release; day filters, event cards, and the
separate IAMWATCH Schedule tab remain. No new permissions or data collection.

Identify the build by TestFlight notes beginning **Rapid release — Home cleanup
and reliable guide browsing**. Xcode Cloud assigns the build number. Select that
same build in the existing 1.0.2 App Store Connect version after Apple processing.
If 1.0.2 has already been released, a higher marketing version and rebuild are
required. Do not substitute a differently numbered version.

Minimum launch steps (iPad supported):
1. Install this newest TestFlight update and briefly open Home and IAMWATCH Schedule.
2. App Store Connect → WatchWeeks → iOS 1.0.2 → Build: select that tested build.
3. What's New: "Discover Just announced watches, explore IAMWATCH’s program, and
   browse Coconut Grove dealers in a searchable A–Z list. Includes cleaner Home
   cards and more reliable guide browsing."
4. Keep existing accurate privacy, seller, territories and pricing; choose manual
   release. Add for Review → Submit for Review only with owner approval.
5. After approval, Release This Version when ready.

No Mac or Apple Developer capability change is needed for this rapid candidate.
Analytics and push enrollment remain on the separate full-feature branch.

---

# Rapid content release — current candidate

## Final frozen candidate

Source **6cb6a2ef45f0df0845194824e8fc19628e95dc45**, version **1.0.2**.
Notes start **Rapid release — Just announced, IAMWATCH schedule and dealer lists**.
Includes Just announced in all three requested locations, Just added markers,
event-brand chips, IAMWATCH program-first browsing and the vertical dealer list.
No native analytics or notification enrollment. Full instrumentation is preserved
on feature/just-announced for a later release.

Validation: 101 portable tests; 10 export-validator cases; Xcode Cloud Verify passed
in 6m 3s with zero errors, failures, analysis issues or warnings. UI QA exercised
announcement-to-release routing, all three placements, brand-chip navigation,
program/day/speaker browsing, dealer search and absence of removed feature UI.
All 12 current announcement image URLs returned HTTP 200 with image content.
Three actual simulator screenshot attachments were captured using a two-item
snapshot of real published Nov 12 data; they are QA captures, not a new App Store
marketing screenshot set:

- announced-01-home-real-feed-snapshot
- announced-02-guide-event-real-feed-snapshot
- announced-03-new-releases-real-feed-snapshot

Archive check 131432217941 still reports running as of Nov 12, 19:40 UTC. Public
reports may lag. Apple processing and the exact TestFlight build number are NOT
confirmed. Do not call the candidate available until TestFlight/Apple confirms it.

## Minimum owner steps for this frozen candidate

1. When TestFlight offers the build with the notes above, install it. Record its
   version/build. Spend about two minutes opening Just announced → release,
   IAMWATCH Schedule → a day/session, Coconut Grove → dealer search, and My list.
   Confirm appearance and preserved selections. No APNs or PostHog setup is needed.
2. In the existing WatchWeeks App Store Connect update, choose that same tested
   build. Keep existing name, price, seller, territories and accurate screenshots.
   Use the What's New and review-note text below. Keep Sign-in required off and
   choose manual release. If version 1.0.2 is already public, stop and bump/rebuild;
   do not attach this binary to a differently numbered version.
3. After exact-build owner approval, Add for Review → Submit for Review. After
   Apple approves, approve public release and use Release This Version. No agent
   submission or publication is authorized by these instructions.

Apple Developer → Identifiers → Push Notifications can remain checked. It is an
App ID capability, not activation in the signed rapid app. No APNs entitlement is
requested by this candidate. App Privacy disclosures are separate: do not add
Device ID/Product Interaction solely for omitted push/PostHog features. If those
were added only as preparation, restore the live app's accurate data disclosures;
keep actual hosting/request-metadata collection accurately disclosed.

Native policy URL, if the listing needs it:
https://github.com/rreibstein/watchweeks-ios/blob/release/rapid-schedule/release/PRIVACY_RAPID.md

What's New:

> Discover Just announced watches, explore IAMWATCH's day-by-day program, and
> browse Coconut Grove dealers in a searchable A–Z list. Includes quicker brand
> browsing and smoother guide loading.

Review notes:

> Independent guide; no organizer affiliation or required login. Singapore shows
> Just announced; tapping a watch opens New releases at that brand. Singapore →
> IAMWATCH opens the native Schedule tab with days and session details. Miami →
> Coconut Grove has the dealer directory. Ratings remain on-device and previously
> loaded guides/programs work offline. This build has no native product analytics
> or notification enrollment. Public program content is parsed without running
> website scripts or embedding a WebView.

Deferred analytics event list (no events sent by rapid build):

- just_announced_tapped: source (home/guide/new_releases), guide_id, brand_key,
  event_id, zero-based position, visible count and announced_date.
- just_announced_all_releases_tapped: source, guide_id and visible count.
- Existing consent gate and platform/app-version properties apply in the full
  variant. No model/variant text, notes, credit, image URL or prices are sent.

The earlier implementation notes below remain background; this frozen-candidate
section supersedes their candidate/validation/owner-step details.

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
