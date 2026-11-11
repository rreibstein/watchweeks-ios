# Paste into Lovable — WatchWeeks iOS reliability and guide alerts

WatchWeeks is a live, independent native iPhone app. App Store ID 6832395283,
bundle ID com.watchweeks.app. Version 1.0.2 (13) has processed in TestFlight; a
follow-up candidate adds the forthcoming-guide promo and moves About & privacy
to the bottom of Home. Keep website/native terminology and first-party identity
consistent. Native accounts, notes/day-plan synchronization and remote push are
not live. The website remains the primary product.

Evaluate the issue against the existing implementation, choose a practical solution
where one is apparent, and BUILD and test it in the development/preview environment.
Use the Nov 11 audit already completed; do not return another audit or stop after a
plan. Briefly explain the chosen solution alongside the working changes. Continue
independent implementation if an Apple credential or owner decision blocks one part.

Implement publication/feed reliability and the guest-first push backend first.
Sharing and account sync below are compatibility requirements for that work, not
authorization to add native login or a new account system in this change. Preserve
all existing website features, authentication, synchronization, analytics and user
data. Use existing infrastructure. Do NOT deploy, mutate production records, rotate
keys, send notifications/emails, create paid services or expose credentials.
Production deployment and real notification delivery require separate explicit owner
approval. Development/preview implementation and tests do not need another approval.

Return the implemented API contracts, sanitized fixtures, tested behavior, commit/diff,
and exact native integration instructions so Codex can implement the iOS side. Mark
anything unimplemented or unverified explicitly; ask only for genuinely missing access,
credentials entered securely, expenditure or material owner decisions.

## Required corrections to the Nov 11 audit — apply while building

- TestFlight AND App Store builds use production APNs. Development-signed builds
  typically use sandbox; the signed `aps-environment` entitlement is authoritative.
  Test a development installation against sandbox, then an explicitly approved
  staging TestFlight audience against production APNs. Never send to real users
  merely to verify the integration.
- Released v1 native clients require a non-null string `slug`. Do not introduce
  `slug: null` for future editions in the existing index: one such row could break
  decoding of the entire index. Choose a non-null compatible value, preserve current
  IDs/URLs/types, and pin compatibility with fixtures for existing and future guides.
  Keep any nullable or otherwise breaking contract under a new version.
- Replace the hardcoded published-guide allowlist with all published editions.
  Keep the existing account-header placeholder, which the audit confirms already
  works. Do not spend another pass investigating those settled findings.
- Publication must queue promptly after index AND detail serve the guide, with
  scheduled reconciliation as a fallback. Define the state transition so changing
  an upcoming entry to published cannot make the checker miss its announcement.
- Make retries recover after worker crashes: leased claims, per-installation retry
  accounting and bounded backoff. Keep collapse IDs within APNs' 64-byte limit,
  scope token identity to environment/topic, and handle APNs invalid-token timestamps
  without revoking a newer registration. Define registration recovery when a server
  response is lost and ledger deletion/retention when an installation unsubscribes.
  Do not claim exactly-once delivery across a network timeout.
- Derive cache revisions from all data that changes the representation, including
  related events, brands and images; an edition timestamp alone may be insufficient.
- Implement a genuine unsubscribe flow and a stable newsletter URL before presenting
  new native signup promotion as release-ready. Preserve existing subscribers and
  consent. Do not invent retention periods or promise an unimplemented unsubscribe.

## 1. Reliable new-guide push alerts — priority

The website currently says “Be the first to know about new guides,” listing
Geneva (W&W), Las Vegas and British Watchmakers' Day. The native promo matches
those editorial plans without invented dates. User chose reliable publication-time
push, not best-effort background polling. Native notification permission stays
DISABLED until a real server/APNs integration has been verified. No device token
is currently registered or sent. Native APNs registration callbacks, a gated backend
protocol and safe guide-ID routing are prepared; no guessed production API exists.

Build the staged implementation and return the exact implemented versioned contract:

- Expose an additive public upcoming-guide list (stable editorial key, title/city,
  planned/published state, optional dates explicitly null when unknown, canonical
  URL and publication ID when live). Prefer existing public index configuration
  without breaking older v1 clients. Include a capability descriptor that remains
  unavailable until the backend, signing and end-to-end delivery are actually ready.
  A remote switch alone must not enable the current native app: it still needs a
  completed adapter, Push Notifications signing capability and validated build.
- Define the authoritative “published” transition. Queue ONE launch announcement
  only after the public index AND detail endpoints actually serve the guide.
  Draft edits, preview, cron retries, redeploys, cache refreshes and minor edits
  must not generate launch notifications. Unpublishing cancels pending sends.
- Use a transactional outbox or equivalent idempotent mechanism on existing
  infrastructure. Stable publication/notification IDs; per-installation send ledger;
  bounded retries/backoff; APNs collapse/expiration; invalid/410 token cleanup.
  APNs delivery is best effort even with a correct server; never promise guaranteed
  delivery or confuse provider acceptance, delivery and a user's open.
- Guest-first enrollment: no required website account. Document register/update,
  token rotation, preference read, unsubscribe/deletion and retry semantics. Use a
  scoped installation credential stored in iOS Keychain, not a static app secret.
  Validate ownership, payload sizes and content types, restrict the APNs topic/app,
  rate-limit abuse, never expose subscriber enumeration or an arbitrary send API.
  Return the actual security approach, including whether App Attest/DeviceCheck is
  justified. Do not silently turn that into a login requirement.
- Enrollment succeeds only after a server acknowledgement. A permission grant alone
  is NOT a working subscription. Handle denied/revoked OS permission, retry after
  network failure, stale device tokens, reinstall, switching APNs environment and
  opt-out during pending registration. Never display On after a failed registration.
- Separate sandbox and production tokens, signing and test audiences. Use a fake
  provider/staging installation for development; no test messages to real users.
  Apple APNs provider authentication belongs only in server-side secret storage.
  APNs keys are NOT App Store Connect API keys. Reuse an existing appropriate key
  if available; tell owner the exact secure account action if a key is required.
  Never request private .p8 material in chat, reports, app bundles or Git.
- Describe subscription retention/deletion and what device/token/request metadata
  is stored, where, why, and who can access it. Hash/redact tokens in operational
  logs; never send tokens, registration credentials or email to PostHog. Notification
  preferences and PostHog analytics consent are independent. No account matching or
  cross-channel identity merge as a side effect.

Proposed minimal payload (confirm before activation):

```json
{
  "aps": {"alert": {"title": "A new WatchWeeks guide is ready", "body": "Explore the new guide."}, "sound": "default"},
  "type": "guide_published",
  "payload_v": 1,
  "guide_id": "ACTUAL_PUBLISHED_GUIDE_ID",
  "notification_id": "STABLE_PUBLICATION_NOTIFICATION_ID"
}
```

The placeholders above are NOT production records. Native routes only a validated
ID after looking it up in the authoritative public feed; it does not open arbitrary
payload URLs. Return valid/malformed/expired/revoked/stale-cache payload fixtures.
Test cold launch, warm/background launch, permission denial, foreground presentation,
reinstall/token rotation, unsubscribe, duplicate event and delayed/out-of-order sends.
No Critical Alerts, location permission or silent-push polling workaround is needed.
Do not add remote-notification background modes unless a real use case requires it.

## 2. Public data contract — remove brittle native workarounds

Check `GET /api/public/guides` and `/api/public/guides/{id}` against ALL published
website guides, particularly Singapore. Counts of editorial blocks versus models
and repeated brand appearances differ legitimately: explain those separately from
missing records. Return concrete missing IDs and actual examples, not just totals.

- Preserve v1 field types, stable guide IDs and canonical brand keys. Do not truncate
  v1 responses by silently introducing pagination. Propose additive fields or v2
  where required. Publish a machine-readable schema, version/deprecation policy,
  sanitized fixtures and old-client compatibility tests.
- Supply stable release AND individual-model IDs that survive prose edits, including
  brand/event relationships and aliases. The app currently splits editorial prose;
  stable model records would avoid ambiguous prices, photos and duplicate models.
- Add explicit availability (available/sold-out/preorder/unknown) and exhibition
  status (at-show/absent/unknown), scoped to model/variant/event as appropriate.
  Include structured price/currency only when supported, awards with a documented
  shape, updatedAt and source. Unknown is not sold out. One sold-out variant does
  not mean the brand or every model is sold out.
- Model-specific photos must have the exact association, credit/source, dimensions,
  thumbnail/full-size URLs and content version/hash. Keep group photos separate;
  the native app deliberately removed “Other photos from this release group.” Do
  not mix them back into model galleries. Confirm usage rights; do not pass off a
  publication-sourced image as brand imagery because its release cites the brand.
- Add withdrawn-image/record tombstones or a revocation manifest, replacement and
  cache-invalidation rules. Never keep a withdrawn asset indefinitely in future
  offline caches. Editorial image removal must not delete users' saved selections.
- Return validated structured venue/address and optional coordinates, canonical
  organizer URL, guide/event IANA timezone, local public opening intervals,
  invitation/VIP intervals separately, cancellation/postponement state and updatedAt.
  Resolve known conflicting hours with organizer evidence. Overnight/DST/multi-day
  schedules and missing hours require fixtures. No invented dates, venues or times.
- Calendar export needs the complete public schedule, never a single guessed time.
  Distinguish a daily recurring schedule from varying hours; preserve exact intervals
  and expose editorial notes. No UTC-midnight date-only conversion bugs.
- ETag/Last-Modified, Cache-Control and CDN invalidation should be documented. A push
  must not announce a guide before cached index/detail are ready. Define old-cache
  fallback, status codes, version errors, size limits and retry/rate-limit behavior.
  Use cacheable responses without leaking personalized/private data.
- Add safe operational observability for publish/feed/push failures and a rollback
  plan. No synthetic notifications or analytics into production to prove success.

## 3. Corrections, newsletter and website parity

Return stable public mobile-friendly correction, feedback and Notify me/newsletter
URLs, preferably real section anchors or dedicated routes. The native app currently
opens the home page for email signup because no reliable signup anchor was confirmed.
Reuse existing forms, account state and email-consent flow. No native collection of
email is added by this handoff. Provide success/error behavior and privacy wording.
Skip new surveys unless already available and genuinely useful.

The Nov 11 audit confirms the website account header already has a stable neutral
44-by-44 placeholder. Preserve it and its existing loading/session behavior.

## 4. Shared picks and universal links — later, additive

Native currently shares text/guide URLs, not synced selections. Propose a versioned
HTTPS shared-picks route with opaque IDs, explicit content, expiry/revocation and
retention. No private notes, emails or account IDs in public shares. Receiver previews
before importing and never overwrites existing local data automatically.
Return valid/expired/malformed fixtures, useful browser fallback and exact AASA
configuration for supported paths only. Obtain the REAL Apple signing Team ID;
never substitute an ASC team UUID. Bundle ID is com.watchweeks.app. Do not hijack
account/OAuth callbacks or advanced website-only tools. Keep test hosts separate.

## 5. Same-account sync — separate staging proposal

Document actual existing auth providers/session refresh/sign-out/account deletion.
Propose authenticated owner-scoped APIs for ratings, shortlist and Seen first;
notes/day plans later. Preserve guest browsing and the current local selections.
Use revision preconditions, idempotent mutations, stable IDs/aliases and tombstones.
Define merge/conflict behavior without silent overwrites. Cover offline retries,
account switching, deletion and export. Supply a test account only through secure
staging access. Assess native login/Sign in with Apple and account-deletion App
Review requirements before enabling it. Do not create a second account system.

## 6. Privacy and handoff deliverables

Confirm actual guide/image/PostHog IP metadata, retention, processors, regions,
access and sharing practices. GeoIP disabled does not establish IP deletion. Do not
change website analytics, replay, dashboards or shared project settings. Native
analytics is a separate explicit opt-in, uses platform=ios_native and no website
identity linking. Push permission is a separate choice, not analytics consent or ATT.

Return: implemented API/schema + sanitized fixtures; preview implementation diff;
existing resources reused; exact secure missing setup; native adapter/capability
changes; privacy copy/ASC data-purpose worksheet; QA matrix including old clients;
publication rollback; and deployment steps requiring separate owner approval.
Do not deploy or send messages until that approval is given.
