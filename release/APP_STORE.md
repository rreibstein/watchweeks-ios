# WatchWeeks 1.0 App Store handoff

Target public availability before Friday, November 13, 2026, 11 a.m. Singapore
time (Thursday, November 12, 10 p.m. US Eastern). Aim to submit by Monday,
November 9, and release as soon as approved. Apple can take up to 24 hours to
make a released app available. Check the Singapore storefront after release.

This is an iPhone-only, free candidate with public guides, local visit planning
and offline access to previously loaded guides. The iPhone app contains no
product analytics SDK, session replay, ads, tracking, sign-in or purchases.
Account opens the existing website in the system browser.

## Launch decisions

- Include Singapore, the EU and other intended eligible storefronts. In
  **Business → Agreements → Compliance → Digital Services Act**, declare
  your status before submission. Based on the current free community project,
  non-trader is reasonable if WatchWeeks is outside your trade or profession
  and paid sponsorship is only a future possibility. If WatchWeeks is already
  operated commercially or professionally, assess trader status even if it
  is free. The website's invitation to sponsors is one factor. Its wording
  does not determine the outcome.
- If you qualify as a non-trader, select **I'm not a trader under the DSA or
  I don't plan to distribute in the EU**. Set storefronts separately in
  **WatchWeeks → Pricing and Availability → App Availability**. The combined
  wording does not require non-traders to exclude the EU.
- A trader must provide contact details and may need supporting documents.
  Resolve this in parallel with build preparation. Apple's published criteria
  for expedited review focus on urgency and reviewer availability. DSA status
  is a submission/compliance requirement, and pending verification can affect
  EU availability. If it actually blocks submission and timing takes priority,
  release outside the EU and add those storefronts once compliance is resolved.
- A free app with no in-app purchases uses the active Free Apps Agreement.
  Reassess DSA status before starting paid sponsorship, even if the sponsorship
  is website-only and the app helps promote or drive traffic to the business.

[Apple's DSA requirements](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements)
· [App availability](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/manage-availability-for-your-app-on-the-app-store)

## 1. Create the App Store Connect record

1. Sign in to [App Store Connect](https://appstoreconnect.apple.com/). If Business
   shows a pending Apple Developer Program agreement, the Account Holder
   reviews and accepts it. Use the existing WatchWeeks record if one exists.
2. If needed, register an explicit App ID under Apple Developer → Certificates,
   Identifiers & Profiles → Identifiers → **+** → App IDs → App. Use
   `com.watchweeks.app`, description **WatchWeeks**, and the existing owner team.
3. In App Store Connect → Apps → **+** → **New App**, select iOS, English (U.S.),
   the registered bundle ID and SKU `watchweeks-ios`. Try **WatchWeeks** as the
   public name. If unavailable, try **WatchWeeks: Watch Event Guide**.
4. Copy the numeric Apple ID from **App Information** to make the direct product
   page link after launch. Keep the business-card QR pointed to the live
   [Singapore guide](https://watchweeks.com/singapore).

## 2. Archive and upload from Xcode

1. Open `WatchWeeks.xcodeproj` from the verified `development/native-launch`
   checkout. In **Xcode → Settings → Accounts**, add your Apple Account if it
   is missing. Choose the enrolled team for the WatchWeeks target in
   **Signing & Capabilities** and leave **Automatically manage signing** on.
   Keep `com.watchweeks.app` unless the actual existing app record uses a
   different ID. Avoid committing personal signing settings.
2. Confirm **Version 1.0.0**, **Build 1** if unused, or the next unused build
   number if App Store Connect already has a build. Leave Xcode's automatic
   version/build number adjustment off during upload if you set them explicitly.
3. Select **WatchWeeks** and **Any iOS Device (arm64)** in the toolbar, then
   **Product → Archive**. In Organizer, select the new archive and use
   **Validate App** if offered. Resolve any validation errors.
4. In Organizer choose **Distribute App → App Store Connect → Upload**.
   Use the regular App Store Connect upload so the same build can be tested
   and submitted. Keep upload symbols enabled if offered. Wait for processing
   and check App Store Connect for any build issues. This step uploads the
   build for private preparation. App Review starts in step 5 below.

[Apple's Xcode distribution instructions](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)

## 3. Do one physical iPhone pass on the exact build

In App Store Connect → **TestFlight → Internal Testing**, create or use an
internal group, add yourself and the processed build, and install it from
TestFlight on the iPhone 13 Pro running iOS 17 or later. If the upload is still processing, start the
smoke test by selecting a connected iPhone in Xcode and choosing **Product →
Run** with the scheme's Run configuration set to Release, then confirm the
processed build in TestFlight. For a wired run, unlock the iPhone and accept
Trust This Computer. If Xcode asks, enable Developer Mode in iPhone
**Settings → Privacy & Security → Developer Mode**, restart and confirm.

- Open a fresh install. The Events tab should appear without an account or
  analytics prompt. Open Singapore, then Golden Hour and IAMWATCH.
- Confirm Singapore dates, venue, public access, hours and an official link.
  Open the itinerary planner, select Friday then Saturday, and copy a plan.
- In an event, shortlist a real brand, set an interest rating and mark it seen.
  Open My list. Force-quit and relaunch to confirm those choices persisted.
- Enable Airplane Mode and switch Wi-Fi off. Relaunch and open the cached
  Singapore guide and My list. Turn connectivity back on and refresh.
- Open New releases and a release detail with a retained brand-credited photo.
  Confirm the photo and credit appear. Open Account and verify the
  existing website opens in the browser. Return to the app and verify
  **Account → About & privacy → Privacy policy** loads in the browser.
- Confirm the icon, type, native tabs and back navigation on the device.
  Record iPhone model, iOS, build number and pass/fail. A reproducible crash,
  lost selection, blocked guest flow or incorrect core schedule holds submission.

[Apple's internal TestFlight instructions](https://developer.apple.com/help/app-store-connect/test-a-beta-version/add-internal-testers)

## 4. Fill the version page while the build processes

| App Store Connect field | Entry or action |
| --- | --- |
| Subtitle | Independent watch event guide |
| Category | Lifestyle |
| Price | Free |
| Availability | Include Singapore, the EU and other intended eligible storefronts. See Launch decisions for a compliance fallback. |
| Support URL | `https://watchweeks.com` (public footer has the correction/contact path) |
| Privacy Policy URL | `https://github.com/rreibstein/watchweeks-ios/blob/development/native-launch/release/PRIVACY.md` after owner confirms the wording and feed and image-host log retention. This matches the in-app link. |
| Copyright | 2026 Reed Reibstein |
| Age Rating | Complete the current questionnaire from the actual app. Native guides have editorial text and credited photos, with no messaging, public posting, ads or native web browser. Check Apple's wording on external links. |
| Content Rights | Answer Yes for third-party content. The app displays brand-credited watch photos and excludes images with publication provenance. Confirm the source and applicable native usage terms for the retained photos and keep documentation ready. The listing should only show photos with verified listing rights. |
| Export Compliance | The candidate uses system HTTPS, with no app or third-party encryption library. The build declares no non-exempt encryption. Answer any remaining territory questions using Apple's questionnaire. |
| App Privacy | The app stores visit data locally. Confirm feed, CDN and image-host logging and retention before deciding what to disclose. See the request below. Apple excludes data discarded after servicing the request in real time. Disclose relevant retained data and purposes. The app has no tracking. |
| Screenshots | Use actual, final-build iPhone Dynamic Island medium PNGs. See [screenshot instructions](SCREENSHOTS.md). |
| App Review Information | Provide a real contact name, phone and email. Leave Sign-in required off. Paste the review notes below and replace the build placeholder. |
| Version Release | Manually release this version. Be ready to release as soon as Apple approves it. |

**Read-only hosting question for Lovable**

> For requests from the iPhone app to `watchweeks.com/api/public/guides`,
> `watchweeks.com/api/public/guides/<id>`, and the guide photo paths under
> `watchweeks.com/__l5e/assets-v1/`, identify what production Cloudflare,
> Lovable and any connected logging or storage service retain after the
> request. Check IP, user agent, resource path, cookie or other identifier,
> analytics use, retention duration, who can access it and deletion process.
> Cite the settings or provider docs and mark unknowns. Do not change or
> deploy anything.

The live guide and photo responses set Cloudflare's `__cf_bm` bot-management
cookie. All image URLs in the five live guides resolved to `watchweeks.com`
at the time of this check. The public response does not establish log
retention or prove that every underlying provider discards the data.

[Apple's definition of collection](https://developer.apple.com/app-store/app-privacy-details/)
· [Cloudflare cookie documentation](https://developers.cloudflare.com/fundamentals/reference/policies-compliances/cloudflare-cookies/#__cf_bm-cookie-for-cloudflare-bot-products)

**Promotional text**

Explore watch events worldwide. Browse participating brands, build your
must-see list, and discover new releases with WatchWeeks.

**Description**

Find your next watch event with WatchWeeks, an independent guide for enthusiasts.
Explore city guides, browse fairs and venues, discover participating brands, and
see new watch releases where available.

- Plan your Singapore fair visits around opening hours and travel time.
- Shortlist brands, rate your interest and keep track of the brands you've seen.
- Browse previously loaded guides and your checklist offline.
- Share guide links and copy your itinerary.

No account is required. Your personal selections stay on your device. Event
schedules may change, so confirm important details with the organizer.
WatchWeeks is independent of the listed events and brands.

**Keywords**

`watches,watch fairs,horology,city guide,checklist,watch releases,itinerary`

**Review notes**

> WatchWeeks 1.0.0, build [build number], is an independent watch fair guide.
> No account or purchase is required. In Events, open Singapore, then Golden
> Hour Singapore for the venue, hours and exhibitor checklist. Shortlist a
> brand, mark it seen, then open My list in the tab bar. Back in Singapore,
> open “Plan your fair day” to make and copy an itinerary.
>
> The app saves personal selections and previously loaded guides on-device.
> It retrieves public, read-only guide data. This version is free and has no
> ads, sponsored placements or in-app purchases. Account is an optional link to
> the existing WatchWeeks website in the system browser. The iPhone app
> has no native login or synchronization.
>
> The independent editorial guide displays product photos credited to
> their brands. The app filters out photos with publication provenance.
> Photos load from watchweeks.com and are not embedded in the app binary.
> We can replace or remove them from the hosted guide without a binary
> update. Review About & privacy for the contact and privacy policy.
>
> The release is time-sensitive. Golden Hour Singapore opens Friday,
> November 13, 2026 at 11 a.m. SGT and runs through November 15. The app helps
> visitors plan around Golden Hour, IAMWATCH and Spring Sprang Sprung.
> Guide: https://watchweeks.com/singapore
> Organizer schedule: https://goldenhour.delugs.com/singapore

## 5. Submit, request expedited review, then release after approval

1. After physical-device QA, privacy and rights clearance, select the tested
   build on the 1.0 version page. Save the completed listing and use
   **Add for Review → Submit for Review**. Only the owner or authorized release
   manager should take this step.
2. With the app in **Waiting for Review**, use Apple's **Request an Expedited
   App Review** form. Select WatchWeeks and iOS. State that it is a first release
   for the November 13–15 Singapore fairs and repeat the opening time and links
   from Review Notes. Apple's decision and turnaround are discretionary.
3. Watch App Review messages. If Apple requests information or a fix, resolve
   that exact request. At **Pending Developer Release**, use **Release This
   Version → Confirm**. Verify availability on the Singapore storefront.

[Submit an app](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app)
· [Request expedited review](https://developer.apple.com/help/app-review/after-submitting-for-review/request-expedited-review/)
· [Release timing](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/select-an-app-store-version-release-option)
