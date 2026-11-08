# Native analytics implementation and acceptance

Official PostHog iOS SDK pinned exactly to **3.93.6**, tag commit
4e9850f767988f394e8584b0bf61ce85674775eb. Source/manifest inspected, SDK not yet
compiled in Xcode here. Source: https://github.com/PostHog/posthog-ios/tree/3.93.6.

Existing public website analytics bundle analytics-DPNrSzxm.js was inspected on
2026-11-08. It configures project 668499, US ingestion https://us.i.posthog.com.
Its public phc_ project token is reused in App/AnalyticsConfig.plist. It is an
intentionally public ingestion token, not a personal/admin API credential. No
Supabase credentials were copied. No management API access was granted. Web code,
analytics settings and dashboards were not changed. No synthetic events were sent.

First-launch optional consent explains usage and offers equal allow/decline choices.
Analytics is off until allowed; change it in About. The SDK generates its own
anonymous distinct ID. Never call identify/alias/group or bridge website identity.
No IDFA/ATT permission is requested. Replay, automatic lifecycle/screens, element
capture, surveys, feature-flag preloading, geo-IP enrichment, swizzling
and automatic errors are disabled. Manual events only, no SDK default person data.
Existing web events include rating_set/rating_clear and seen_check/seen_uncheck.
Native uses the explicitly requested names below rather than emitting both naming
schemes. Web/native comparisons must map those families, never sum duplicates.

## Event contract

All events: platform=ios_native, app_version, app_build, instrumentation_version=1.
Public IDs only where context exists: guide_id, city, event_id, brand_id, release_id.
No free-text notes, email, account ID, search strings, prices, URL queries or release
text enters application analytics. SDK adds runtime/device/session metadata.

| Event | Trigger and extra properties |
|---|---|
| app_opened | one foreground transition, not each refresh; first_observed_open indicates first analytics-observed opening, not install |
| guide_viewed | first appearance of a newly navigated city screen |
| event_viewed | event detail opened |
| brand_viewed | brand detail opened, not scroll visibility |
| brand_rating_set | changed rating only, rating_category=must/moderate/little/unknown/none/unrated; clear included |
| brand_seen_toggled | changed seen only, seen=true/false |
| my_visit_viewed | actual transition to My list tab |
| release_viewed | new release detail, public composed release_id |
| guide_shared | completed native activity share, not canceled sheet |
| website_link_opened | accepted native open of WatchWeeks website link, no query/URL captured |

Screen State guards prevent redraw/background refresh from recounting. This app
has no navigation restoration; adding it later requires restoration-aware guards.
First opt-in may generate one consented app_opened in the already-active session.
SDK lifecycle events remain disabled, so no duplicate automatic install/open stream.

SDK bounded disk queue: max 500 events, batches at 20 or 30 seconds, retries and
reachability resume according to SDK. Events can be dropped under queue limits,
network failure or app deletion. No exactly-once/delivery guarantee. SDK 3.93.6
can still try to flush existing queued events while opted out. WatchWeeks blocks
new capture in the app and SDK, and rejects requests from the SDK URLSession
when the saved consent setting is off. Already in-flight transmissions cannot be
recalled. Previously consented events may retry after the user opts back in.

## Mac analytics validation

A local macOS harness exercised the app's consent gate and the pinned SDK's
actual batch transport. Before the transport guard, a flush delivered a queued
event after opt-out. With the guard, decline and opt-out blocked capture,
queued delivery was blocked while opted out, and only previously consented
events retried after opt-in. The seen value was a JSON Boolean. The harness used
a fake token and localhost and omitted iOS-only SDK options. iOS runtime and
device checks remain separate.

Debug Simulator builds use no analytics transport by default. Launch with
`SIMCTL_CHILD_WW_ANALYTICS_QA=1` (or pass `WW_ANALYTICS_QA=1` in a UI test's
launch environment) to send only to a local receiver on `localhost:8766`
with a fake token. Session replay remains disabled.

## Required Mac acceptance

Resolve/pin transitive Package.resolved, compile SDK/app, inspect archive's bundled
privacy manifests; intercept SDK URLSession with test transport or use authorized
separate test project for delivery validation. Never send synthetic test traffic to
production. Test first consent, decline and relaunch, opt-out before offline queue
flush, airplane mode -> online, active/inactive transitions, no background refresh
screen events, repeated rating no-op, successful versus canceled sharing. Verify
no replay/automatic events/IDFA/notes/prices/emails in captured wire payloads.
Then confirm a consented real-device event appears in project 668499 with
platform=ios_native (only after explicit test authorization and reviewing quotas).
Cloud unit tests validate consent/event properties, not SDK delivery or Apple builds.

## Exact dashboard specification (create in existing project)

Dashboard: **WatchWeeks — Native iOS engagement**. Default last 30 days, compare
previous period; all native panels filtered platform=ios_native. Break down app_version
as needed. Exclude test/internal builds after specifying their version/build values.

1. DAU: app_opened, unique distinct IDs, daily. WAU: same, weekly buckets; optionally
   rolling 7-day uniques (label rolling explicitly).
2. New vs returning: first observed native event per distinct_id within date range
   versus earlier observed event. Use event-history cohort/min(timestamp), NOT
   person-created date since person profiles are disabled. first_observed_open is
   a convenience marker only, can reset after reinstall/data deletion.
3. Guide usage: guide_viewed uniques and total views, breakdown city/guide_id.
4. Activation: unique native users with brand_rating_set and rating_category in must/moderate/little
   / unique app_opened users in same period. Also create 7-day ordered funnel
   app_opened -> interested brand_rating_set (must/moderate/little). Label the two denominator methods.
5. Rating changes: total brand_rating_set, breakdown rating_category; distinguish
   changes/clears from unique currently-rated brands (the latter cannot be inferred
   by counting events). Seen check-offs: brand_seen_toggled seen=true; undo separately.
6. Release engagement: release_viewed total/unique; breakdown guide and brand IDs.
7. My list: my_visit_viewed total/unique and fraction of active native users.
8. Website transitions: website_link_opened total/unique and active-user percentage.
9. Web vs native: separate series, never merge identities. Map native brand_rating_set
   to web rating_set (exclude clears) and native seen=true to web seen_check. Use
   verified web guide_id values; web New York currently differs from API ID. Do not
   equate web sessions/pageviews with app opens or deduplicate across channels.

These measure consented observed usage only. App Store downloads/installs require
App Store Connect acquisition data; PostHog cannot directly count downloads.
“New observed native user,” “first open,” “installation,” and “active user” are
separate quantities. Consent, device sharing, ID resets and reinstalls affect counts.
No dashboard has been created remotely; this is the exact reusable specification.

SDK setup is deferred until consent. In 3.93.6 remoteConfig is a deprecated no-op: config is always fetched after SDK setup. We do not claim it is disabled; local replay/autocapture/survey settings remain off. Inspect this request during Mac privacy QA.
