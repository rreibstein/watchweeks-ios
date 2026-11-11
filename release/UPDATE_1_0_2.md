# Follow-up source changes after build 13 (new build required)

- About & privacy is now at the bottom of Home/Events, removed from My list.
- Forthcoming-guide promo mirrors watchweeks.com: Geneva (W&W), British Watchmakers'
  Day and Las Vegas. It hides entries once matching public guides are available.
- The live upcoming feed supplies planned guide titles without invented dates.
- The signed push client uses a Keychain-generated credential and durable pending
  registration, exact lost-response recovery, token rotation and unsubscribe retries.
- Public alerts remain gated by capabilities.push.available. An explicit TestFlight
  path permits enrollment and a copyable non-secret test installation ID before
  public activation; provider sending belongs to Lovable. No notifications are sent here.
- Push privacy disclosures are included; optional PostHog consent remains separate.
- Latest follow-up: optional analytics is offered inline after two meaningful
  interactions and 30 seconds of active use. “Not now” persists, existing choices
  are respected, and pre-consent actions are never sent later. Settings remains
  available for changing the choice; no launch interruption or mandatory opt-in.

This is NOT in TestFlight build 13. Use Xcode Cloud's next unused build number for
this follow-up, retaining marketing version 1.0.2 while that update is pending.
The former signed-client candidate passed Xcode/simulator checks; the final recovery
contract has 72 portable tests and requires a fresh cloud pass and signed upload.
Physical receipt must be confirmed before public availability. Do not submit for
App Review or publish without the exact-build owner approval gate.

# WatchWeeks 1.0.2 candidate

Source build number defaults to 1. Before upload, check App Store Connect and use
an unused valid build number (Xcode Cloud may assign a different number). Do not
replace/rewrite the approved 1.0.1 binary or overwrite newer Mac changes.

## Changes

- Opt-in PostHog usage analytics in Home > About & privacy. Off by default;
  no launch prompt, replay, ad identifier, account linking or automatic capture.
- Durable bounded queue for previously consented events; opt-out clears it and
  cancels delivery. No retroactive analytics about actions performed while off.
- Calendar offers Add to Calendar only, including all public event days. The
  single-day chooser is removed. Restricted sessions remain excluded; hours and
  recurrence remain event-local. Existing Apple calendar entries are not modified.
- System tab bar no longer inherits the branded body font that can inflate item
  labels/selection geometry. Retains native Liquid Glass, four labels and hit areas.
- Home cards and city shortcuts show public-event countdowns: In N days, Tomorrow,
  Opens today, Happening now or Looking back, using event-local calendar days.
- Earlier removal of the other-release-group photo galleries is preserved.

## Validation completed in cloud

42 portable XCTest tests passed in this cloud revision. Portable tests cover
analytics payload/consent, disk-backed retry, bounded queue, foreground deduplication,
in-flight opt-out, public opening countdowns, local midnight and daylight saving.
Static source/resource checks and native-source syntax parsing are separate from
actual iOS compilation. No Xcode build, signed upload, TestFlight or production
analytics delivery has been performed here for this revision.

## Mac / Xcode Cloud acceptance (required before submission)

1. Fetch development/native-launch and inspect latest revision. Preserve local work.
2. Run scripts/verify-macos.sh. Fix iOS build/UI failures, including new Core module.
3. The shared scheme now runs analytics consent QA by default, using a
   Debug/simulator-only in-process receiver with a dummy key. No local server or
   production event is needed. Confirm testOptionalAnalyticsConsent passed, not
   skipped. It exercises the real preference controls and serialized payloads.
4. TestFlight Release: verify installed version/build; check whole-event Calendar,
   all four navigation selections at normal/large text (iPhone/iPad), current guide
   countdown, old selections after upgrade, and absence of extra-group galleries.
5. Inspect consent/opt-out and offline retry on device. Validate consented production
   delivery only under owner's authorization; do not spam real project with tests.
6. Update App Store Connect App Privacy before selecting this build. It now collects
   optional Identifiers > Device ID and Usage Data > Product Interaction for
   Analytics, linked to the app's pseudonymous identifier. Do not reuse “Data Not
   Collected.” No tracking is intended; owner must confirm actual PostHog project
   use/retention/processor practices do not constitute Apple's defined tracking.
7. Confirm the app privacy URL resolves to the updated policy. The website is not
   changed by this release. Website analytics/account behavior remains separate.
8. Present exact source, version/build, privacy answers and residual risks to owner.
   Only explicit approval permits App Review submission or public release.

## What's New draft

See how soon the next public watch event starts, add an event's full public schedule
to Calendar, and enjoy cleaner navigation. Optional usage analytics can be enabled
or disabled in About & privacy. We've also simplified new-release photo galleries.

## App Review notes draft

WatchWeeks remains guest-first, with local ratings/shortlist/Seen and public guide
content. Optional PostHog product analytics starts only when a user explicitly opts
in at Home > About & privacy > Learn about usage analytics > Choose a preference
> Share usage. All features work while it is off. No session replay or advertising
tracking. Turning it off purges pending analytics and cancels delivery; already
in-flight transmissions cannot be recalled. No private notes, email, rating values,
Seen values, purchase prices or website account IDs are captured.
Calendar uses Apple's editor for all public days of the chosen event, with local
timezone and notes. For a schedule with varying hours it uses a free all-day span
with the actual public hours in notes. No existing calendar data is read or edited.
