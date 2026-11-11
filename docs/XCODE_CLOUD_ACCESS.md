# Xcode Cloud access — verified operational knowledge

Observed 2026-11-11: this Linux Codex Cloud session CAN initiate WatchWeeks iOS
verification through Git branch promotion. Do not assume a local Mac or an Apple
API token is required just because xcodebuild is unavailable locally.

Repository: rreibstein/watchweeks-ios. App Store Connect app: 6832395283.

- Promote an intended source commit with an ordinary fast-forward push to
  ci/cloud-candidate. This started the Xcode Cloud check named
  `WatchWeeks | WatchWeeks Verify | Test - iOS` for commit 46a3460.
- Read check status via HTTPS GET:
  https://github.com/rreibstein/watchweeks-ios/commit/<FULL_SHA>/checks
  This works here even though gh api/api.github.com returned Forbidden. Use the
  actual HTML status text, not the presence of 'Xcode Cloud' alone. Failed checks
  may include useful annotations or links. Apple-only detailed logs may still
  require owner access; inspect what's available before declaring a blocker.
- The configured upload source branch is release/cloud-upload. Preserve its
  history and promote the same verified source SHA without force-pushing.
  Observe the resulting archive/upload check, then verify processing separately.
- GitHub source read/push authentication is provided by the environment. Do not
  request a personal token merely because GitHub API or Apple API isn't connected.
- Do not use unrelated feature branches as release source. Do not submit for
  App Review or publish without owner approval. Never infer TestFlight processing
  or exact build number solely from a successful Git push or simulator test.

First verification run start observed on GitHub: 2026-11-11 06:49:12 UTC.
Completion, signed upload and Apple processing must be recorded when observed.
See release/REMOTE_BUILDS.md for the configured workflow separation and safety gates.

## Confirmed execution, 2026-11-11

- 46a3460: initial iOS verification succeeded, zero reported errors/failures/warnings.
- 08fcc4c: a localhost listener pre-build hook failed in Cloud; do not restore it.
- 8b27440: mandatory self-contained analytics consent UI QA and verification
  succeeded (5m 2s), zero reported errors/failures/warnings. Test receiver is
  Debug/simulator-only; the actual serialized capture payload is exercised without
  an external listener or production events. Source/core tests total 42.
- Verified source 8b27440f498cc04f33963c9ac67796efa3575fe1 was promoted to
  release/cloud-upload. Its Archive action started at 07:15:24 UTC. Completion,
  distribution and exact processed build number are not yet confirmed in this note.
- The later 48c6451 only restores default shared test-scheme environment settings;
  it does not change the Release app functionality. The upload intentionally uses
  the exact verified source, not a different unverified tip.

GitHub's commit/checks page can default to the Verify run even when Archive is
running. Discover the individual check links in the sidebar: fetch its actual
/suites/<id>/show_partial data-url, then follow /runs/<check_run_id>.
For this candidate:
- Verify: https://github.com/rreibstein/watchweeks-ios/runs/130380850058
- Archive: https://github.com/rreibstein/watchweeks-ios/runs/130382082155
The selected report's data-url /commit/<SHA>/checks/<run_id> returns a compact live
summary with X-Requested-With: XMLHttpRequest. Do not print data-channel tokens.
A ?check_run_id query alone did not select Archive reliably. Use full source SHAs.
GitHub reports are not a substitute for Apple processing/TestFlight build-number
confirmation. A lack of App Store Connect API access does not prevent these builds.

## Signed upload and Apple processing confirmed

Owner forwarded Apple's TestFlight email on 2026-11-11: WatchWeeks 1.0.2 (13)
is ready to test on iOS. The accompanying Xcode Cloud notification lists Archive
and TestFlight Internal Testing for WatchWeeks Upload, source branch
release/cloud-upload, latest commit “Make cloud analytics consent UI QA
self-contained without a listener” (8b27440). This confirms the remote signed
build/upload/processing path works; a local Mac is not required to trigger it.

Use the individual GitHub checks for progress, but they can lag Apple's email:
the archive check still displayed running when this readiness email was received.
Do not start duplicate builds solely because that check has not refreshed.
No App Review submission or public release of 1.0.2 was performed. Owner smoke QA,
actual PostHog production ingestion confirmation and App Privacy updates remain
separate acceptance gates. See release/BUILD_HISTORY.md.
