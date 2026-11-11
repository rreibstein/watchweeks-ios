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

The default shared-scheme test now includes testOptionalAnalyticsConsent. It launches
only the Debug simulator app with WW_ANALYTICS_QA=1 and a fresh UserDefaults suite.
A Debug/simulator-only in-process receiver validates the actual serialized Capture
API request and exposes event/id summaries through a test diagnostic accessibility
value. It never opens a network connection or uses the public project token. The
receiver and diagnostic UI are not compiled into the Release app.

This checks silent launch, decline, opt-in, opt-out across relaunch and new identity
after re-enabling. Core tests separately cover payload allowlist, durable offline
queue/restart, queue cap, foreground deduplication and in-flight cancellation.
Actual production network ingestion still requires a separately authorized test;
these consent tests do not claim to verify production delivery.

The prior localhost receiver script remains for manual transport investigations,
but is no longer a prerequisite for cloud or local consent UI tests. A Cloud-only
listener-startup failure was removed, not skipped or treated as an app test pass.

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
