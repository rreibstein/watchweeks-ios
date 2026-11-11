# App Store Connect privacy worksheet — 1.0.2 and follow-up candidate

Do not reuse the launch release's “Data Not Collected.” Version 1.0.2 (13) adds
optional native PostHog usage analytics. The later Home/promo candidate retains
that analytics behavior; guide push delivery is DISABLED until backend integration
and APNs verification. No website settings or App Store Connect fields were changed
by this worksheet. Owner confirms the declarations before submission.

## Current collection

| ASC category | Purpose | Linked | Tracking | Actual behavior |
|---|---|---|---|---|
| Identifiers > Device ID | Analytics; App Functionality in the push-enabled follow-up | Yes, conservatively device-linked | No, subject to project-use verification below | Random analytics ID after analytics opt-in; APNs token and guest subscription ID only after alert enrollment |
| Usage Data > Product Interaction | Analytics | Yes, linked to that random identifier | Same condition | App/guide/event/release views, rating-control/Seen-control use, My list, successful guide shares and website transitions |

Public guide/event/release IDs and app version/build describe those interactions.
No chosen rating or Seen value, private notes, search text, email, account IDs,
purchase prices, photos, precise location, contacts or advertising ID is included
in native analytics. Native/web identities are not joined. No session replay or
automatic screen capture. No native account creation/synchronization.

Analytics is off by default and optional. Home > About & privacy explains the
choice before enabling; turning it off purges queued events and cancels delivery.
Existing 1.0.2 (13) has the same controls under My list instead. Consented events
can be queued locally for retry, bounded at 100. Already in-flight transmissions
cannot be recalled. Re-enabling creates a new identifier. Data already delivered
is subject to actual processor retention and rights requests.

The native privacy manifest declares Device ID and Product Interaction for
Analytics, linked, not tracking; UserDefaults reason CA92.1. Source declarations
do not substitute for accurate ASC answers and archive verification.

## Owner/provider facts to confirm

“Not used for tracking” reflects intended first-party product analytics, without
cross-company ad targeting/measurement or identifiable-data-broker sharing. Verify
actual existing PostHog project use, processor settings/terms and retention. Do not
infer this from lack of login, SDK absence or $geoip_disable. If actual use meets
Apple's tracking definition, reassess disclosures/ATT before release.

Lovable/provider should confirm whether IP/request metadata is retained on guide,
image and PostHog endpoints, purposes and retention. GeoIP enrichment being disabled
does not prove IP addresses are discarded. Add any actual retained collection to
ASC under Apple's current definitions; do not invent retention periods.

## Notifications — push-enabled follow-up

The forthcoming-guide card offers website guide updates and signup options without
claiming that a newsletter sender is activated. The app collects no newsletter email.
Build 13 has no push enrollment. The newer integrated client can enroll after an
explicit action, OS permission and a live backend capability. A signed TestFlight
build may verify delivery before public activation; App Store users require the
remote availability gate. The privacy manifest adds App Functionality to Device ID.

Before App Review: disclose APNs device token and scoped installation/subscription
identifiers under Device ID for App Functionality, and confirm actual hosting,
request metadata and retention. The app sends app/iOS version for enrollment;
classify any diagnostic collection according to its actual retained use. Determine whether Developer
Advertising or Marketing also applies to the actual notification content. OS
notification permission is separate from PostHog consent and Apple's ATT policy.
No push token or registration secret may enter PostHog. Update this worksheet,
in-app policy and ASC answers before shipping the enabled feature.

TestFlight's email-linked beta diagnostics are Apple's testing service and are
separate from the native app's anonymous optional PostHog collection.
