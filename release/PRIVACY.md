# WatchWeeks iPhone app privacy policy

WatchWeeks is operated by Reed Reibstein in the United States. This policy covers
the WatchWeeks iPhone app. You can contact us at reed.reibstein@gmail.com with
privacy questions or requests about your data.

## What stays on your device

The app saves your shortlist, ratings, seen marks, reactions and buying
preferences in its local app storage. It also saves copies of previously loaded
guides for offline access. The app does not upload your selections, use them for
advertising or associate them with a website account. The iPhone app has
no accounts or synchronization. Local data stays in app
storage until you delete the app. iOS may include app data in device backups
under your Apple settings. You can remove backups using Apple's device or iCloud
backup controls.

## Version scope

Versions 1.0.0 and 1.0.1 do not include native product analytics. The optional
analytics described below applies to version 1.0.2 and later only when you enable
it. All versions can retrieve public guides and images as described below.

## What leaves your device

The app retrieves public event guides and watch photos over HTTPS. WatchWeeks
and the providers that host the guides or photos receive request information,
such as your IP address and the requested resource, to deliver this content and
operate and protect the service. Cloudflare uses a bot-management cookie to
protect the guide and photo endpoints. These requests do not carry your checklist
or ratings. The app offers optional usage analytics through PostHog. It is off until
enabled through an optional in-app prompt after early engagement, or in About &
privacy (at the bottom of Home in newer builds, or under My list in earlier builds).
“Not now” keeps it off and prevents repeated prompts. The app stores only local,
capped activity counts and active-use duration to time the prompt; it sends none
of that pre-consent activity to analytics. When enabled, the app sends a random installation identifier,
app version and build, public guide/event/release identifiers, and events such as
views, use of the rating and Seen controls, visits to My list, guide sharing and
opening WatchWeeks website links. It does not send the selected rating or Seen
value. It does not join these events to an account or use them for advertising or
session replay. Turning analytics off clears queued events and cancels pending
requests. Previously consented events can be stored on-device for delivery after
connectivity returns, up to a bounded limit. Transmissions already in flight cannot
be recalled. Information already delivered remains subject to the service's
retention policy.

If you use the iOS share sheet or copy a plan, you choose where to send or paste
that information. If you follow a link, your browser opens the destination. The
[WatchWeeks website privacy policy](https://watchweeks.com/privacy) applies in
the browser. Website sign-in, website analytics, and website session replay
are features of that separate website. Other websites have their own policies.

## Forthcoming guides and optional notifications

The native Home screen can show editorial notes about forthcoming guides. Email
signup opens the existing WatchWeeks website, whose form and privacy policy apply;
the native app does not collect an email address for that signup.

Guide-publication notifications are optional and available only in supported builds
after the delivery service is activated. Earlier builds without this feature do not
register for push. TestFlight may offer a delivery-verification option before public
activation. The app asks Apple's permission only after you choose to enable alerts.

If you enable alerts, the app sends its APNs device token, app and iOS versions,
and guide subscription preferences to WatchWeeks over HTTPS. WatchWeeks creates
an installation record and uses Apple Push Notification service to deliver alerts.
An installation credential is kept in this device's Keychain, excluded from iCloud
Keychain synchronization, to manage that subscription. Tokens and subscription
credentials are not sent to PostHog or joined to website accounts. Network providers
also receive the request information needed to serve these requests.

Turning alerts off requests deletion of the installation, device token and associated
send ledger. If the device is offline or the service is unavailable, the app saves
the unsubscribe request and retries when reopened online; alerts may still arrive
until deletion is confirmed. Operational security records are separate from the
subscription. Notification delivery is best effort, not guaranteed. Notification
preferences and usage analytics are independent; neither is required to use guides
or your checklist.
