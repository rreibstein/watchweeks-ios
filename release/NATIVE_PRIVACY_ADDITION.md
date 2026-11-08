# Proposed Lovable privacy-policy addition — do not deploy from this repository

The existing policy was retrieved from https://watchweeks.com/privacy on
2026-11-08. It covers website accounts, analytics and replay but lacks clear native
on-device selections, native consent and no native replay distinction. Owner should
have Lovable add the following after checking actual processing/retention practices:

## WatchWeeks for iPhone

The WatchWeeks iPhone app can be used without an account. Native interest ratings,
seen selections and previously loaded guide data are stored on your device and do
not automatically synchronize with a WatchWeeks website account. Device backups
may include this local information. Deleting the app removes its local copy.

With your permission, the iPhone app uses PostHog to understand guide views and
feature usage, including rating and checklist interactions. This uses a randomly
generated app identifier and public guide, event and brand identifiers, together
with app and device information. The app does not send private notes, email
addresses or purchase prices in analytics. We do not join your native anonymous
identifier to your website account. The initial native release does not use
session replay, advertising identifiers or automatic screen recording.

You can decline analytics when first opening the app or turn it off in About.
Turning it off stops future collection and delivery of pending events while opted
out; transmissions already underway cannot be recalled. Previously delivered
information may remain subject to our retention practices and applicable rights.
The app retrieves public event data and images from WatchWeeks and linked hosting
services, which receive the connection information needed to respond. External
websites opened from the app have their own privacy practices.

Owner must confirm US PostHog processing, retention, processor role and whether
analytics data is ever used/shared for advertising or broker purposes. The existing
policy's aggregate-commercial-use clause needs review against intended native use.

## App Store privacy worksheet — updated for analytics

Do NOT select “Data Not Collected.” Conservative draft: Identifiers > Device ID
(SDK anonymous persistent ID) and Usage Data > Product Interaction / Other Usage
Data, for Analytics. Treat persistent device-linked behavior as linked to a device
for disclosure review even though there is no name/login. SDK manifest's own
unlinked declarations do not decide the whole app's label. Confirm Apple's current
identifier classification and any additional retained connection/IP data with owner.

Tracking is NOT automatically “yes” because PostHog is present, nor automatically
“no” because the identifier is anonymous. The intended use is first-party product
analytics through a processor, without cross-company advertising linkage or data
broker sharing. Verify actual project settings, processor terms and owner use.
If that differs, reassess consent, ATT and privacy labels before release. No tracking
SDK permission or ATT flow is implemented. Apple privacy answers remain a release gate.

Inspected SDK 3.93.6 manifest declares ProductInteraction and OtherUsageData for
analytics (unlinked/no tracking), plus UserDefaults CA92.1, SystemBootTime 35F9.1
and FileTimestamp C617.1. Bundle the SDK's manifest intact. The app uses its own
UserDefaults for consent/first-observed marker and declares CA92.1 separately.
