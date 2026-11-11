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
- Acknowledgement is required before showing On. A 256-bit credential is generated
  with SecRandomCopyBytes and formatted wwpi_ plus unpadded base64url. It and the
  exact pending request are stored BEFORE the first POST. POST authenticates with
  that bearer; 201 creates and 200 recovers. Lost responses/restarts reuse the same
  credential and canonical request bytes. The acknowledged ID is stored in Keychain
  with `AfterFirstUnlockThisDeviceOnly`. Pending token bytes live only in that
  protected record for recovery, then clear after acknowledgement; they never enter
  ordinary app preferences or this repository. No passwords or Apple provider keys belong in the app.
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
  to `/notify#newsletter` only after the page itself serves successful HTML;
  otherwise it uses the verified homepage.
  Copy does not claim that email delivery is already activated.

## Launch gates — signed native client prepared

The integrated native client now includes Push Notifications entitlements and explicit
build settings (Debug development/sandbox; Release production/production).
`WatchWeeksPushIntegrationVerified` enables that client; final signed archive
validation must pass. A live backend is required. App Store users additionally need
remote availability. A verification build identified by its TestFlight sandbox receipt
can enroll before public availability so actual receipt can be proven. Simulator
UI QA cannot enroll. No receipt contents or Apple identities are read or transmitted.
Released build 13 still has no such adapter/capability and cannot be remotely enabled.

Before an enabled build:

1. Production index/upcoming now serve JSON and the installation read route
   enforces authentication. Public capability/scheduling remain Off. Lovable reports
   24 backend tests passed; provider transport and iPad receipt remain unverified.
   Never generate a historical-guide blast.
2. The final recovery contract is implemented natively. Keep public delivery
   disabled until actual test-device receipt and hosted transport are verified.
3. Provider credentials are already stored securely in Lovable, per the owner.
   Do not request, rotate or change them. Xcode Cloud handles app signing; if its
   permissions cannot enable the App ID capability, report the exact portal step.
   No remote-notification background mode is needed.
4. Complete Xcode validation, signed archive checks, device QA and privacy review.
   `WatchWeeksAPNsEnvironment` expands from explicit build settings; validate it
   against the actual signed entitlement rather than assuming build configuration
   names prove correctness. TestFlight AND App Store use production APNs.
5. Validate the final signed archive:

   ```sh
   python3 scripts/verify-push-archive.py /path/to/WatchWeeks.xcarchive
   ```

   The script compares the configured API environment with the actual signed
   `aps-environment` entitlement and fixed bundle/topic. The Xcode Cloud archive
   post-build hook runs the same check. Distribution can re-sign an app: inspect
   the final exported app too if its environment differs from the initial archive.
6. Lovable performs the selected-device test after Reed supplies the non-secret
   TestFlight installation ID. Reed confirms physical receipt. TestFlight uses
   production APNs; a development/sandbox test is optional and does not require a
   Mac for this launch path. Neither fake tests nor APNs 200 proves device receipt.
7. Activate the remote capability/schedule only after the ready native build and
   real delivery are verified. Obtain approval for any real notification send.

The final backend recovery contract supplied by the owner is now implemented.
429/503/network failures persist backoff (30 seconds, 2 minutes, 10 minutes, then
30 minutes; a longer Retry-After is honored). Backgrounding suspends the retry task.
404 on initial/recovery registration preserves the credential and reports failure,
not a fabricated subscription. PATCH omits registration-only platform/guides fields
and preserves server subscription preferences. Deletion intent survives a lost POST
response: recover the same installation, then delete it without showing On.

The owner confirms APNs provider credentials are stored in Lovable. Native code
never reads them. The final instruction prohibits notification sending, App Store
release and Apple credential changes; provider testing belongs to Lovable and Reed
must confirm physical receipt before public activation.

## Reed: internal TestFlight verification

1. Install the newly uploaded build in TestFlight on the iPad and launch WatchWeeks.
2. On Home/Events, scroll to Get guide updates. A TestFlight delivery-check notice
   appears while public capability is false. Tap Enable notifications, then Allow.
   Browsing and local selections continue to work if permission is denied.
3. Wait for Guide alerts are enabled. Tap Copy test installation ID. This is only
   the non-secret installation UUID, never the bearer or APNs device token. Share
   that reference with Lovable for the selected-device provider test.
4. Lovable handles sending. Confirm physical receipt and tap the notification to
   open its public guide; unknown/unavailable guides return to the guide list.
5. Test Turn off guide alerts; wait for confirmation. If offline, the app explains
   pending deletion and retries online. Re-enable when ready to use the feature.
6. Public availability stays false until Reed confirms receipt. App Store users
   cannot use the TestFlight-only bypass. No App Review submission occurs here.

## Privacy

Production availability remains gated. A new TestFlight verification build can
register only after explicit action and permission against a live backend. Build 13
sends no push registration. The manifest adds App Functionality to Device ID and
the native policy explains optional push enrollment/unsubscribe. Before App Review,
update the app policy, native consent copy and App Store privacy answers for push
device/installation identifiers used for App Functionality, plus any actual
diagnostic/request metadata the backend retains. Verify purpose, linkage, processor,
region and retention from actual implementation; do not invent retention periods.
Push permission is independent of analytics consent and is not ATT authorization.
The native app collects no newsletter email itself; website signup uses the
website's existing consent and subscriber lifecycle.

## Validation evidence

- Production read-only probes on Nov 11: index/upcoming 200 JSON/no-store; push
  availability false, delivery_unverified. The authenticated installation GET route
  returns 401 without credentials. /notify still returns 404; native links safely
  fall back to the homepage until that page actually serves HTML successfully.
- Portable tests cover real-feed decoding and per-guide 404/503 recovery, upcoming
  null dates/version/duplicates/offline storage, push payload validation/dedup,
  request shape/environment/acknowledgement/errors/token rotation, credential header
  validation, offline unsubscribe/restart and opt-out during in-flight registration.
- Source checks and synthetic signed-entitlement checks are separate from an actual
  signed archive or APNs delivery test. See the recorded Xcode Cloud result for the
  exact candidate revision. No signed upload or App Review submission is implied.
