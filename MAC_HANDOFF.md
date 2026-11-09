# Continue WatchWeeks in Codex on the Mac

Cloud implementation branch: `development/native-launch` in `rreibstein/watchweeks-ios`.
See `git rev-parse HEAD` after fetching for exact revision, and docs/STATUS.md for
verified versus unverified capabilities. Never work in the website repository.

## Minimal Mac steps

1. Install current **stable Xcode 26 or newer** from Apple's supported download
   channel/App Store (no beta). Check macOS/hardware compatibility and available
   storage first; never purchase hardware or services automatically.
2. Open Xcode once; accept license and install iOS platform/simulator components.
3. Open this GitHub repository on the Mac with Codex. Clone if absent:
   `git clone -b development/native-launch https://github.com/rreibstein/watchweeks-ios.git`
   then `cd watchweeks-ios`. Do not reset existing work.
4. Paste the continuation prompt below into Codex. It owns troubleshooting.

## Codex continuation prompt

> Continue WatchWeeks iOS launch execution in this checkout. Read MAC_HANDOFF.md,
> docs/STATUS.md, docs/API_CONTRACT.md, release/APP_STORE.md and git status. Preserve
> changes; never touch or deploy watchweeks.com. Confirm branch, origin and revision.
> The actual v1 feed, detail loader, Singapore/Austin fixtures and first-party clock
> icon are now integrated. Revalidate live responses; read docs/FEATURE_PARITY.md
> and release/APP_STORE.md. Keep the 1.0 candidate free of native product analytics
> and replay. Check native
> typography/layout against captured mobile-web references and fix discrepancies.
> Run scripts/verify-macos.sh using stable Xcode 26+ and fix every build/test failure.
> Validate real offline checklist, date zones, accessibility and device behavior;
> capture actual screenshots per release/SCREENSHOTS.md and current Apple requirements.
> Continue autonomously through release preparation. Verify developer enrollment,
> request secure account authorization only when needed, configure actual team and
> available bundle ID, and prepare signed archive. Never buy membership or trigger
> paid services without authorization. Prepare and upload a build when account access
> allows, confirm processing, and complete reversible ASC preparation. Obtain explicit
> owner approval for exact first App Review submission and for public release. Do not
> imply Xcode/simulator/archive/upload results until observed. Commit/push fixes to
> the dedicated iOS branch. Keep this Codex project as source of truth and continue
> review fixes here; do not send the owner to another ChatGPT conversation.

## Verification and integration

`xcodebuild -version` and `xcrun --sdk iphoneos --show-sdk-version` must show current
accepted release tools. Select Xcode in Settings > Locations or use `xcode-select`
with authorized system access. Run `scripts/verify-macos.sh`. Optionally supply
WW_SIMULATOR_ID from `xcrun simctl list devices available`.
This runs SwiftPM tests, package resolution, simulator build and UI tests, saving
xcresult bundles. The manual Actions workflow uses macos-15/Xcode 26.3 from the
published runner image inventory observed in cloud; recheck availability. Verify
private-repo free allowance before dispatch. Never assume billing eligibility.

Manually test both appearance modes, large accessibility text, VoiceOver, fast
seen toggles, relaunch, airplane mode after loading guides, fresh install offline,
failed images, bad feed, empty feed, multiple cities and event-local time while
phone timezone differs. Test on an iPhone before release; iPad access alone is not
iPhone physical-device validation. Simulator screenshots must show live public data.

## Apple account and signing (owner securely authenticates)

Check https://developer.apple.com/account for active Apple Developer Program
membership. If missing, the next action is owner enrollment using Apple's
Developer app/site; enrollment fee requires owner approval. Do not request passwords,
2FA codes, certificates/private keys or identity documents in chat. Owner signs
into Xcode Settings > Accounts with their Apple Account. Verify team and role
permissions in App Store Connect. Resolve pending agreements directly with Apple.

In Xcode, open WatchWeeks.xcodeproj > WatchWeeks > Signing & Capabilities. Select
the actual team with automatic signing. Register `com.watchweeks.app` if available;
if unavailable, choose an owner-approved replacement and update project settings.
The project intentionally has no hard-coded team. No entitlements required.
Create one ASC iOS app record using available name, matching bundle ID, English
primary language and a stable SKU (proposal watchweeks-ios-001). Verify actual seller.

## Archive, upload and review

After all gates pass, set version/build correctly, select Any iOS Device (arm64),
Product > Archive. Or `xcodebuild -project WatchWeeks.xcodeproj -scheme WatchWeeks
-configuration Release -destination 'generic/platform=iOS'
-archivePath release/archives/WatchWeeks.xcarchive DEVELOPMENT_TEAM=ACTUALTEAM archive`.
Do not disable signing for the release archive. Use Organizer > Validate App then
Distribute App > App Store Connect > Upload with secure Xcode authentication.
Confirm upload and build processing in ASC; preserve build number and source SHA.
Resolve validation and export-compliance questions using actual app behavior.
No custom cryptography is implemented, but verify Apple's applicable declaration.

Fill listing using release/APP_STORE.md after actual feature acceptance; verify
support/privacy URLs and native policy coverage. Apply worldwide territories and
English metadata only after regional/legal checks. Owner chooses EU DSA trader
status; do not infer it from free pricing. Trader contact verification may be
required for EU distribution. Complete age/privacy questionnaires with owner.
Upload screenshots per current ASC dimensions, select processed build, complete
review contact and notes, choose manual release.

Before first submission present ONE concise approval gate: exact build/SHA, name,
bundle/team/seller, privacy disclosures, territories/price, screenshots and remaining
risks. Only after explicit approval click Submit for Review. Request expedited
review through Apple's supported form using release draft with verified dates.
Approval/expedite timing is not guaranteed. Ask separate final publication approval
before manual public release. Verify actual store URL and availability afterward.

## Review feedback and maintenance

No background monitoring is configured. Owner should bring Apple's exact review
message, version/build and ASC status back into this Codex project. Interpret it,
fix and retest as needed, increment build, upload and request any required approval.
Never claim approval or public availability from an upload success. After release,
record URL and verify intended regions. New events should arrive via the public
feed; perform fixture/contract regression checks when API changes. Maintain a small
monthly dependency/toolchain check, quarterly device/privacy review and build-number
log. Do not change website data or add private backend access.

## Current environment update
The live public API is integrated. See docs/STATUS.md for Mac validation and
release/APP_STORE.md for signing, device testing and submission steps. The
first release has no native product analytics or replay.
