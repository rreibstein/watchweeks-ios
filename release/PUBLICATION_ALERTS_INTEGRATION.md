# Publication alerts integration — November 11, 2026

The owner supplied Lovable's implementation handoff for the isolated draft
“Native publication alerts + newsletter preview.” Its reported tests are backend
evidence supplied by Lovable, not tests run from this native repository. Nothing
in this change accepts that draft, migrates its shared database, deploys the
website, sends messages, or submits an app for review.

## Implemented native behavior

- The existing dynamic v1 index remains authoritative; string slugs and stable
  edition IDs stay compatible. Individual detail failures retain that edition's
  last-good content while other editions refresh. All-guide failure restores the
  snapshot. Removed editions remain in the checklist library without deleting
  ratings. Stale refresh retries use 30 seconds, 2 minutes, then 10 minutes, and
  the app refreshes on foreground.
- `/api/public/guides/upcoming` supplies titles and planned/published state. Its
  validated editorial content is cached; cached push capabilities never enable
  enrollment. Before deployment/offline, verified editorial titles remain the
  fallback. No dates are invented.
- Typed, bounded registration/read/rotation/delete requests implement Lovable's
  contract. The dedicated ephemeral session rejects redirects and uses no cookies
  or disk URL cache. Tokens and credentials never enter usage analytics.
- Acknowledgement is required before showing On. A per-installation bearer and ID
  are stored in Keychain with `AfterFirstUnlockThisDeviceOnly`. Token bytes are
  passed to the server only when enabled, not persisted in this repository/app
  preferences. No passwords or Apple provider keys belong in the app.
- OS permission is requested only after an explicit action and both gates below.
  Foreground checks reconcile server revocation and OS permission. Unsubscribe
  intent persists before network deletion and retries after a restart; the UI
  distinguishes pending deletion from confirmed Off. Opt-out during registration
  removes an acknowledged enrollment rather than silently enabling it.
- Notification taps require type, version, bounded guide ID and notification ID.
  The last 200 opened IDs suppress duplicate routing across restarts. A destination
  must be present in a fetched canonical index; stale-only guides and arbitrary
  payload URLs cannot become destinations. Unknown IDs receive one refresh attempt.
- About & privacy stays at the bottom of Home. It includes guide-alert preferences
  and the verified signed-out corrections link. The website newsletter link switches
  to `/notify#newsletter` only after the new feed endpoint responds successfully.
  Copy does not claim that email delivery is already activated.

## Shipping gates — disabled in this source

`WatchWeeksPushIntegrationVerified` is explicitly false in Info.plist. No push
entitlement is added or signing capability enabled by this change. The remote
capability is a second gate, never a replacement for verified native signing.

Before an enabled build:

1. Obtain owner approval to accept the isolated Lovable draft (including its shared
   backend migration), and separately deploy it. Validate that the historical-guide
   baseline cannot enqueue a blast. Native work does not authorize either action.
2. Resolve the backend release issues in `LOVABLE_PUSH_FINISH.md`. Keep delivery
   disabled and scheduling absent until explicit approval.
3. Owner enables Push Notifications for `com.watchweeks.app` and provides APNs
   provider credentials only through secure backend configuration. No key material
   is needed by Codex in chat. No remote-notification background mode is needed.
4. Complete device QA and privacy review before setting the local verified flag.
   Set `WatchWeeksAPNsEnvironment` to `sandbox` for a development-entitled build or
   `production` for a production-entitled build. TestFlight AND App Store use
   production APNs. Never derive this from Debug/Release labels.
5. Validate the final signed archive:

   ```sh
   python3 scripts/verify-push-archive.py /path/to/WatchWeeks.xcarchive
   ```

   The script compares the configured API environment with the actual signed
   `aps-environment` entitlement and fixed bundle/topic. The Xcode Cloud archive
   post-build hook runs the same check. Distribution can re-sign an app: inspect
   the final exported app too if its environment differs from the initial archive.
6. With separate owner approval, verify actual sandbox receipt on a development
   device, then production APNs receipt on a staging TestFlight installation.
   APNs HTTP/2 transport must be proven in the published backend runtime. Neither
   fake-provider tests nor APNs 200 proves on-device delivery.
7. Activate the remote capability/schedule only after the ready native build and
   real delivery are verified. Obtain approval for any real notification send.

The current POST contract cannot recover a lost registration response without the
returned credential. The client fails safely on 409; it never takes over another
installation. Server recovery is a remaining backend prerequisite, not a reason to
ask the user to wait 60 days or repeatedly tap Enable.

## Privacy

Current gated build: no registration, device token or installation credential is
sent. Existing optional analytics disclosures remain applicable. Before activation,
update the app policy, native consent copy and App Store privacy answers for push
device/installation identifiers used for App Functionality, plus any actual
diagnostic/request metadata the backend retains. Verify purpose, linkage, processor,
region and retention from actual implementation; do not invent retention periods.
Push permission is independent of analytics consent and is not ATT authorization.
The native app collects no newsletter email itself; website signup uses the
website's existing consent and subscriber lifecycle.

## Validation evidence

- Production read-only probes on Nov 11: guide index 200 JSON/no-store; upcoming
  endpoint 404 JSON; `/notify` 404 HTML. Preview contracts are not live.
- Portable tests cover real-feed decoding and per-guide 404/503 recovery, upcoming
  null dates/version/duplicates/offline storage, push payload validation/dedup,
  request shape/environment/acknowledgement/errors/token rotation, credential header
  validation, offline unsubscribe/restart and opt-out during in-flight registration.
- Source checks and synthetic signed-entitlement checks are separate from an actual
  signed archive or APNs delivery test. See the recorded Xcode Cloud result for the
  exact candidate revision. No signed upload or App Review submission is implied.
