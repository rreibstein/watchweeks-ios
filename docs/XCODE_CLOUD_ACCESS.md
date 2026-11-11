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
