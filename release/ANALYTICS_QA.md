# WatchWeeks iOS optional analytics

The native app opens straight to Events. No automatic consent dialog or system
tracking request is shown. Under My list → About & privacy → Learn about usage
analytics, a native sheet explains what is shared and why. The user can leave
it off or explicitly choose “Share usage” in a native alert. After opt-in, the
same page offers “Turn off usage analytics.”

The HTTPS client sends explicit usage events with platform `ios_native`, an
app-only random identifier, and app version. It never links to website identities
or sends a rating choice, Seen value, search query, or account information.
It does not use ATT, an SDK, autocapture, person profiles, GeoIP enrichment,
advertising or replay. Opt-out stops capture, cancels pending requests, clears the
persisted queue and removes the identifier. It does not delete data already sent.
Previously consented queued events persist across app exits, up to 100 events.

## Test without touching production

Run `python3 scripts/qa-analytics-receiver.py` on the Mac and select a Debug iPhone
simulator. Use `TEST_RUNNER_WW_ANALYTICS_QA=1 xcodebuild ... test
-only-testing:WatchWeeksUITests/WatchWeeksUITests/testOptionalAnalyticsConsent`.
The test uses a fresh consent store and a loopback-only endpoint with a dummy key.
Production delivery is disabled in all simulator and Debug builds.

The test checks a silent fresh launch, declining, successful opt-in delivery,
opt-out surviving relaunch, and a new identifier after re-enabling. Before
release, exercise offline opt-out and retry; confirm production configuration
against the intended PostHog project and test real delivery against an isolated
test project or approved non-production endpoint. Do not send synthetic events
into production.

## Before promoting this branch

Verify the intended project and region, access and retention, client IP storage,
and remaining privacy disclosures. `$geoip_disable` disables enrichment, not
necessarily IP logging. PostHog offers a project-level discard-IP setting; do
not change the shared website project without coordinating with its owner.
Update App Store Connect's App Privacy details with the actual collection and
any processor-side data; this branch cannot use “Data Not Collected.” Confirm
the public in-app privacy-policy URL describes this exact build before review.
The live policy and no-analytics branch must remain accurate until rollout.

The branch records app opens, guide/event/release views, rating actions and
Seen actions. It also records My list visits, completed guide shares and accepted WatchWeeks website transitions. Brand detail is not a separate screen; no synthetic brand-view event is emitted.
