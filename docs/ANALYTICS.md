# WatchWeeks native PostHog — next release 1.0.2

The published launch release and approved 1.0.1 contain no native analytics.
This candidate integrates the existing feature/consented-analytics work and extends
its consent gate with tested durable delivery in UsageAnalyticsClient.swift.
It uses PostHog's HTTPS Capture API directly, NOT the earlier removed iOS SDK.
No new runtime dependency, replay/autocapture, device fingerprint, account linking
or geo-IP enrichment is added. There is no SDK-generated automatic event stream.

## Configuration and user choice

Public project token in App/Info.plist, production host https://us.i.posthog.com,
existing website project. Public token is not a personal/admin credential. No
website code, account data, dashboards, retention settings or replay is changed.
PostHog admin access and processor logging/retention are not available here.

Off by default, no automatic startup dialog. My list > About & privacy > Usage
analytics explains collection before “Share usage.” Turning it off clears queued
analytics and installation identifier, cancels pending delivery and survives relaunch.
Re-enabling creates a new random app identifier. No identity is shared with web.
User preferences remain local and are not changed by analytics consent.

Captured: app_opened, guide_viewed, event_viewed, release_viewed, brand_rating_set,
brand_seen_toggled, my_visit_viewed, completed guide_shared, website_link_opened and
usage_analytics_enabled. Only public guide/event/release IDs and app version/build
are attached; no rating category, Seen value, notes, queries, prices or email.
platform=ios_native, $geoip_disable=true, $process_person_profile=false.
Brand detail is not a distinct native screen, so no synthetic brand_viewed is added.
Foreground and per-view guards avoid redraw/refresh/background duplicate counts.

Durable FIFO queue capped at 100 events in app-local UserDefaults. Oldest queued
event is evicted at cap. Consent is rechecked before every delivery and response;
opt-out purges queue. Previously consented events retry after transient errors and
across app restarts. 429/5xx retry with bounded exponential delay; permanent 4xx
are dropped. Delivery is best effort, not exactly-once; existing in-flight requests
cannot be recalled. No attempt is made to reconstruct actions performed while off.

## Verification and dashboard

42 total portable tests passed for this candidate. Analytics tests cover opt-in/out, payload allowlist, persisted queue/restart,
in-flight opt-out, queue cap and foreground deduplication. iOS transport/consent UI
and actual intended-project ingestion remain release acceptance checks. See
release/ANALYTICS_QA.md. Debug and simulator cannot use production ingestion.
No production test event was sent and no remote dashboard was created here.

Dashboard specification: WatchWeeks — Native iOS engagement, last 30 days, filter
platform=ios_native throughout:
- DAU/WAU: unique distinct IDs with app_opened per day/week.
- New/returning: first observed native event timestamp versus prior history. Person
  profiles are disabled; don't use person creation dates. Opt-out/re-opt-in resets IDs.
- Guide/event/release engagement: event totals and uniques by their public ID.
- Activation: users with brand_rating_set / active users in the same period; this
  counts control changes, not unique current ratings or must-see choices.
- Seen actions: totals/uniques of brand_seen_toggled; no checked/unchecked split is
  available because the value is deliberately not transmitted.
- My list: my_visit_viewed totals, uniques and share of active users.
- Guide shares and website transitions: respective totals/uniques.
- Web/native comparison: map web rating_set/rating_clear and seen_check/seen_uncheck
  to native action families with separate series. Never merge anonymous identities.

Metrics describe consenting observed users, not everyone who installs. Downloads
and acquisition come from App Store Connect, not PostHog. All counts can be affected
by opt-out, ID resets, reinstalls, network loss and queue eviction.
