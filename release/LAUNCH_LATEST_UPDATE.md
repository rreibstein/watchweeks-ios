# Launch the latest WatchWeeks update

All remaining owner actions can be done on iPad using TestFlight and Safari.
No Mac is required with the configured Xcode Cloud pipeline.

## Verified candidate

- Source: bc4d8654813ad8b13e0138cd8807badb924acd88; marketing version 1.0.2.
- Signed Xcode Cloud Archive passed in 4m 54s with no errors or warnings.
- Native permission/analytics UI QA passed at 88307be before the styling-only
  refinement; 85 core tests and nine signed-export validator cases are covered.
- Current TestFlight build number/Apple processing are not readable here.
- TestFlight notes start **Guide alerts — prominent Home button**.
- Public API still reports `available:false, reason:delivery_unverified`.
- Actual APNs receipt, public activation, production analytics ingestion, owner
  privacy confirmation and App Review/publication approval remain open.

## 1. Install and check the exact candidate

TestFlight → WatchWeeks → install/update the build with the notes above. Record
its version/build. If not offered, allow Apple's processing to finish; do not
install an older build to verify the new promo. No reinstallation or data reset.

Check the filled Home Notify me button above Past guides, no city shortcut rail,
opening a guide and release, changing a rating/Seen and finding it in My list.
Briefly go offline and confirm the loaded guide/checklist remains; return online.

Tap Notify me → Allow. No intermediate page should open. Apple will not repeat
permission if already granted. Denial opens system Settings. Wait for Notifications
on (server acknowledgement), then Home → About & privacy → Guide alert preferences
→ Copy test installation ID. This is a non-secret reference, not a device token.
If setup remains pending, keep the app online; do not reset its saved data.

## 2. Verify exactly one real notification through Lovable

Paste into Lovable, replacing the installation reference:

> Finish production APNs verification for com.watchweeks.app using the credentials
> already stored securely. Send exactly one test publication alert to my installation
> [INSTALLATION_ID], for the real singapore-2026 guide, and no other installation.
> Keep public availability and scheduled sending off until I confirm physical receipt.
> If delivery fails, diagnose, implement and deploy the necessary fix; verify the
> published runtime's HTTP/2 transport and production APNs routing. Do not rotate keys,
> create a paid service, send a historical blast, or expose tokens/credentials.
> Return the actual provider outcome and any remaining blocker, not another audit.

Receive the notification on iPad and tap it; Singapore should open. Provider HTTP
200 alone is not evidence of receipt. Briefly background the app for the receipt
test so the normal system banner is visible.

## 3. Activate public alerts after receipt

Only after the actual receipt/opening succeeds, paste into Lovable:

> I received the targeted test on my iPad and tapping it opened Singapore.
> I authorize public guide-alert activation and the publication dispatch schedule.
> Enable capabilities.push.available, retain the existing-guide baseline and
> per-installation deduplication, and verify the deployed endpoints/schedule and
> operational stop switch. Do not send another test, a historical blast or email.
> Preserve website features, users and all existing data. Return live status.

The existing native build reads this capability; activation alone does not require
another native build. If the backend needs a contract change, reconcile and rebuild
before App Review. Public App Store users cannot use the internal TestFlight bypass.

## 4. Confirm real analytics and privacy facts

After two useful interactions and 30 active seconds, an undecided user sees the
optional inline analytics choice. Existing choices are respected. Use Home →
About & privacy to change yours; do not reinstall to force the prompt.

Opt in, open a guide/My list, then inspect the existing PostHog project's Activity
events filtered to `platform = ios_native`. Confirm the actual native events arrive
in the intended project; do not substitute synthetic events or claim downloads.
Turn off analytics and confirm the app still works. Cloud UI QA verified consent
and serialized payloads, not actual production ingestion.

Confirm processor use/retention and retained request metadata for accurate privacy
answers. Ask Lovable/provider for actual facts, with no unrelated audit or website
mutation. Intended first-party product analytics does not become Apple-defined
tracking solely because a processor handles it; verify actual project use.

## 5. Prepare the existing App Store Connect update

Safari → https://appstoreconnect.apple.com → Apps → WatchWeeks.
Use the existing 1.0.2 draft and select the exact tested build. If 1.0.2 has already
been publicly released, stop: the native version must be advanced and rebuilt.
Do not create another application record. Keep the existing name, price, seller
identity and intended storefronts; resolve any account banner Apple actually shows.

App Privacy: use APP_PRIVACY_1_0_2.md; do not retain Data Not Collected.
Proposed source-based answers, subject to the processor facts above:

| Data | Purposes | Linked | Tracking |
| --- | --- | --- | --- |
| Identifiers → Device ID | Analytics; App Functionality for push | Yes | No, only if actual use remains non-tracking |
| Usage Data → Product Interaction | Analytics | Yes | Same condition |

Add any actual additional retained collection/purpose, including promotional use
if applicable. Optional analytics is still disclosed. Owner confirms these factual
and legal representations before publishing the privacy answers.

Use the native policy already linked in the app:
https://github.com/rreibstein/watchweeks-ios/blob/development/native-launch/release/PRIVACY.md

The website's general privacy page does not currently describe native push; using
the dedicated native policy keeps this update consistent without a website change.

What's New:

> Optional alerts for new guides, a clearer Home screen, smoother loading on slow
> connections, and a choice to share usage analytics.

Review notes, after public activation/receipt verification:

> WatchWeeks is an independent guide, with no organizer affiliation or required
> account. Home → Notify me requests Apple's notification permission directly.
> Guide alerts are optional; preferences are in Home → About & privacy. Optional
> first-party PostHog analytics is off until consent, with an early in-app choice
> and later opt-out. No session replay, advertising identifiers or web identity
> linking. Ratings/checklists remain on-device and previously loaded guides work
> offline. The production APNs test was received and its guide opened successfully.

Keep Sign-in required off. Use existing accurate screenshots; replace any that
misrepresent current functionality. App icon, category, age rating and content
rights remain subject to the existing listing and actual content. If Apple asks
export compliance, this source uses Apple's OS encryption, not custom/non-exempt
cryptography. Choose **Manually release this version** and Save.

## 6. Approve and submit the exact tested build

Before submission, confirm version/build, source above, WatchWeeks product name,
the actual seller identity/storefronts, privacy answers, notification receipt and
analytics ingestion. Present any unresolved risk. Explicit owner approval is
required before the agent submits; no submission is authorized by this document.

After approval, the owner/account-authorized operator uses Add for Review →
Submit for Review. This cloud session has no App Store Connect account tools, so
it cannot make that authenticated click or claim to monitor App Review privately.

Optional expedited update request:
https://developer.apple.com/contact/app-store/?topic=expedite

> Please consider expedited review of the WatchWeeks update, Apple ID 6832395283,
> ahead of Singapore's November 12–15 watch events, with public IAMWATCH attendance
> beginning November 13. It improves native guide browsing and slow-connection
> handling for visitors. WatchWeeks is independent of event organizers.

## 7. Release after approval

After Apple's approval, confirm the owner approves public release, then use
Release This Version. Verify the actual new version on the intended storefronts:
https://apps.apple.com/app/watchweeks-watch-event-guide/id6832395283

If review requests changes, bring the exact message to this Codex conversation.
No background App Review monitoring is configured. Approval is not the same as
public release, and listing propagation may take time.
