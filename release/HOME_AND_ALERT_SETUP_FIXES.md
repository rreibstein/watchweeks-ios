# Home and notification setup fixes

Implemented after the first signed publication-alert candidate:

- Removed the horizontal city shortcut strip. Guide cards retain their local-time
  countdowns and normal navigation.
- Moved the new-guide notification promo ahead of Past guides; About & privacy
  remains at the bottom of Home.
- Notification service discovery runs alongside guide loading. It no longer waits
  for every city detail, resets availability during each refresh, or loses a refresh
  request when a previous load is still finishing.
- App focus changes (inactive/active) no longer cancel loading. Shared refresh work
  survives a canceled UI caller. Swift/URLSession cancellation is silent, preserves
  last-good content and selections, and cannot become a raw error banner. Actual
  failures have readable copy and a retry action.
- TestFlight setup checks StoreKit's verified AppTransaction environment, with the
  old sandbox receipt only as a fallback when signed transaction evidence is absent.
  A verified production download cannot use the internal bypass. No transaction
  identity, JWS, account, price or purchase history is retained or transmitted.
- Notification setup retries are available directly in the sheet. Native UI no
  longer describes the feature as coming soon. Public availability remains gated
  by the backend; the live API still reports delivery_unverified, so a real device
  receipt is required before the publisher activates public alerts.

Portable coverage: 77 Swift tests, including cancellation/cache preservation and
verified sandbox access without a legacy receipt. Existing lost-response recovery,
rotation, unsubscribe and analytics consent remain covered. Nine signed-export
validator tests remain mandatory. Cloud UI QA now exercises background/foreground
browsing; simulator runs never enroll a real APNs device.

No website source/deployment, user data, Apple provider credentials, public push
switch, notification send or App Review submission is changed by this work.
